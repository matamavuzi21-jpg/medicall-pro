import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_language.dart';

/// Gère l'annonce vocale des patients (écran d'appel en mode 1 appareil,
/// ou écran TV en mode 2 appareils), en français, swahili, lingala,
/// kikongo ou tshiluba.
///
/// Pour les langues non couvertes par le moteur TTS de l'appareil
/// (lingala, kikongo, tshiluba — voir [AppLanguage]), le texte est tout de
/// même prononcé avec la meilleure voix disponible (repli français), ce
/// qui reste plus utile qu'un silence, en attendant l'intégration d'un
/// moteur cloud ou de phrases pré-enregistrées (voir README).
///
/// Avec les appels en parallèle par service, plusieurs annonces peuvent
/// arriver au même moment. `announce` ne lit donc jamais directement : le
/// texte est empilé dans une file, et un worker unique les lit une par
/// une, dans l'ordre d'arrivée, en attendant la fin de chaque phrase
/// avant de passer à la suivante.
///
/// Chaque annonce peut aussi être **répétée automatiquement** (2 ou 3
/// fois, avec un intervalle réglable) pour une meilleure audibilité dans
/// une salle d'attente bruyante — réglage persistant, appliqué de façon
/// centralisée ici, donc valable pour toute annonce quel que soit
/// l'écran d'où elle part.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  static const _languagePrefsKey = 'medicall_selected_language';
  static const _repeatCountPrefsKey = 'medicall_repeat_count';
  static const _repeatIntervalPrefsKey = 'medicall_repeat_interval_seconds';

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  AppLanguage _currentLanguage = AppLanguage.francais;

  int _repeatCount = 1; // 1 = pas de répétition, lu une seule fois
  int _repeatIntervalSeconds = 4;

  final List<_QueueItem> _queue = [];
  bool _speaking = false;

  AppLanguage get currentLanguage => _currentLanguage;
  int get repeatCount => _repeatCount;
  int get repeatIntervalSeconds => _repeatIntervalSeconds;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
    await _restoreSavedLanguage();
    await _restoreRepeatSettings();
    _initialized = true;
  }

  Future<void> _restoreSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_languagePrefsKey);
    _currentLanguage =
        saved != null ? AppLanguage.fromCode(saved) : AppLanguage.francais;
    await _applyLanguage(_currentLanguage);
  }

  Future<void> _restoreRepeatSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _repeatCount = prefs.getInt(_repeatCountPrefsKey) ?? 1;
    _repeatIntervalSeconds = prefs.getInt(_repeatIntervalPrefsKey) ?? 4;
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

  /// Change la langue active et la mémorise pour les prochains lancements.
  Future<void> setLanguage(AppLanguage language) async {
    await _ensureInit();
    _currentLanguage = language;
    await _applyLanguage(language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languagePrefsKey, language.bcp47);
  }

  /// Indique si la voix native de [language] est présente sur l'appareil,
  /// utile pour afficher un badge "voix française de secours" dans l'UI.
  Future<bool> hasNativeVoice(AppLanguage language) async {
    await _ensureInit();
    if (!language.nativelySupported) return false;
    return _isLanguageAvailable(language.bcp47);
  }

  /// Définit combien de fois chaque annonce est répétée (1 à 3) et
  /// l'intervalle de silence entre deux répétitions. Mémorisé pour les
  /// prochains lancements de l'app.
  Future<void> setRepeatSettings({
    required int count,
    required int intervalSeconds,
  }) async {
    await _ensureInit();
    _repeatCount = count.clamp(1, 3);
    _repeatIntervalSeconds = intervalSeconds.clamp(1, 30);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_repeatCountPrefsKey, _repeatCount);
    await prefs.setInt(_repeatIntervalPrefsKey, _repeatIntervalSeconds);
  }

  /// Ajoute un texte à la file d'annonces, répété selon les réglages
  /// actuels (`repeatCount` fois, espacées de `repeatIntervalSeconds`).
  /// Ne bloque pas l'appelant : la lecture se fait en arrière-plan.
  Future<void> announce(String text) async {
    await _ensureInit();
    for (var i = 0; i < _repeatCount; i++) {
      final isLast = i == _repeatCount - 1;
      _queue.add(_QueueItem(
        text: text,
        delayAfter: isLast
            ? Duration.zero
            : Duration(seconds: _repeatIntervalSeconds),
      ));
    }
    if (!_speaking) _processQueue();
  }

  Future<void> _processQueue() async {
    _speaking = true;
    while (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      try {
        await _tts.speak(next.text);
        if (next.delayAfter > Duration.zero) {
          await Future.delayed(next.delayAfter);
        }
      } catch (_) {
        // Une annonce en échec ne doit pas bloquer les suivantes.
      }
    }
    _speaking = false;
  }

  /// Vide la file en attente sans couper l'annonce en cours.
  void clearPendingQueue() => _queue.clear();

  Future<void> stop() async {
    _queue.clear();
    await _tts.stop();
  }
}

class _QueueItem {
  final String text;
  final Duration delayAfter;
  const _QueueItem({required this.text, required this.delayAfter});
}
