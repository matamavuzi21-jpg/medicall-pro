/// Langues disponibles dans MediCall Pro.
///
/// ⚠️ Limitation technique importante : les moteurs de synthèse vocale
/// natifs d'Android/iOS/Windows ne proposent en général de voix que pour
/// le français et le swahili (sw-KE / sw-TZ). Le lingala, le kikongo et
/// le tshiluba ne sont couverts par (quasiment) aucun moteur TTS grand
/// public à ce jour. Pour ces langues, l'app bascule automatiquement sur
/// une voix française qui lit le texte traduit (meilleur rendu possible
/// avec les moteurs embarqués). Pour une prononciation native fidèle en
/// production, voir la section "Synthèse vocale — langues locales" du
/// README (intégration d'un moteur cloud ou de phrases pré-enregistrées).
enum AppLanguage {
  francais('fr-FR', 'Français', '🇫🇷', nativelySupported: true),
  swahili('sw-KE', 'Kiswahili', '🌍', nativelySupported: true),
  lingala('ln', 'Lingala', '🌍', nativelySupported: false),
  kikongo('kg', 'Kikongo', '🌍', nativelySupported: false),
  tshiluba('lu', 'Tshiluba', '🌍', nativelySupported: false);

  final String bcp47;
  final String label;
  final String flag;
  final bool nativelySupported;

  const AppLanguage(
    this.bcp47,
    this.label,
    this.flag, {
    required this.nativelySupported,
  });

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (l) => l.bcp47 == code,
      orElse: () => AppLanguage.francais,
    );
  }
}
