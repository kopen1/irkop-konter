import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerParityRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> loadAliases(
    String businessId,
    String customerId,
  ) async {
    final rows = await _client
        .from('irkop_cell_customer_aliases')
        .select()
        .eq('business_id', businessId)
        .eq('customer_id', customerId)
        .order('created_at');

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> addAlias({
    required String businessId,
    required String customerId,
    required String value,
    String type = 'phone',
    String source = 'manual',
  }) async {
    final valueClean = value.trim();
    if (valueClean.isEmpty) return;

    await _client.from('irkop_cell_customer_aliases').insert({
      'business_id': businessId,
      'customer_id': customerId,
      'alias_type': type,
      'alias_value': valueClean,
      'source': source,
    });
  }

  Future<void> merge({
    required String businessId,
    required String sourceCustomerId,
    required String targetCustomerId,
  }) async {
    if (sourceCustomerId == targetCustomerId) {
      throw StateError('Pelanggan sumber dan tujuan harus berbeda.');
    }

    await _client.from('irkop_cell_customer_merges').insert({
      'business_id': businessId,
      'source_customer_id': sourceCustomerId,
      'target_customer_id': targetCustomerId,
    });

    final aliases = await loadAliases(businessId, sourceCustomerId);

    for (final alias in aliases) {
      await _client.from('irkop_cell_customer_aliases').upsert({
        'business_id': businessId,
        'customer_id': targetCustomerId,
        'alias_type': alias['alias_type'],
        'alias_value': alias['alias_value'],
        'source': alias['source'],
      });
    }
  }
}
