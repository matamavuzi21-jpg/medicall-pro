import '../models/patient_call.dart';
import 'supabase_service.dart';

/// Récupère l'historique des appels de patients avec filtres combinables.
class HistoryService {
  HistoryService._();
  static final HistoryService instance = HistoryService._();

  Future<List<PatientCall>> getHistory({
    DateTime? date,
    ServiceType? service,
    String? searchQuery,
    int limit = 200,
  }) async {
    var query = SupabaseService.instance.client.from('patient_calls').select();

    if (date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      query = query
          .gte('called_at', start.toIso8601String())
          .lt('called_at', end.toIso8601String());
    }

    if (service != null) {
      query = query.eq('service', service.name);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      query = query.ilike('patient_name', '%${searchQuery.trim()}%');
    }

    final rows = await query.order('called_at', ascending: false).limit(limit);

    return (rows as List)
        .map((r) => PatientCall.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
