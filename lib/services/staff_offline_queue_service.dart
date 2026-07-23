import 'dart:async';
import 'dart:convert';
import '../models/staff_call.dart';
import 'connectivity_service.dart';
import 'local_db.dart';
import 'supabase_service.dart';

/// Équivalent de [OfflineQueueService] mais pour les appels de personnel
/// soignant : enregistrement local immédiat, puis synchronisation
/// automatique dès que le réseau (local ou Internet) est disponible.
class StaffOfflineQueueService {
  StaffOfflineQueueService._();
  static final StaffOfflineQueueService instance = StaffOfflineQueueService._();

  final _statusController = StreamController<int>.broadcast();
  Stream<int> get onPendingCountChange => _statusController.stream;

  bool _syncing = false;

  Future<void> start() async {
    ConnectivityService.instance.onStatusChange.listen((online) {
      if (online) flushQueue();
    });
    await flushQueue();
  }

  Future<void> callStaff(StaffCall call) async {
    await LocalDb.instance.insertPendingStaff(call.id, jsonEncode(call.toJson()));
    await _emitCount();
    if (ConnectivityService.instance.isOnline) {
      await flushQueue();
    }
  }

  Future<void> flushQueue() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final pending = await LocalDb.instance.getAllPendingStaff();
      for (final row in pending) {
        final id = row['id'] as String;
        try {
          final json =
              jsonDecode(row['payload'] as String) as Map<String, dynamic>;
          final call = StaffCall.fromJson(json);
          await SupabaseService.instance.callStaff(call);
          await LocalDb.instance.removeStaff(id);
        } catch (_) {
          await LocalDb.instance.incrementStaffAttempts(id);
        }
      }
    } finally {
      _syncing = false;
      await _emitCount();
    }
  }

  Future<void> _emitCount() async {
    final count = await LocalDb.instance.countPendingStaff();
    _statusController.add(count);
  }
}
