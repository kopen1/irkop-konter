import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessContext {
  const BusinessContext({
    required this.businessId,
    required this.businessName,
    required this.outletId,
    required this.outletName,
  });

  final String businessId;
  final String businessName;
  final String outletId;
  final String outletName;
}

class BusinessContextRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<BusinessContext> ensureForCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User belum login.');

    var business = await _client
        .from('irkop_cell_businesses')
        .select('id,name')
        .eq('owner_user_id', user.id)
        .order('created_at')
        .limit(1)
        .maybeSingle();

    business ??= await _client
        .from('irkop_cell_businesses')
        .insert({
          'owner_user_id': user.id,
          'name': _defaultBusinessName(user.email),
        })
        .select('id,name')
        .single();

    var outlet = await _client
        .from('irkop_cell_outlets')
        .select('id,name')
        .eq('business_id', business['id'])
        .order('created_at')
        .limit(1)
        .maybeSingle();

    outlet ??= await _client
        .from('irkop_cell_outlets')
        .insert({
          'business_id': business['id'],
          'name': 'Outlet Utama',
          'timezone': 'Asia/Jakarta',
        })
        .select('id,name')
        .single();

    return BusinessContext(
      businessId: business['id'] as String,
      businessName: business['name'] as String,
      outletId: outlet['id'] as String,
      outletName: outlet['name'] as String,
    );
  }

  Future<void> updateBusinessName({required String businessId, required String name}) async {
    final value = name.trim();
    if (value.isEmpty) throw StateError('Nama bisnis tidak boleh kosong.');
    await _client
        .from('irkop_cell_businesses')
        .update({'name': value})
        .eq('id', businessId);
  }

  String _defaultBusinessName(String? email) {
    final prefix = (email ?? 'Owner').split('@').first.trim();
    return prefix.isEmpty ? 'Bisnis Saya' : '$prefix Store';
  }
}
