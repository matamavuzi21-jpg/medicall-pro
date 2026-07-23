import '../models/app_language.dart';
import '../models/staff_call.dart';

/// Construit le texte annoncé par la synthèse vocale pour un appel de
/// personnel soignant — ex : "Le Docteur Mukendi est demandé en
/// Pédiatrie, en urgence."
///
/// ⚠️ Comme pour [AnnouncementBuilder] (appels de patients), seuls le
/// français et le swahili sont couverts de façon fiable ; les traductions
/// lingala/kikongo/tshiluba sont à valider par un locuteur natif.
class StaffAnnouncementBuilder {
  StaffAnnouncementBuilder._();

  static String build(StaffCall call, AppLanguage language) {
    final nom = call.staffName;
    final service = call.destinationDisplayLabel;
    final urgent = call.urgent;

    switch (language) {
      case AppLanguage.francais:
        final titre = call.role.titre;
        var texte = '$titre $nom est demandé en $service';
        if (urgent) texte += ', en urgence';
        return '$texte.';

      case AppLanguage.swahili:
        final titre = _titreSwahili(call.role);
        var texte = '$titre $nom anaombwa katika $service';
        if (urgent) texte += ', kwa dharura';
        return '$texte.';

      case AppLanguage.lingala:
        final titre = _titreLingala(call.role);
        var texte = '$titre $nom asengami na $service';
        if (urgent) texte += ', na lombangu';
        return '$texte.';

      case AppLanguage.kikongo:
        final titre = _titreKikongo(call.role);
        var texte = '$titre $nom wele lombwa mu $service';
        if (urgent) texte += ', mu nswalu';
        return '$texte.';

      case AppLanguage.tshiluba:
        final titre = _titreTshiluba(call.role);
        var texte = '$titre $nom udi ulombua mu $service';
        if (urgent) texte += ', ne lukasa';
        return '$texte.';
    }
  }

  static String _titreSwahili(StaffRole role) {
    switch (role) {
      case StaffRole.medecin:
        return 'Daktari';
      case StaffRole.infirmier:
        return 'Muuguzi';
      case StaffRole.sageFemme:
        return 'Mkunga';
      case StaffRole.technicienLabo:
        return 'Fundi wa maabara';
      case StaffRole.anesthesiste:
        return 'Daktari wa ganzi';
    }
  }

  static String _titreLingala(StaffRole role) {
    switch (role) {
      case StaffRole.medecin:
        return 'Monganga';
      case StaffRole.infirmier:
        return 'Infirimie';
      case StaffRole.sageFemme:
        return 'Sage-femme';
      case StaffRole.technicienLabo:
        return 'Tekniki ya laboratware';
      case StaffRole.anesthesiste:
        return 'Monganga ya anesthésie';
    }
  }

  static String _titreKikongo(StaffRole role) {
    switch (role) {
      case StaffRole.medecin:
        return 'Munganga';
      case StaffRole.infirmier:
        return 'Infirimie';
      case StaffRole.sageFemme:
        return 'Sage-femme';
      case StaffRole.technicienLabo:
        return 'Tekniki ya laboratware';
      case StaffRole.anesthesiste:
        return 'Munganga ya anesthésie';
    }
  }

  static String _titreTshiluba(StaffRole role) {
    switch (role) {
      case StaffRole.medecin:
        return 'Munganga';
      case StaffRole.infirmier:
        return 'Infirimie';
      case StaffRole.sageFemme:
        return 'Sage-femme';
      case StaffRole.technicienLabo:
        return 'Tekniki wa laboratware';
      case StaffRole.anesthesiste:
        return 'Munganga wa anesthésie';
    }
  }
}
