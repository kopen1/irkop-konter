import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

class OutletRecord {
  const OutletRecord({required this.id,required this.name,required this.active});
  final String id,name; final bool active;
  factory OutletRecord.fromMap(Map<String,dynamic> row)=>OutletRecord(id:row['id'] as String,name:row['name'] as String,active:(row['is_active'] as bool?)??true);
}
class OutletRepository {
  final SupabaseClient _client=Supabase.instance.client;
  Future<List<OutletRecord>> load(String businessId) async {
    if(!Env.isSupabaseConfigured)return const [];
    final rows=await _client.from('irkop_cell_outlets').select('id,name,is_active').eq('business_id',businessId).order('created_at');
    return rows.map<OutletRecord>((r)=>OutletRecord.fromMap(r)).toList();
  }
  Future<void> create({required String businessId,required String name})=>_client.from('irkop_cell_outlets').insert({'business_id':businessId,'name':name.trim(),'timezone':'Asia/Jakarta','is_active':true});
  Future<void> setActive({required String id,required String businessId,required bool active})=>_client.from('irkop_cell_outlets').update({'is_active':active}).eq('id',id).eq('business_id',businessId);
}