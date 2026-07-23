import 'patient_call.dart' show ServiceType;

/// Fonctions du personnel soignant pouvant être appelées.
/// Le "titre" est celui utilisé dans l'annonce vocale, ex :
/// "Le Docteur Mukendi est demandé en Pédiatrie".
enum StaffRole {
  medecin('Médecin', 'Le Docteur', '🩺'),
  infirmier('Infirmier', 'L\'infirmier', '💉'),
  sageFemme('Sage-femme', 'La sage-femme', '🤱'),
  technicienLabo('Technicien de laboratoire', 'Le technicien de laboratoire', '🧪'),
  anesthesiste('Anesthésiste-réanimateur', 'L\'anesthésiste-réanimateur', '💊');

  final String label;
  final String titre;
  final String emoji;
  const StaffRole(this.label, this.titre, this.emoji);
}

class StaffCall {
  final String id;
  final String staffName;
  final StaffRole role;
  final ServiceType destination;
  final List<String> subDestinations;
  final String? salle;
  final bool urgent;
  final DateTime calledAt;
  final String calledBy;

  const StaffCall({
    required this.id,
    required this.staffName,
    required this.role,
    required this.destination,
    this.subDestinations = const [],
    this.salle,
    this.urgent = false,
    required this.calledAt,
    required this.calledBy,
  });

  /// Libellé complet de la destination, sous-choix inclus — ex :
  /// "Pavillon (Pédiatrie)".
  String get destinationDisplayLabel {
    if (subDestinations.isEmpty) return destination.label;
    return '${destination.label} (${subDestinations.join(", ")})';
  }

  factory StaffCall.fromJson(Map<String, dynamic> json) {
    final subRaw = json['sous_destination'] as String?;
    return StaffCall(
      id: json['id'] as String,
      staffName: json['staff_name'] as String,
      role: StaffRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => StaffRole.medecin,
      ),
      destination: ServiceType.values.firstWhere(
        (s) => s.name == json['destination'],
        orElse: () => ServiceType.consultation,
      ),
      subDestinations:
          (subRaw == null || subRaw.isEmpty) ? const [] : subRaw.split('||'),
      salle: json['salle'] as String?,
      urgent: json['urgent'] as bool? ?? false,
      calledAt: DateTime.parse(json['called_at'] as String),
      calledBy: json['called_by'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staff_name': staffName,
      'role': role.name,
      'destination': destination.name,
      'sous_destination':
          subDestinations.isEmpty ? null : subDestinations.join('||'),
      'salle': salle,
      'urgent': urgent,
      'called_at': calledAt.toIso8601String(),
      'called_by': calledBy,
    };
  }
}
