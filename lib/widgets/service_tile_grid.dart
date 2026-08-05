import 'package:flutter/material.dart';
import '../models/patient_call.dart' show ServiceType;
import '../theme/app_theme.dart';

/// Grille de sélection de service en tuiles colorées — remplace l'ancien
/// menu déroulant par quelque chose de plus séduisant visuellement :
/// tuile claire avec icône teintée quand non sélectionnée, tuile pleine
/// couleur avec icône blanche quand sélectionnée.
///
/// Utilisée à la fois par l'écran d'appel patient (choix du service) et
/// l'écran d'appel personnel (choix de la destination).
class ServiceTileGrid extends StatelessWidget {
  final ServiceType selected;
  final ValueChanged<ServiceType> onSelect;

  const ServiceTileGrid({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.5,
      children: ServiceType.values.map((s) {
        final isSelected = s == selected;
        final color = s.tileColor;
        return GestureDetector(
          onTap: () => onSelect(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected ? color : AppColors.blanc,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(
                color: isSelected ? color : AppColors.grisClair,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(s.emoji, style: const TextStyle(fontSize: 17)),
                ),
                const SizedBox(height: 6),
                Text(
                  s.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.grisAnthracite,
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
