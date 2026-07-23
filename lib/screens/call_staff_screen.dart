import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/patient_call.dart' show ServiceType;
import '../models/staff_call.dart';
import '../services/supabase_service.dart';
import '../services/staff_offline_queue_service.dart';
import '../services/connectivity_service.dart';
import '../services/tts_service.dart';
import '../services/staff_announcement_builder.dart';
import '../widgets/sync_status_badge.dart';

/// Écran du 2ᵉ volet : appeler un membre du personnel soignant (médecin,
/// infirmier, sage-femme, technicien de labo, anesthésiste-réanimateur)
/// dans un service donné — ex : "Le Docteur Mukendi est demandé en
/// Pédiatrie, en urgence."
///
/// Fonctionne exactement comme l'appel de patient : enregistrement
/// hors-ligne garanti, synchronisation automatique, annonce vocale
/// immédiate sur cet appareil (mode 1 appareil).
class CallStaffScreen extends StatefulWidget {
  const CallStaffScreen({super.key});

  @override
  State<CallStaffScreen> createState() => _CallStaffScreenState();
}

class _CallStaffScreenState extends State<CallStaffScreen> {
  final _nameCtrl = TextEditingController();
  final _salleCtrl = TextEditingController();
  StaffRole _selectedRole = StaffRole.medecin;
  ServiceType _selectedDestination = ServiceType.consultation;
  final Set<String> _selectedSubDestinations = {};
  bool _urgent = false;
  bool _sending = false;

  void _onDestinationChanged(ServiceType? value) {
    if (value == null) return;
    setState(() {
      _selectedDestination = value;
      _selectedSubDestinations.clear();
    });
  }

  Future<void> _callStaff() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir le nom du personnel.')),
      );
      return;
    }
    if (_selectedDestination.hasSubOptions && _selectedSubDestinations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Veuillez choisir au moins une option pour ${_selectedDestination.label}.'),
        ),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final call = StaffCall(
        id: const Uuid().v4(),
        staffName: name,
        role: _selectedRole,
        destination: _selectedDestination,
        subDestinations: _selectedSubDestinations.toList(),
        salle: _salleCtrl.text.trim().isEmpty ? null : _salleCtrl.text.trim(),
        urgent: _urgent,
        calledAt: DateTime.now(),
        calledBy: SupabaseService.instance.currentUser?.email ?? 'agent',
      );

      final wasOnline = ConnectivityService.instance.isOnline;
      await StaffOfflineQueueService.instance.callStaff(call);

      final text = StaffAnnouncementBuilder.build(
        call,
        TtsService.instance.currentLanguage,
      );
      TtsService.instance.announce(text);

      if (!mounted) return;
      _nameCtrl.clear();
      _salleCtrl.clear();
      setState(() {
        _urgent = false;
        _selectedSubDestinations.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: wasOnline ? AppColors.succes : AppColors.attention,
          content: Text(wasOnline
              ? '${_selectedRole.titre} $name appelé(e) — ${call.destinationDisplayLabel}'
              : 'Enregistré(e) — sera envoyé(e) dès le retour du réseau'),
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
        title: const Text('Appeler le personnel'),
        actions: const [SyncStatusBadge()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nom du personnel', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'Ex : Mukendi',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Fonction', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _RoleDropdown(
                selected: _selectedRole,
                onChanged: (r) => setState(() => _selectedRole = r!),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Demandé en', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _DestinationDropdown(
                selected: _selectedDestination,
                onChanged: _onDestinationChanged,
              ),
              if (_selectedDestination.hasSubOptions) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Précisez (un ou plusieurs choix)',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                _SubOptionsChips(
                  options: _selectedDestination.subOptions,
                  selected: _selectedSubDestinations,
                  onToggle: (option, isSelected) => setState(() {
                    if (isSelected) {
                      _selectedSubDestinations.add(option);
                    } else {
                      _selectedSubDestinations.remove(option);
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
                  hintText: 'Ex : Salle 2',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _UrgentSwitch(
                value: _urgent,
                onChanged: (v) => setState(() => _urgent = v),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: _sending ? null : _callStaff,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _urgent ? AppColors.erreur : AppColors.bleuMedical,
                ),
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
                label: Text(_urgent ? 'APPELER EN URGENCE' : 'APPELER',
                    style: const TextStyle(letterSpacing: 1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  final StaffRole selected;
  final ValueChanged<StaffRole?> onChanged;
  const _RoleDropdown({required this.selected, required this.onChanged});

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
        child: DropdownButton<StaffRole>(
          value: selected,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded),
          items: StaffRole.values.map((r) {
            return DropdownMenuItem(
              value: r,
              child: Row(
                children: [
                  Text(r.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(r.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.grisAnthracite)),
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

class _DestinationDropdown extends StatelessWidget {
  final ServiceType selected;
  final ValueChanged<ServiceType?> onChanged;
  const _DestinationDropdown({required this.selected, required this.onChanged});

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
          items: ServiceType.values.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Row(
                children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.grisAnthracite)),
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

class _UrgentSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _UrgentSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: value ? AppColors.erreur.withValues(alpha: 0.08) : AppColors.blanc,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: value ? AppColors.erreur : Colors.grey),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'En urgence',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: value ? AppColors.erreur : AppColors.grisAnthracite,
                ),
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: AppColors.erreur,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
