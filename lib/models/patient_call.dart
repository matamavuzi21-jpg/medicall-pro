/// Services disponibles pour l'appel d'un patient.
enum ServiceType {
  consultation('Consultation médicale', '🩺'),
  laboratoire('Laboratoire', '🧪'),
  pharmacie('Pharmacie', '💊'),
  radiologie('Radiologie', '🩻'),
  urgences('Urgences', '🚑'),
  caisse('Caisse', '💳');

  final String label;
  final String emoji;
  const ServiceType(this.label, this.emoji);
}

/// Statut du cycle de vie d'un appel patient.
enum CallStatus { enAttente, appele, termine, annule }

class PatientCall {
  final String id;
  final String patientName;
  final ServiceType service;
  final String? salle;
  final DateTime calledAt;
  final CallStatus status;
  final String calledBy;

  const PatientCall({
    required this.id,
    required this.patientName,
    required this.service,
    this.salle,
    required this.calledAt,
    this.status = CallStatus.appele,
    required this.calledBy,
  });

  factory PatientCall.fromJson(Map<String, dynamic> json) {
    return PatientCall(
      id: json['id'] as String,
      patientName: json['patient_name'] as String,
      service: ServiceType.values.firstWhere(
        (s) => s.name == json['service'],
        orElse: () => ServiceType.consultation,
      ),
      salle: json['salle'] as String?,
      calledAt: DateTime.parse(json['called_at'] as String),
      status: CallStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => CallStatus.appele,
      ),
      calledBy: json['called_by'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_name': patientName,
      'service': service.name,
      'salle': salle,
      'called_at': calledAt.toIso8601String(),
      'status': status.name,
      'called_by': calledBy,
    };
  }
}

