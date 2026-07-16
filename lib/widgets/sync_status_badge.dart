import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/offline_queue_service.dart';

/// Petit badge affiché dans l'appBar : vert (à jour), orange (envoi en
/// cours), gris (hors-ligne, N appel(s) en attente). Donne au personnel
/// une confiance immédiate dans le fait que l'appel a bien été enregistré,
/// même sans réseau.
class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: OfflineQueueService.instance.onStatusChange,
      builder: (context, snapshot) {
        final status = snapshot.data;
        final Color color;
        final IconData icon;
        final String label;

        if (status == null || (status.isOnline && status.pendingCount == 0)) {
          color = AppColors.succes;
          icon = Icons.cloud_done_rounded;
          label = 'À jour';
        } else if (!status.isOnline) {
          color = AppColors.grisAnthracite;
          icon = Icons.cloud_off_rounded;
          label = status.pendingCount > 0
              ? 'Hors-ligne · ${status.pendingCount} en attente'
              : 'Hors-ligne';
        } else {
          color = AppColors.attention;
          icon = Icons.sync_rounded;
          label = 'Synchronisation… ${status.pendingCount}';
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }
}
