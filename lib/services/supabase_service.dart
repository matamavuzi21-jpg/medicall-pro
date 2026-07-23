import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient_call.dart';
import '../models/staff_call.dart';
/// Centralise tous les échanges avec Supabase (auth, base de données,
/// synchronisation temps réel entre le poste d'appel et l'écran TV).
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  /// À appeler une seule fois au démarrage de l'app (voir main.dart).
  /// Remplacer les valeurs par celles de votre projet Supabase
  /// (Project Settings > API).
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://iikqndrpufjmgzkesgvm.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlpa3FuZHJwdWZqbWd6a2VzZ3ZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQxODMwNjksImV4cCI6MjA5OTc1OTA2OX0.v5a1Lk4XFJnx6WVI5r9xtr86S0idbdpI-rDJXDOST90',
    );
  }

  // ---------- Authentification ----------

  Future<void> signIn({required String email, required String password}) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => client.auth.signOut();

  User? get currentUser => client.auth.currentUser;

  // ---------- Appels de patients ----------

  /// Enregistre un nouvel appel. Grâce à Supabase Realtime, l'écran TV
  /// recevra la mise à jour instantanément, sans réseau internet requis
  /// si Supabase est auto-hébergé sur le réseau local de l'hôpital.
  Future<void> callPatient(PatientCall call) async {
    await client.from('patient_calls').insert(call.toJson());
  }

  /// Historique des appels du jour, du plus récent au plus ancien.
  Future<List<PatientCall>> getTodayHistory() async {
    final start = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final rows = await client
        .from('patient_calls')
        .select()
        .gte('called_at', start)
        .order('called_at', ascending: false);
    return (rows as List)
        .map((r) => PatientCall.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Flux temps réel écouté par l'écran TV : chaque nouvel appel apparaît
  /// immédiatement dans le stream.
  Stream<List<PatientCall>> watchCalls() {
    return client
        .from('patient_calls')
        .stream(primaryKey: ['id'])
        .order('called_at', ascending: false)
        .map((rows) =>
            rows.map((r) => PatientCall.fromJson(r)).toList());
  }
}
