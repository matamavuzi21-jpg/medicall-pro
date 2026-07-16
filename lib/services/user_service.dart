import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import 'supabase_service.dart';

/// Gère le CRUD des comptes du personnel hospitalier (table `profiles`).
///
/// Important : la création d'un compte (email + mot de passe) exige des
/// privilèges administrateur que la clé "anon" du client n'a pas. On délègue
/// donc cette opération à une Edge Function Supabase (`admin-create-user`)
/// qui utilise la clé "service_role" côté serveur — jamais dans l'app.
/// Voir le README pour le code de cette fonction et son déploiement.
class UserService {
  UserService._();
  static final UserService instance = UserService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Liste tous les comptes, triés par nom.
  Future<List<AppUser>> getAllUsers() async {
    final rows = await _client
        .from('profiles')
        .select()
        .order('full_name', ascending: true);
    return (rows as List)
        .map((r) => AppUser.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Crée un nouveau compte (auth + profil) via l'Edge Function sécurisée.
  Future<void> createUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? service,
  }) async {
    final response = await _client.functions.invoke(
      'admin-create-user',
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role.name,
        'service': service,
      },
    );
    if (response.status != 200) {
      throw Exception(
          'Échec de la création du compte (${response.status}).');
    }
  }

  /// Met à jour le nom, le rôle, le service ou l'état actif/inactif.
  Future<void> updateUser(AppUser user) async {
    await _client.from('profiles').update(user.toJson()).eq('id', user.id);
  }

  /// Désactive un compte sans le supprimer (conserve l'historique des
  /// appels liés à cet agent).
  Future<void> setActive(String userId, bool actif) async {
    await _client.from('profiles').update({'actif': actif}).eq('id', userId);
  }
}
