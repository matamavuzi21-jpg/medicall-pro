import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/patient_call.dart';
import '../services/supabase_service.dart';
import '../services/offline_queue_service.dart';
import '../services/connectivity_service.dart';
import '../services/tts_service.dart';
import '../services/announcement_builder.dart';
import '../widgets/sync_status_badge.dart';
import '../widgets/repeat_settings_dialog.dart';

/// Écran principal : saisie du patient et déclenchement de l'appel.
///
/// Deux modes d'utilisation possibles, au choix de l'hôpital :
/// 1. "Mode 2 appareils" : ce poste + un second appareil ouvert sur
///    TvDisplayScreen (icône 📺), affiché en salle d'attente.
/// 2. "Mode 1 appareil" (zones reculées, sans second appareil) : ce même
///    poste, relié en Bluetooth à une enceinte, annonce lui-même le
///    patient à voix haute juste après l'appel — grâce au commutateur
///    "Annonce vocale sur cet appareil" ci-dessous. Les deux modes
///    peuvent aussi être actifs en même temps sans conflit.
class CallPatientScreen extends StatefulWidget {
  const CallPatientScreen({super.key});

  @override
  State<CallPatientScreen> createState() => _CallPatientScreenState();
}

class _CallPatientScreenState extends State<CallPatientScreen> {
  static const _localAnnouncePrefsKey = 'medicall_local_announce_enabled';

  final _nameCtrl = TextEditingController();
  final _salleCtrl = TextEditingController();
  ServiceType _selectedService = ServiceType.consultation;
  final Set<String> _selectedSubServices = {};
  bool _sending = false;
  bool _localAnnounceEnabled = true;

  @override
  void initState() {
    super.initState();
    _restoreLocalAnnouncePreference();
  }

  Future<void> _restoreLocalAnnouncePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_localAnnouncePrefsKey);
    if (saved != null && mounted) {
      setState(() => _localAnnounceEnabled = saved);
    }
  }

  Future<void> _setLocalAnnouncePreference(bool value) async {
    setState(() => _localAnnounceEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_localAnnouncePrefsKey, value);
  }

  void _onServiceChanged(ServiceType? service) {
    if (service == null) return;
    setState(() {
      _selectedService = service;
      _selectedSubServices.clear();
    });
  }

  Future<void> _callPatient() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir le nom du patient.')),
      );
      return;
    }
    if (_selectedService.hasSubOptions && _selectedSubServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Veuillez choisir au moins une option pour ${_selectedService.label}.'),
        ),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final call = PatientCall(
        id: const Uuid().v4(),
        patientName: name,
        service: _selectedService,
        subServices: _selectedSubServices.toList(),
        salle: _salleCtrl.text.trim().isEmpty ? null : _salleCtrl.text.trim(),
        calledAt: DateTime.now(),
        calledBy: SupabaseService.instance.currentUser?.email ?? 'agent',
      );
      final wasOnline = ConnectivityService.instance.isOnline;
      await OfflineQueueService.instance.callPatient(call);

      if (_localAnnounceEnabled) {
        final text = AnnouncementBuilder.build(
          call,
          TtsService.instance.currentLanguage,
        );
        TtsService.instance.announce(text);
      }

      if (!mounted) return;
      _nameCtrl.clear();
      _salleCtrl.clear();
      setState(() => _selectedSubServices.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: wasOnline ? AppColors.succes : AppColors.attention,
          content: Text(wasOnline
              ? '$name a été appelé(e) — ${call.serviceDisplayLabel}'
              : '$name enregistré(e) — sera envoyé(e) dès le retour du réseau'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.erreur,
          content: Text("Échec de l'enregistrement de l'appel."),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appeler un patient'),
        actions: const [SyncStatusBadge()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LocalAnnounceCard(
                enabled: _localAnnounceEnabled,
                onChanged: _setLocalAnnouncePreference,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Nom du patient', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'Ex : Henri Fayol Mata',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Service', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _ServiceDropdown(
                selected: _selectedService,
                onChanged: _onServiceChanged,
              ),
              if (_selectedService.hasSubOptions) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Précisez (un ou plusieurs choix)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                _SubOptionsChips(
                  options: _selectedService.subOptions,
                  selected: _selectedSubServices,
                  onToggle: (option, isSelected) => setState(() {
                    if (isSelected) {
                      _selectedSubServices.add(option);
                    } else {
                      _selectedSubServices.remove(option);
                    }
                  }),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text('Salle (optionnel)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _salleCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ex : Salle 3',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: _sending ? null : _callPatient,
                icon: _sending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.campaign_rounded),
                label: const Text('APPELER', style: TextStyle(letterSpacing: 1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte de contrôle du mode "1 appareil" : active/désactive l'annonce
/// vocale directement sur ce téléphone (utile en zone reculée, avec une
/// enceinte Bluetooth, sans second appareil dédié à l'écran TV).
class _LocalAnnounceCard extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _LocalAnnounceCard({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: enabled ? AppColors.bleuMedical : Colors.grey,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Annonce vocale sur cet appareil',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    enabled
                        ? 'Utile en zone reculée : reliez une enceinte Bluetooth, aucun second appareil requis.'
                        : 'Désactivé — utilisez ce mode si un écran TV séparé s\'occupe déjà de l\'annonce.',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              activeThumbColor: AppColors.vertEmeraude,
              onChanged: onChanged,
            ),
            IconButton(
              tooltip: 'Régler la répétition',
              icon: const Icon(Icons.repeat_rounded),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const RepeatSettingsDialog(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Menu déroulant compact listant les 10 services, avec emoji.
class _ServiceDropdown extends StatelessWidget {
  final ServiceType selected;
  final ValueChanged<ServiceType?> onChanged;

  const _ServiceDropdown({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: AppColors.grisClair),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ServiceType>(
          value: selected,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded),
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          items: ServiceType.values.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Row(
                children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.grisAnthracite,
                      ),
                    ),
                  ),
                  if (s.hasSubOptions)
                    const Icon(Icons.list_rounded, size: 18, color: Colors.grey),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Choix multiples (chips) pour les services proposant des sous-options
/// (Imagerie médicale, Pavillon).
class _SubOptionsChips extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final void Function(String option, bool isSelected) onToggle;

  const _SubOptionsChips({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          selectedColor: AppColors.bleuMedical,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.grisAnthracite,
            fontWeight: FontWeight.w600,
          ),
          onSelected: (value) => onToggle(option, value),
        );
      }).toList(),
    );
  }
}
