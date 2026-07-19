import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/patient_call.dart';
import '../services/supabase_service.dart';
import '../services/tts_service.dart';
import '../services/announcement_builder.dart';
import '../widgets/language_selector.dart';

/// Écran destiné aux téléviseurs de la salle d'attente.
///
/// Affiche un appel actif **par salle** en parallèle. Une tuile disparaît
/// automatiquement si sa salle n'a rien appelé depuis [_tileValidityWindow]
/// (par défaut 2 heures) — ça évite l'accumulation de tuiles obsolètes au
/// fil du temps (salles de test, noms mal orthographiés, etc.) et garde
/// l'écran pertinent pour la journée en cours.
///
/// Important : à l'ouverture de cet écran, les appels déjà existants ne
/// sont **jamais** annoncés à voix haute (seul le premier "instantané" est
/// affiché silencieusement) — seules les nouvelles arrivées, après
/// l'ouverture, déclenchent une annonce vocale.
class TvDisplayScreen extends StatefulWidget {
  const TvDisplayScreen({super.key});

  @override
  State<TvDisplayScreen> createState() => _TvDisplayScreenState();
}

String _tileKey(PatientCall call) {
  if (call.salle != null && call.salle!.trim().isNotEmpty) {
    return 'salle:${call.salle!.trim().toLowerCase()}';
  }
  return 'service:${call.service.name}';
}

const _tileValidityWindow = Duration(hours: 2);

class _TvDisplayScreenState extends State<TvDisplayScreen> {
  final Map<String, PatientCall> _latestByTile = {};
  final Map<String, String> _lastAnnouncedIdByTile = {};
  List<PatientCall> _recentHistory = [];
  bool _hasReceivedInitialSnapshot = false;

  @override
  void initState() {
    super.initState();
    SupabaseService.instance.watchCalls().listen((calls) {
      setState(() {
        _recentHistory = calls.take(6).toList();
        for (final call in calls) {
          final key = _tileKey(call);
          final existing = _latestByTile[key];
          if (existing == null || call.calledAt.isAfter(existing.calledAt)) {
            _latestByTile[key] = call;
          }
        }
      });

      if (!_hasReceivedInitialSnapshot) {
        for (final call in calls) {
          final key = _tileKey(call);
          final latest = _latestByTile[key];
          if (latest != null) {
            _lastAnnouncedIdByTile[key] = latest.id;
          }
        }
        _hasReceivedInitialSnapshot = true;
        return;
      }

      for (final call in calls) {
        final key = _tileKey(call);
        final lastId = _lastAnnouncedIdByTile[key];
        final existingLatest = _latestByTile[key];
        final isNewest = existingLatest == null || call.id == existingLatest.id;
        if (isNewest && call.id != lastId) {
          _lastAnnouncedIdByTile[key] = call.id;
          final text = AnnouncementBuilder.build(
            call,
            TtsService.instance.currentLanguage,
          );
          TtsService.instance.announce(text);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cutoff = DateTime.now().subtract(_tileValidityWindow);
    final tiles = _latestByTile.values
        .where((c) => c.calledAt.isAfter(cutoff))
        .toList()
      ..sort((a, b) {
        final byService = a.service.index.compareTo(b.service.index);
        if (byService != 0) return byService;
        return (a.salle ?? '').compareTo(b.salle ?? '');
      });

    return Scaffold(
      backgroundColor: AppColors.grisAnthracite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.local_hospital_rounded,
                      color: AppColors.vertEmeraude, size: 32),
                  const SizedBox(width: 12),
                  const Text(
                    'MediCall Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const LanguageSelector(),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: tiles.isEmpty
                    ? const _EmptyState()
                    : _TileGrid(calls: tiles),
              ),
              if (_recentHistory.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _PreviousCallsRow(calls: _recentHistory),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TileGrid extends StatelessWidget {
  final List<PatientCall> calls;
  const _TileGrid({required this.calls});

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = calls.length <= 1
        ? 1
        : calls.length <= 4
            ? 2
            : 3;
    return GridView.builder(
      itemCount: calls.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (_, i) => _TileCard(call: calls[i]),
    );
  }
}

class _TileCard extends StatelessWidget {
  final PatientCall call;
  const _TileCard({required this.call});

  @override
  Widget build(BuildContext context) {
    final header = call.salle != null && call.salle!.isNotEmpty
        ? '${call.service.emoji}  ${call.serviceDisplayLabel} · ${call.salle}'
        : '${call.service.emoji}  ${call.serviceDisplayLabel}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.bleuMedical, Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(header,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 14),
          Text(
            call.patientName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviousCallsRow extends StatelessWidget {
  final List<PatientCall> calls;
  const _PreviousCallsRow({required this.calls});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: calls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = calls[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(c.patientName,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                Text(
                  c.salle != null && c.salle!.isNotEmpty
                      ? '${c.service.emoji} ${c.salle}'
                      : '${c.service.emoji} ${c.serviceDisplayLabel}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'En attente du premier appel…',
        style: TextStyle(color: Colors.white54, fontSize: 22),
      ),
    );
  }
}
