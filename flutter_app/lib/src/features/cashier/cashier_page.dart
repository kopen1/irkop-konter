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
    final total = cart.fold<double>(0, (value, item) => value + item.subtotal);
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Cari produk',
            ),
            onChanged: (value) => setState(() => query = value),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Product>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = (snapshot.data ?? const <Product>[])
                  .where(
                    (product) => product.name
                        .toLowerCase()
                        .contains(query.toLowerCase()),
                  )
                  .toList();

              if (products.isEmpty) {
                return const Center(child: Text('Belum ada produk demo'));
              }

              return ListView(
                children: products
                    .map(
                      (product) => ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.inventory_2_outlined),
                        ),
                        title: Text(product.name),
                        subtitle: Text(
                          '${product.category} • ${currency.format(product.price)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: () => _add(product),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Total ${currency.format(total)}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: cart.isEmpty
                    ? null
                    : () => _checkout(context, currency, total),
                icon: const Icon(Icons.payments),
                label: Text('Bayar (${cart.length} item)'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _add(Product product) {
    final index = cart.indexWhere((item) => item.product.id == product.id);

    setState(() {
      if (index < 0) {
        cart.add(CartItem(product: product, qty: 1));
      } else {
        cart[index] = cart[index].copyWith(qty: cart[index].qty + 1);
      }
    });
  }

  Future<void> _checkout(
    BuildContext context,
    NumberFormat currency,
    double total,
  ) async {
    final payment = await showModalBottomSheet<String>(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Tunai', 'Transfer']
              .map(
                (method) => ListTile(
                  title: Text(method),
                  onTap: () => Navigator.pop(bottomSheetContext, method),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (!mounted || payment == null) {
      return;
    }

    setState(cart.clear);
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text(
          'Transaksi demo ${currency.format(total)} • $payment',
        ),
      ),
    );
  }
}
