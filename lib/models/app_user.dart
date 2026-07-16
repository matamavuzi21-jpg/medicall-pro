/// Rôles disponibles dans MediCall Pro.
/// Détermine les écrans et actions accessibles à chaque utilisateur.
enum UserRole {
  agent('Agent d\'accueil', 1),
  superviseur('Superviseur', 2),
  directeur('Directeur', 3);

  final String label;
  final int niveau; // Utilisé pour les contrôles d'accès hiérarchiques.
  const UserRole(this.label, this.niveau);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.agent,
    );
  }
}

class AppUser {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? service; // Service d'affectation (ex : Consultation, Labo)
  final bool actif;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.service,
    this.actif = true,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String? ?? 'agent'),
      service: json['service'] as String?,
      actif: json['actif'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.name,
      'service': service,
      'actif': actif,
    };
  }

  AppUser copyWith({
    String? fullName,
    UserRole? role,
    String? service,
    bool? actif,
  }) {
    return AppUser(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      service: service ?? this.service,
      actif: actif ?? this.actif,
      createdAt: createdAt,
    );
  }
}
