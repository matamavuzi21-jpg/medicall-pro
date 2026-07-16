import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_language.dart';

/// Gère l'annonce vocale des patients sur l'écran TV, en français,
/// swahili, lingala, kikongo ou tshiluba.
///
/// Pour les langues non couvertes par le moteur TTS de l'appareil
/// (lingala, kikongo, tshiluba — voir [AppLanguage]), le texte est tout de
/// même prononcé avec la meilleure voix disponible (repli français), ce
/// qui reste plus utile qu'un silence, en attendant l'intégration d'un
/// moteur cloud ou de phrases pré-enregistrées (voir README).
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  static const _prefsKey = 'medicall_selected_language';

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  AppLanguage _currentLanguage = AppLanguage.francais;

  AppLanguage get currentLanguage => _currentLanguage;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _restoreSavedLanguage();
    _initialized = true;
  }

  Future<void> _restoreSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    _currentLanguage =
        saved != null ? AppLanguage.fromCode(saved) : AppLanguage.francais;
    await _applyLanguage(_currentLanguage);
  }

  /// Applique la langue au moteur TTS, avec repli vers le français si la
  /// voix demandée n'existe pas sur l'appareil.
  Future<void> _applyLanguage(AppLanguage language) async {
    final available = await _isLanguageAvailable(language.bcp47);
    final effectiveCode = available ? language.bcp47 : AppLanguage.francais.bcp47;
    await _tts.setLanguage(effectiveCode);
  }

  Future<bool> _isLanguageAvailable(String bcp47) async {
    try {
      final result = await _tts.isLanguageAvailable(bcp47);
      return result == true || result == 1;
    } catch (_) {
      return false;
    }
  }

  /// Change la langue active et la mémorise pour les prochains lancements
  /// de l'écran TV.
  Future<void> setLanguage(AppLanguage language) async {
    await _ensureInit();
    _currentLanguage = language;
    await _applyLanguage(language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.bcp47);
  }

  /// Indique si la voix native de [language] est présente sur l'appareil,
  /// utile pour afficher un badge "voix française de secours" dans l'UI.
  Future<bool> hasNativeVoice(AppLanguage language) async {
    await _ensureInit();
    if (!language.nativelySupported) return false;
    return _isLanguageAvailable(language.bcp47);
  }

  Future<void> announce(String text) async {
    await _ensureInit();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
