import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';
import '../models/business_models.dart';
import 'demo_store.dart';
class ProductRepository {final SupabaseClient _client=Supabase.instance.client;
Future<List<Product>> loadProducts(String businessId) async {if(!Env.isSupabaseConfigured)return DemoStore.products;final rows=await _client.from('irkop_cell_products').select('id,name,category,sell_price,stock').eq('business_id',businessId).eq('is_active',true).order('name');return rows.map<Product>((r)=>Product(id:r['id'] as String,name:r['name'] as String,category:(r['category'] as String?)??'Lainnya',price:(r['sell_price'] as num).toDouble(),stock:(r['stock'] as num).toDouble())).toList();}
Future<void> createProduct({required String businessId,required String name,required String category,required double price,required double stock}) async {await _client.from('irkop_cell_products').insert({'business_id':businessId,'name':name.trim(),'category':category.trim().isEmpty?'Lainnya':category.trim(),'sell_price':price,'stock':stock,'is_active':true});}}
