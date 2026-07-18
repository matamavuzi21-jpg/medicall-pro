import '../models/app_language.dart';
import '../models/patient_call.dart';

/// Construit le texte annoncé par la synthèse vocale, dans la langue
/// choisie pour l'écran TV.
///
/// ⚠️ Les traductions du lingala, du kikongo et du tshiluba ci-dessous sont
/// des formulations courantes mais doivent être validées par un locuteur
/// natif de chaque langue avant mise en production (variantes régionales
/// possibles en RDC). Le français et le swahili sont les deux langues
/// couvertes de façon fiable par les moteurs TTS embarqués.
class AnnouncementBuilder {
  AnnouncementBuilder._();

  static String build(PatientCall call, AppLanguage language) {
    final name = call.patientName;
    final service = call.service.label;
    final salle = call.salle;

    switch (language) {
      case AppLanguage.francais:
        final lieu = salle != null && salle.isNotEmpty ? ' en $salle' : '';
        return 'Monsieur, Madame $name, veuillez vous présenter '
            'à $service$lieu.';

      case AppLanguage.swahili:
        final lieu = salle != null && salle.isNotEmpty ? ' katika $salle' : '';
        return 'Bwana au Bibi $name anasubiriwa katika $service$lieu.';

      case AppLanguage.lingala:
        final lieu = salle != null && salle.isNotEmpty ? ' na $salle' : '';
        return 'Tata to Mama $name azali kozela na $service$lieu.';

      case AppLanguage.kikongo:
        final lieu = salle != null && salle.isNotEmpty ? ' mu $salle' : '';
        return 'Tata to Mama $name wele kuvingila mu $service$lieu.';

      case AppLanguage.tshiluba:
        final lieu = salle != null && salle.isNotEmpty ? ' mu $salle' : '';
        return 'Tatu anyi Mamu $name udi utekemena mu $service$lieu.';
    }
  }
}
