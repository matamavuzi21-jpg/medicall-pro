import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/dashboard_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_wordmark.dart';
import '../widgets/sync_status_badge.dart';
import 'call_patient_screen.dart';
import 'call_staff_screen.dart';
import 'tv_display_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'user_list_screen.dart';

/// Écran d'accueil : le hub central de MediCall Pro, après connexion.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<DashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = DashboardService.instance.getStatsForDate(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 22, color: AppColors.bleuMedical),
            const SizedBox(width: 8),
            const AppWordmark(fontSize: 18),
          ],
        ),
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
              _StatsRow(statsFuture: _statsFuture),
              const SizedBox(height: AppSpacing.lg),
              Text('Que souhaitez-vous faire ?',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _VoletCard(
                emoji: '📋',
                title: 'Appeler un patient',
                subtitle: 'Consultation, laboratoire, pharmacie, urgences…',
                color: AppColors.bleuMedical,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CallPatientScreen()),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _VoletCard(
                emoji: '👨🏽‍⚕️',
                title: 'Appeler le personnel soignant',
                subtitle: 'Médecin, infirmier, sage-femme, technicien de labo…',
                color: AppColors.vertEmeraude,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CallStaffScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bandeau de chiffres du jour — appels totaux et service le plus actif,
/// tirés de DashboardService (vraies données, jamais inventées).
class _StatsRow extends StatelessWidget {
  final Future<DashboardStats> statsFuture;
  const _StatsRow({required this.statsFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardStats>(
      future: statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        return Row(
          children: [
            Expanded(
              child: _StatChip(
                icon: Icons.campaign_rounded,
                label: 'Appels aujourd\'hui',
                value: stats == null ? '—' : '${stats.totalCalls}',
                color: AppColors.bleuMedical,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatChip(
                icon: Icons.local_hospital_rounded,
                label: 'Service le plus actif',
                value: stats?.busiestService == null
                    ? '—'
                    : '${stats!.busiestService!.emoji} ${stats.busiestService!.label}',
                color: AppColors.vertEmeraude,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: AppColors.grisClair),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.grisAnthracite.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

class _VoletCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _VoletCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radius + 4),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSpacing.radius + 4),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      )),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                      )),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}
