import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/tts_service.dart';

/// Boîte de dialogue permettant de régler combien de fois chaque annonce
/// vocale est répétée, et l'intervalle de silence entre les répétitions.
/// Utile dans une salle d'attente bruyante, pour que les patients aient
/// le temps de bien entendre leur nom.
class RepeatSettingsDialog extends StatefulWidget {
  const RepeatSettingsDialog({super.key});

  @override
  State<RepeatSettingsDialog> createState() => _RepeatSettingsDialogState();
}

class _RepeatSettingsDialogState extends State<RepeatSettingsDialog> {
  late int _count;
  late int _interval;

  @override
  void initState() {
    super.initState();
    _count = TtsService.instance.repeatCount;
    _interval = TtsService.instance.repeatIntervalSeconds;
  }

  Future<void> _save() async {
    await TtsService.instance.setRepeatSettings(
      count: _count,
      intervalSeconds: _interval,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Répétition de l\'annonce'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nombre de répétitions',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [1, 2, 3].map((n) {
              final selected = n == _count;
              return ChoiceChip(
                label: Text(n == 1 ? '1 fois (aucune répétition)' : '$n fois'),
                selected: selected,
                selectedColor: AppColors.bleuMedical,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.grisAnthracite,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() => _count = n),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Intervalle entre les répétitions',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [2, 3, 4, 5, 8, 10].map((s) {
              final selected = s == _interval;
              return ChoiceChip(
                label: Text('${s}s'),
                selected: selected,
                selectedColor: AppColors.vertEmeraude,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.grisAnthracite,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() => _interval = s),
              );
            }).toList(),
          ),
          if (_count == 1) ...[
            const SizedBox(height: AppSpacing.md),
            const Text(
              'L\'intervalle ne s\'applique que si "2 fois" ou "3 fois" est choisi.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
