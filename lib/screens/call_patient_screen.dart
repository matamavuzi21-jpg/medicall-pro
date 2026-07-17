import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/patient_call.dart';
import '../services/supabase_service.dart';
import '../services/offline_queue_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/sync_status_badge.dart';
import 'user_list_screen.dart';
import 'tv_display_screen.dart';
import 'history_screen.dart';
import 'dashboard_screen.dart';

class CallPatientScreen extends StatefulWidget {
  const CallPatientScreen({super.key});

  @override
  State<CallPatientScreen> createState() => _CallPatientScreenState();
}

class _CallPatientScreenState extends State<CallPatientScreen> {
  final _nameCtrl = TextEditingController();
  final _salleCtrl = TextEditingController();
  ServiceType _selectedService = ServiceType.consultation;
  bool _sending = false;

  Future<void> _callPatient() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir le nom du patient.')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final call = PatientCall(
        id: const Uuid().v4(),
        patientName: name,
        service: _selectedService,
        salle: _salleCtrl.text.trim().isEmpty ? null : _salleCtrl.text.trim(),
        calledAt: DateTime.now(),
        calledBy: SupabaseService.instance.currentUser?.email ?? 'agent',
      );
      // Toujours enregistré localement d'abord : aucun appel n'est perdu
      // même sans réseau. Synchronisé automatiquement avec Supabase dès
      // que la connexion (locale ou Internet) est disponible.
      final wasOnline = ConnectivityService.instance.isOnline;
      await OfflineQueueService.instance.callPatient(call);

      if (!mounted) return;
      _nameCtrl.clear();
      _salleCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: wasOnline ? AppColors.succes : AppColors.attention,
          content: Text(wasOnline
              ? '$name a été appelé(e) — ${_selectedService.label}'
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
        actions: [
          const SyncStatusBadge(),
          IconButton(
            tooltip: 'Écran TV',
            icon: const Icon(Icons.tv_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TvDisplayScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Tableau de bord',
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Historique des appels',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          // Visible pour tous ici ; l'accès réel est contrôlé côté serveur
          // par les policies RLS de Supabase (réservé aux superviseurs et
          // directeurs — voir README, section "Sécurité des rôles").
          IconButton(
            tooltip: 'Gestion des utilisateurs',
            icon: const Icon(Icons.group_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UserListScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              _ServiceGrid(
                selected: _selectedService,
                onSelect: (s) => setState(() => _selectedService = s),
              ),
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

class _ServiceGrid extends StatelessWidget {
  final ServiceType selected;
  final ValueChanged<ServiceType> onSelect;

  const _ServiceGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.4,
      children: ServiceType.values.map((s) {
        final isSelected = s == selected;
        return GestureDetector(
          onTap: () => onSelect(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.bleuMedical : AppColors.blanc,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(
                color: isSelected ? AppColors.bleuMedical : AppColors.grisClair,
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    s.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.grisAnthracite,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
