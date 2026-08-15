import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Le nom de la marque tel qu'il doit apparaître partout dans l'app :
/// "MediCall" dans la couleur principale (bleu ou blanc selon le fond)
/// et "Pro" toujours en vert — jamais en une seule couleur unie, pour
/// rester cohérent avec le logo.
class AppWordmark extends StatelessWidget {
  final double fontSize;
  final Color primaryColor;
  final Color proColor;

  const AppWordmark({
    super.key,
    this.fontSize = 26,
    this.primaryColor = AppColors.bleuMedical,
    this.proColor = AppColors.vertEmeraude,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'MediCall',
            style: AppTypography.wordmark(fontSize: fontSize, color: primaryColor),
          ),
          TextSpan(
            text: ' Pro',
            style: AppTypography.wordmark(fontSize: fontSize, color: proColor),
          ),
        ],
      ),
    );
  }
}
