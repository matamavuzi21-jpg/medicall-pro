import '../models/patient_call.dart';
import 'supabase_service.dart';

/// Statistiques agrégées pour une période donnée, calculées à partir des
/// appels enregistrés dans `patient_calls`.
///
/// Note honnête sur les limites actuelles : le modèle de données
/// n'enregistre que l'heure de l'*appel*, pas l'heure d'arrivée du
/// patient. Le "temps d'attente réel" par patient ne peut donc pas encore
/// être calculé avec précision. Les métriques ci-dessous (répartition par
/// service, par heure, par agent) sont fiables dès aujourd'hui ; un vrai
/// temps d'attente nécessitera d'ajouter un horodatage "arrivée / prise en
/// charge" au flux (ticket d'accueil), prévu en évolution future.
class DashboardStats {
  final int totalCalls;
  final Map<ServiceType, int> byService;
  final Map<int, int> byHour; // 0-23
  final Map<String, int> byAgent;

  const DashboardStats({
    required this.totalCalls,
    required this.byService,
    required this.byHour,
    required this.byAgent,
  });

  ServiceType? get busiestService {
    if (byService.isEmpty) return null;
    return byService.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  MapEntry<String, int>? get mostActiveAgent {
    if (byAgent.isEmpty) return null;
    return byAgent.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }

  double get averagePerHour {
    final activeHours = byHour.values.where((v) => v > 0).length;
    if (activeHours == 0) return 0;
    return totalCalls / activeHours;
  }
}

class DashboardService {
  DashboardService._();
  static final DashboardService instance = DashboardService._();

  Future<DashboardStats> getStatsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final rows = await SupabaseService.instance.client
        .from('patient_calls')
        .select()
        .gte('called_at', start.toIso8601String())
        .lt('called_at', end.toIso8601String());

    final calls = (rows as List)
        .map((r) => PatientCall.fromJson(r as Map<String, dynamic>))
        .toList();

    final byService = <ServiceType, int>{};
    final byHour = <int, int>{for (var h = 0; h < 24; h++) h: 0};
    final byAgent = <String, int>{};

    for (final call in calls) {
      byService.update(call.service, (v) => v + 1, ifAbsent: () => 1);
      final hour = call.calledAt.toLocal().hour;
      byHour.update(hour, (v) => v + 1, ifAbsent: () => 1);
      final agent = call.calledBy.isEmpty ? 'Inconnu' : call.calledBy;
      byAgent.update(agent, (v) => v + 1, ifAbsent: () => 1);
    }

    return DashboardStats(
      totalCalls: calls.length,
      byService: byService,
      byHour: byHour,
      byAgent: byAgent,
    );
  }
}
