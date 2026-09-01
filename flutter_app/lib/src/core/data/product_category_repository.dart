import 'package:supabase_flutter/supabase_flutter.dart';

class ProductCategory {
  const ProductCategory({required this.id,required this.name,required this.trackStock,required this.isActive});
  final String id,name;
  final bool trackStock,isActive;
  factory ProductCategory.fromMap(Map<String,dynamic> r)=>ProductCategory(
    id:r['id'] as String,
    name:r['name'] as String,
    trackStock:(r['track_stock'] as bool?) ?? true,
    isActive:(r['is_active'] as bool?) ?? true,
  );
}

class ProductCategoryRepository {
  final SupabaseClient _client=Supabase.instance.client;
  Future<List<ProductCategory>> load(String businessId) async {
    final rows=await _client.from('irkop_cell_product_categories').select('id,name,track_stock,is_active').eq('business_id',businessId).eq('is_active',true).order('name');
    return rows.map<ProductCategory>((r)=>ProductCategory.fromMap(Map<String,dynamic>.from(r))).toList();
  }
  Future<void> create({required String businessId,required String name,required bool trackStock}) async {
    final clean=name.trim();
    if(clean.isEmpty) throw StateError('Nama kategori wajib diisi.');
    await _client.from('irkop_cell_product_categories').insert({'business_id':businessId,'name':clean,'track_stock':trackStock,'is_active':true});
  }
  Future<void> update({required String id,required String businessId,required String name,required bool trackStock}) async {
    final clean=name.trim();
    if(clean.isEmpty) throw StateError('Nama kategori wajib diisi.');
    await _client.from('irkop_cell_product_categories').update({'name':clean,'track_stock':trackStock}).eq('id',id).eq('business_id',businessId);
  }
  Future<void> archive({required String id,required String businessId}) async => _client.from('irkop_cell_product_categories').update({'is_active':false}).eq('id',id).eq('business_id',businessId);
}
