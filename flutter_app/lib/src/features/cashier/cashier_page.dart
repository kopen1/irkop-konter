import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/data/product_repository.dart';
import '../../core/data/transaction_repository.dart';
import '../../core/models/business_models.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key, this.businessId, this.outletId});

  final String? businessId;
  final String? outletId;

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final _products = ProductRepository();
  final _transactions = TransactionRepository();
  final cart = <CartItem>[];

  late Future<List<Product>> _future;
  String query = '';

  @override
  void initState() {
    super.initState();
    _future = widget.businessId == null
        ? Future.value(const <Product>[])
        : _products.loadProducts(widget.businessId!);
  }

  @override
  Widget build(BuildContext context) {
    final total = cart.fold<double>(0, (sum, item) => sum + item.subtotal);
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

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
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Gagal memuat produk: ${snapshot.error}'),
                );
              }

              final products = (snapshot.data ?? const <Product>[])
                  .where(
                    (product) =>
                        product.name.toLowerCase().contains(query.toLowerCase()),
                  )
                  .toList();

              if (products.isEmpty) {
                return const Center(
                  child: Text('Belum ada produk. Tambahkan produk di database.'),
                );
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
                          '${product.category} • '
                          '${currency.format(product.price)} • '
                          'Stok ${product.stock}',
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: cart.isEmpty || widget.businessId == null
                    ? null
                    : () => _checkout(currency),
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

  Future<void> _checkout(NumberFormat currency) async {
    final payment = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['cash', 'transfer', 'credit']
                .map(
                  (method) => ListTile(
                    title: Text(
                      method == 'cash'
                          ? 'Tunai'
                          : method == 'credit'
                              ? 'Kasbon'
                              : 'Transfer',
                    ),
                    onTap: () => Navigator.pop(sheetContext, method),
                  ),
                )
                .toList(),
          ),
        );
      },
    );

    if (payment == null || !mounted) return;

    try {
      final total = cart.fold<double>(
        0,
        (sum, item) => sum + item.subtotal,
      );

      await _transactions.checkout(
        businessId: widget.businessId!,
        outletId: widget.outletId!,
        items: List.of(cart),
        paymentMethod: payment,
      );

      if (!mounted) return;

      setState(cart.clear);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transaksi berhasil • ${currency.format(total)}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaksi gagal: $error')),
      );
    }
  }
}
