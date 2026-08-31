import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/product_repository.dart';
import '../../core/models/business_models.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key});
  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final _repository = ProductRepository();
  final cart = <CartItem>[];
  late final Future<List<Product>> _productsFuture;
  String query = '';

  @override
  void initState() {
    super.initState();
    _productsFuture = _repository.loadDemoProducts();
  }

  @override
  Widget build(BuildContext context) {
    final total = cart.fold<double>(0, (v, x) => v + x.subtotal);
    final f = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: TextField(
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari produk'),
        onChanged: (v) => setState(() => query = v),
      )),
      Expanded(child: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final products = (snapshot.data ?? const <Product>[])
              .where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();
          if (products.isEmpty) return const Center(child: Text('Belum ada produk demo'));
          return ListView(children: products.map((p) => ListTile(
            leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
            title: Text(p.name),
            subtitle: Text(p.category+' • '+f.format(p.price)),
            trailing: IconButton(icon: const Icon(Icons.add_circle), onPressed: () => _add(p)),
          )).toList());
        },
      )),
      Container(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Total '+f.format(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: cart.isEmpty ? null : () => _checkout(context, f, total),
          icon: const Icon(Icons.payments),
          label: Text('Bayar ('+cart.length.toString()+' item)'),
        ),
      ])),
    ]);
  }

  void _add(Product p) {
    final i = cart.indexWhere((x) => x.product.id == p.id);
    setState(() {
      if (i < 0) cart.add(CartItem(product: p, qty: 1));
      else cart[i] = cart[i].copyWith(qty: cart[i].qty + 1);
    });
  }

  Future<void> _checkout(BuildContext context, NumberFormat f, double total) async {
    final payment = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: ['Tunai', 'Transfer'].map((x) => ListTile(title: Text(x), onTap: () => Navigator.pop(c, x))).toList(),
      )),
    );
    if (payment != null && mounted) {
      setState(cart.clear);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaksi demo '+f.format(total)+' • '+payment)),
      );
    }
  }
}
