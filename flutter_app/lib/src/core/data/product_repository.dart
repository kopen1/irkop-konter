import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';
import '../models/business_models.dart';
import 'demo_store.dart';

class ProductRepository {
  final SupabaseClient _client=Supabase.instance.client;
  void _validate(String name,double price,double stock,double cost,double minStock){
    if(name.trim().isEmpty)throw StateError('Nama produk wajib diisi.');
    if(price<0||stock<0||cost<0||minStock<0)throw StateError('Harga, stok, modal dan stok minimum tidak boleh negatif.');
  }
  Future<List<Product>> loadProducts(String businessId) async {
    if(!Env.isSupabaseConfigured)return DemoStore.products;
    final rows=await _client.from('irkop_cell_products').select('id,name,category,category_id,sku,sell_price,cost_price,stock,min_stock,unit').eq('business_id',businessId).eq('is_active',true).order('name');
    return rows.map<Product>((r)=>Product(id:r['id'] as String,name:r['name'] as String,category:(r['category'] as String?)??'Lainnya',price:(r['sell_price'] as num).toDouble(),stock:(r['stock'] as num).toDouble(),sku:(r['sku'] as String?)??'',unit:(r['unit'] as String?)??'pcs',costPrice:(r['cost_price'] as num?)?.toDouble()??0,minStock:(r['min_stock'] as num?)?.toDouble()??0)).toList();
  }
  Future<void> createProduct({required String businessId,required String name,required String category,required double price,required double stock,String sku='',double costPrice=0,double minStock=0,String unit='pcs'}) async {
    _validate(name,price,stock,costPrice,minStock);
    final row=await _client.from('irkop_cell_products').insert({'business_id':businessId,'name':name.trim(),'category':category.trim().isEmpty?'Lainnya':category.trim(),'sku':sku.trim().isEmpty?null:sku.trim(),'sell_price':price,'cost_price':costPrice,'stock':stock,'min_stock':minStock,'unit':unit.trim().isEmpty?'pcs':unit.trim(),'is_active':true}).select('id').single();
    await _audit(businessId,row['id'] as String,'create');
  }
  Future<void> updateProduct({required String id,required String businessId,required String name,required String category,required double price,required double stock,String sku='',double costPrice=0,double minStock=0,String unit='pcs'}) async {
    _validate(name,price,stock,costPrice,minStock);
    await _client.from('irkop_cell_products').update({'name':name.trim(),'category':category.trim().isEmpty?'Lainnya':category.trim(),'sku':sku.trim().isEmpty?null:sku.trim(),'sell_price':price,'cost_price':costPrice,'stock':stock,'min_stock':minStock,'unit':unit.trim().isEmpty?'pcs':unit.trim()}).eq('id',id).eq('business_id',businessId);
    await _audit(businessId,id,'update');
  }
  Future<void> archiveProduct({required String id,required String businessId}) async {await _client.from('irkop_cell_products').update({'is_active':false}).eq('id',id).eq('business_id',businessId);await _audit(businessId,id,'archive');}
  Future<void> _audit(String businessId,String entityId,String action)async{try{await _client.from('irkop_cell_audit_logs').insert({'business_id':businessId,'entity_type':'product','entity_id':entityId,'action':'product.$action'});}catch(_){}}
}
