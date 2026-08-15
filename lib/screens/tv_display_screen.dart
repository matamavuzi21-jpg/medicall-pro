import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/patient_call.dart';
import '../services/supabase_service.dart';
import '../services/tts_service.dart';
import '../services/announcement_builder.dart';
import '../widgets/language_selector.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_wordmark.dart';

/// Écran destiné aux téléviseurs de la salle d'attente.
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
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

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
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String get _formattedClock {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
                  const AppLogo(size: 28, color: AppColors.vertEmeraude),
                  const SizedBox(width: 12),
                  const AppWordmark(fontSize: 22, primaryColor: Colors.white),
                  const SizedBox(width: 16),
                  Text(
                    _formattedClock,
                    style: AppTypography.mono(fontSize: 18, color: Colors.white70),
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
        childAspectRatio: 1.25,
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
    final caption = AnnouncementBuilder.build(call, TtsService.instance.currentLanguage);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1D22),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Column(
              children: [
                Text('PATIENT APPELÉ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    )),
                const SizedBox(height: 10),
                Text(
                  call.patientName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.wordmark(fontSize: 30, color: Colors.white),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: call.service.tileColor,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    call.serviceDisplayLabel.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (call.salle != null && call.salle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                call.salle!.toUpperCase(),
                style: TextStyle(
                  color: call.service.tileColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          const Spacer(),
          Container(
            width: double.infinity,
            color: Colors.black.withValues(alpha: 0.25),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            child: Row(
              children: [
                Icon(Icons.volume_up_rounded,
                    color: Colors.white.withValues(alpha: 0.6), size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
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
