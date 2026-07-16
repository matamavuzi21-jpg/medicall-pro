import 'package:flutter/material.dart';
import '../models/app_language.dart';
import '../services/tts_service.dart';

/// Sélecteur de langue compact, à placer dans l'appBar de l'écran TV.
/// Affiche un badge "voix de secours" pour les langues sans TTS natif.
class LanguageSelector extends StatefulWidget {
  final ValueChanged<AppLanguage>? onChanged;
  const LanguageSelector({super.key, this.onChanged});

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  AppLanguage _selected = TtsService.instance.currentLanguage;

  Future<void> _pick(AppLanguage lang) async {
    await TtsService.instance.setLanguage(lang);
    setState(() => _selected = lang);
    widget.onChanged?.call(lang);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AppLanguage>(
      tooltip: 'Choisir la langue',
      initialValue: _selected,
      onSelected: _pick,
      itemBuilder: (context) => AppLanguage.values.map((lang) {
        return PopupMenuItem(
          value: lang,
          child: Row(
            children: [
              Text(lang.flag),
              const SizedBox(width: 10),
              Text(lang.label),
              if (!lang.nativelySupported) ...[
                const SizedBox(width: 8),
                const Tooltip(
                  message: 'Voix native indisponible sur cet appareil : '
                      'lecture avec repli français.',
                  child: Icon(Icons.info_outline_rounded, size: 16),
                ),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_selected.flag),
            const SizedBox(width: 6),
            Text(_selected.label,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            const Icon(Icons.expand_more_rounded, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}
