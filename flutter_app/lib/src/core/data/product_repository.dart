import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';
import '../models/business_models.dart';
import 'demo_store.dart';

class ProductRepository {
  Future<List<Product>> loadDemoProducts() async {
    if (!Env.isSupabaseConfigured) return DemoStore.products;

    try {
      final business = await Supabase.instance.client
          .from('irkop_cell_businesses')
          .select('id')
          .eq('is_demo', true)
          .limit(1)
          .maybeSingle();

      if (business == null) return DemoStore.products;

      final rows = await Supabase.instance.client
          .from('irkop_cell_products')
          .select('id,name,category,sell_price,stock')
          .eq('business_id', business['id'])
          .eq('is_active', true)
          .order('name');

      return rows.map<Product>((row) => Product(
        id: row['id'] as String,
        name: row['name'] as String,
        category: (row['category'] as String?) ?? 'Lainnya',
        price: (row['sell_price'] as num).toDouble(),
        stock: (row['stock'] as num).toDouble(),
      )).toList();
    } catch (_) {
      return DemoStore.products;
    }
  }
}
