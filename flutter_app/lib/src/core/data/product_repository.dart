import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';
import '../models/business_models.dart';
import 'demo_store.dart';

class ProductRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Product>> loadProducts(String businessId) async {
    if (!Env.isSupabaseConfigured) return DemoStore.products;
    final rows = await _client
        .from('irkop_cell_products')
        .select('id,name,category,sell_price,stock')
        .eq('business_id', businessId)
        .eq('is_active', true)
        .order('name');
    return rows.map<Product>((row) => Product(
      id: row['id'] as String,
      name: row['name'] as String,
      category: (row['category'] as String?) ?? 'Lainnya',
      price: (row['sell_price'] as num).toDouble(),
      stock: (row['stock'] as num).toDouble(),
    )).toList();
  }
}
