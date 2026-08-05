import 'package:flutter/material.dart';

/// Services disponibles pour l'appel d'un patient, dans l'ordre du
/// parcours patient habituel d'un hôpital.
///
/// Deux services (Imagerie médicale, Pavillon) proposent des sous-choix
/// multiples (ex : Radiographie + Scanner) via [subOptions] — l'agent
/// peut en sélectionner un ou plusieurs à l'appel (voir PatientCall.subServices).
///
/// [tileColor] est la teinte d'accent utilisée pour la tuile de
/// sélection du service (icône colorée quand non sélectionné, fond plein
/// quand sélectionné) — voir les grilles de service des écrans d'appel.
enum ServiceType {
  reception('Réception et Accueil', '🛎️', Color(0xFF0E8E82)),
  caisse('Caisse', '💳', Color(0xFF049B6B)),
  urgences('Urgences', '🚑', Color(0xFFC13F2E)),
  consultation('Consultation médicale', '🩺', Color(0xFF0B3D78)),
  laboratoire('Laboratoire d\'analyse', '🧪', Color(0xFF7C4DFF)),
  imagerie('Imagerie médicale', '🩻', Color(0xFF1E88E5),
      subOptions: ['Radiographie', 'Échographie', 'Scanner']),
  salleSoins('Salle de soins', '💉', Color(0xFF00897B)),
  pharmacie('Pharmacie', '💊', Color(0xFFE2921F)),
  pavillon('Pavillon', '🏨', Color(0xFF3F51B5), subOptions: [
    'Médecine interne',
    'Pédiatrie',
    'Gynéco-obstétrique',
    'Chirurgie',
  ]),
  blocOperatoire('Bloc opératoire', '🔪', Color(0xFF6D4C41));

  final String label;
  final String emoji;
  final Color tileColor;
  final List<String> subOptions;
  const ServiceType(this.label, this.emoji, this.tileColor,
      {this.subOptions = const []});

  bool get hasSubOptions => subOptions.isNotEmpty;
}

/// Statut du cycle de vie d'un appel patient.
enum CallStatus { enAttente, appele, termine, annule }

class PatientCall {
  final String id;
  final String patientName;
  final ServiceType service;
  final List<String> subServices;
  final String? salle;
  final DateTime calledAt;
  final CallStatus status;
  final String calledBy;

  const PatientCall({
    required this.id,
    required this.patientName,
    required this.service,
    this.subServices = const [],
    this.salle,
    required this.calledAt,
    this.status = CallStatus.appele,
    required this.calledBy,
  });

  /// Libellé complet à afficher/annoncer, incluant les sous-choix
  /// éventuels — ex : "Imagerie médicale (Radiographie, Scanner)".
  String get serviceDisplayLabel {
    if (subServices.isEmpty) return service.label;
    return '${service.label} (${subServices.join(", ")})';
  }

  factory PatientCall.fromJson(Map<String, dynamic> json) {
    final subServicesRaw = json['sous_service'] as String?;
    return PatientCall(
      id: json['id'] as String,
      patientName: json['patient_name'] as String,
      service: ServiceType.values.firstWhere(
        (s) => s.name == json['service'],
        orElse: () => ServiceType.consultation,
      ),
      subServices: (subServicesRaw == null || subServicesRaw.isEmpty)
          ? const []
          : subServicesRaw.split('||'),
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
      'sous_service': subServices.isEmpty ? null : subServices.join('||'),
      'salle': salle,
      'called_at': calledAt.toIso8601String(),
      'status': status.name,
      'called_by': calledBy,
    };
  }
}
