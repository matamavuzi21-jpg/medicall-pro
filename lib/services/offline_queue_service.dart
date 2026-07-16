import 'dart:async';
import 'dart:convert';
import '../models/patient_call.dart';
import 'connectivity_service.dart';
import 'local_db.dart';
import 'supabase_service.dart';

/// Point d'entrée unique pour appeler un patient, que le réseau soit
/// disponible ou non.
///
/// Fonctionnement :
/// 1. L'appel est toujours écrit d'abord dans la base locale (SQLite),
///    ce qui garantit qu'aucune demande n'est perdue même hors-ligne.
/// 2. Si le réseau est disponible, l'envoi vers Supabase est tenté
///    immédiatement ; en cas de succès, l'entrée locale est supprimée.
/// 3. Un écouteur de connectivité relance automatiquement la
///    synchronisation de toute la file dès que le réseau revient
///    (Wi-Fi de l'hôpital reconnecté, coupure Internet résolue, etc.).
///
/// Recommandation d'architecture pour un hôpital sans accès Internet
/// fiable : héberger Supabase localement (self-hosted, via Docker) sur
/// un serveur du réseau local de l'hôpital. Tous les postes et l'écran TV
/// s'y connectent alors en Wi-Fi/Ethernet local, sans dépendre
/// d'Internet — voir le README, section "Déploiement en réseau local".
class OfflineQueueService {
  OfflineQueueService._();
  static final OfflineQueueService instance = OfflineQueueService._();

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get onStatusChange => _statusController.stream;

  bool _syncing = false;

  Future<void> start() async {
    await ConnectivityService.instance.start();
    ConnectivityService.instance.onStatusChange.listen((online) {
      if (online) flushQueue();
    });
    await flushQueue();
  }

  /// Enregistre un appel patient. Ne lève jamais d'exception côté UI :
  /// l'appel est garanti d'être conservé localement en attendant l'envoi.
  Future<void> callPatient(PatientCall call) async {
    await LocalDb.instance.insertPending(call.id, jsonEncode(call.toJson()));
    await _emitStatus();
    if (ConnectivityService.instance.isOnline) {
      await flushQueue();
    }
  }

  /// Tente d'envoyer toutes les entrées en attente vers Supabase.
  /// Appelée automatiquement au retour du réseau, et peut aussi être
  /// déclenchée manuellement (ex : bouton "Synchroniser maintenant").
  Future<void> flushQueue() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final pending = await LocalDb.instance.getAllPending();
      for (final row in pending) {
        final id = row['id'] as String;
        try {
          final json = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
          final call = PatientCall.fromJson(json);
          await SupabaseService.instance.callPatient(call);
          await LocalDb.instance.remove(id);
        } catch (_) {
          // Échec pour cette entrée : elle reste en file, on comptabilise
          // la tentative et on passe à la suivante sans bloquer le flux.
          await LocalDb.instance.incrementAttempts(id);
        }
      }
    } finally {
      _syncing = false;
      await _emitStatus();
    }
  }

  Future<void> _emitStatus() async {
    final count = await LocalDb.instance.countPending();
    _statusController.add(SyncStatus(
      pendingCount: count,
      isOnline: ConnectivityService.instance.isOnline,
      isSyncing: _syncing,
    ));
  }
}

class SyncStatus {
  final int pendingCount;
  final bool isOnline;
  final bool isSyncing;
  const SyncStatus({
    required this.pendingCount,
    required this.isOnline,
    required this.isSyncing,
  });
}
