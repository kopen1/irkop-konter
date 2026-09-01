import 'package:supabase_flutter/supabase_flutter.dart';

class AuditRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> load(String businessId) async {
    final rows = await _client
        .from('irkop_cell_audit_logs')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false)
        .limit(100);

    return List<Map<String, dynamic>>.from(rows);
  }
}
