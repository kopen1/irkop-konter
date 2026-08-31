import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';
import '../models/business_models.dart';
import 'demo_store.dart';

class ProductRepository {
  void _validate(String name,double price,double stock){if(name.trim().isEmpty)throw StateError('Nama produk wajib diisi.');if(price<0||stock<0)throw StateError('Harga dan stok tidak boleh negatif.');}
  final SupabaseClient _client=Supabase.instance.client;
  Future<List<Product>> loadProducts(String businessId) async {
    if(!Env.isSupabaseConfigured)return DemoStore.products;
    final rows=await _client.from('irkop_cell_products').select('id,name,category,sell_price,stock').eq('business_id',businessId).eq('is_active',true).order('name');
    return rows.map<Product>((r)=>Product(id:r['id'] as String,name:r['name'] as String,category:(r['category'] as String?)??'Lainnya',price:(r['sell_price'] as num).toDouble(),stock:(r['stock'] as num).toDouble())).toList();
  }
  Future<void> createProduct({required String businessId,required String name,required String category,required double price,required double stock}){_validate(name,price,stock);return _client.from('irkop_cell_products').insert({'business_id':businessId,'name':name.trim(),'category':category.trim().isEmpty?'Lainnya':category.trim(),'sell_price':price,'stock':stock,'is_active':true});}
  Future<void> updateProduct({required String id,required String businessId,required String name,required String category,required double price,required double stock}){_validate(name,price,stock);return _client.from('irkop_cell_products').update({'name':name.trim(),'category':category.trim().isEmpty?'Lainnya':category.trim(),'sell_price':price,'stock':stock}).eq('id',id).eq('business_id',businessId);}
  Future<void> archiveProduct({required String id,required String businessId})=>_client.from('irkop_cell_products').update({'is_active':false}).eq('id',id).eq('business_id',businessId);
}