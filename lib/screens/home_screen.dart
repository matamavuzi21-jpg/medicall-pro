import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/sync_status_badge.dart';
import 'call_patient_screen.dart';
import 'call_staff_screen.dart';
import 'tv_display_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'user_list_screen.dart';

/// Écran d'accueil : le hub central de MediCall Pro, après connexion.
///
/// Sépare clairement les deux volets de l'application :
/// 1. Appeler un patient (parcours vers les services de l'hôpital)
/// 2. Appeler le personnel soignant (médecin, infirmier, sage-femme,
///    technicien de labo, anesthésiste-réanimateur, avec option urgence)
///
/// Les icônes utilitaires (écran TV, tableau de bord, historique,
/// utilisateurs) vivent ici, communes aux deux volets.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 22, color: AppColors.bleuMedical),
            const SizedBox(width: 8),
            Text('MediCall Pro', style: AppTypography.wordmark(fontSize: 18)),
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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Que souhaitez-vous faire ?',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.lg),
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
