import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/patient_call.dart';
import '../services/supabase_service.dart';
import '../services/tts_service.dart';
import '../services/announcement_builder.dart';
import '../widgets/language_selector.dart';

/// Écran destiné aux téléviseurs de la salle d'attente.
/// Affiche le dernier patient appelé + un historique court des précédents,
/// et déclenche l'annonce vocale à chaque nouvel appel reçu en temps réel.
class TvDisplayScreen extends StatefulWidget {
  const TvDisplayScreen({super.key});

  @override
  State<TvDisplayScreen> createState() => _TvDisplayScreenState();
}

class _TvDisplayScreenState extends State<TvDisplayScreen> {
  List<PatientCall> _calls = [];
  String? _lastAnnouncedId;

  @override
  void initState() {
    super.initState();
    SupabaseService.instance.watchCalls().listen((calls) {
      setState(() => _calls = calls);
      if (calls.isNotEmpty && calls.first.id != _lastAnnouncedId) {
        _lastAnnouncedId = calls.first.id;
        final text = AnnouncementBuilder.build(
          calls.first,
          TtsService.instance.currentLanguage,
        );
        TtsService.instance.announce(text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = _calls.isNotEmpty ? _calls.first : null;
    final previous = _calls.skip(1).take(4).toList();

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
              const Spacer(),
              if (current != null) _CurrentCallCard(call: current) else _EmptyState(),
              const Spacer(),
              if (previous.isNotEmpty) _PreviousCallsRow(calls: previous),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentCallCard extends StatelessWidget {
  final PatientCall call;
  const _CurrentCallCard({required this.call});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.bleuMedical, Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text('${call.service.emoji}  ${call.service.label}',
              style: const TextStyle(color: Colors.white70, fontSize: 22)),
          const SizedBox(height: 24),
          Text(
            call.patientName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (call.salle != null) ...[
            const SizedBox(height: 16),
            Text(call.salle!,
                style: const TextStyle(color: AppColors.vertEmeraude, fontSize: 26)),
          ],
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
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: calls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = calls[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(c.patientName,
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                Text(c.service.label,
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'En attente du premier appel…',
      style: TextStyle(color: Colors.white54, fontSize: 22),
    );
  }
}
