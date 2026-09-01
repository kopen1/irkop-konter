import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/product_repository.dart';
import '../../shared/rupiah_input.dart';
import '../../core/models/business_models.dart';
import '../../shared/irkop_ui.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, this.businessId});
  final String? businessId;
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _repo = ProductRepository();
  late Future<List<Product>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Product>> _load() {
    final id = widget.businessId;
    return id == null ? Future.value(const []) : _repo.loadProducts(id);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
    }
  }

  Future<void> _edit([Product? product]) async {
    final businessId = widget.businessId;
    if (businessId == null) {
      _message('Bisnis belum siap.');
      return;
    }

    final name = TextEditingController(text: product?.name ?? '');
    final sku = TextEditingController(text: product?.sku ?? '');
    final category = TextEditingController(text: product?.category ?? '');
    final price = TextEditingController(text: product == null ? '' : formatRupiahInput(product.price));
    final cost = TextEditingController(text: product == null ? '' : formatRupiahInput(product.costPrice));
    final stock = TextEditingController(text: product?.stock.toStringAsFixed(0) ?? '');
    final minStock = TextEditingController(text: product?.minStock.toStringAsFixed(0) ?? '');
    final unit = TextEditingController(text: product?.unit ?? 'pcs');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(product == null ? 'Tambah Produk' : 'Edit Produk', style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: 14),
                TextField(controller: sku, decoration: const InputDecoration(labelText: 'Kode produk / SKU')),
                const SizedBox(height: 10),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama produk')),
                const SizedBox(height: 10),
                TextField(controller: category, decoration: const InputDecoration(labelText: 'Kategori')),
                const SizedBox(height: 10),
                TextField(controller: price, keyboardType: TextInputType.number, inputFormatters: [RupiahInputFormatter()], decoration: const InputDecoration(labelText: 'Harga jual', prefixText: 'Rp ')),
                const SizedBox(height: 10),
                TextField(controller: cost, keyboardType: TextInputType.number, inputFormatters: [RupiahInputFormatter()], decoration: const InputDecoration(labelText: 'Harga modal', prefixText: 'Rp ')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: minStock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok minimum'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: unit, decoration: const InputDecoration(labelText: 'Satuan')),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(sheetContext, true), child: const Text('Simpan'))),
              ],
            ),
          ),
        );
      },
    );

    if (saved == true && name.text.trim().isNotEmpty) {
      try {
        final sellPrice = parseRupiah(price.text).toDouble();
        final costPrice = parseRupiah(cost.text).toDouble();
        final stockValue = double.tryParse(stock.text.replaceAll(',', '.')) ?? 0;
        final minValue = double.tryParse(minStock.text.replaceAll(',', '.')) ?? 0;
        if (sellPrice < 0 || costPrice < 0 || stockValue < 0 || minValue < 0) {
          throw StateError('Nilai tidak boleh negatif.');
        }
        if (product == null) {
          await _repo.createProduct(businessId: businessId, name: name.text, category: category.text, price: sellPrice, stock: stockValue, sku: sku.text, costPrice: costPrice, minStock: minValue, unit: unit.text);
        } else {
          await _repo.updateProduct(id: product.id, businessId: businessId, name: name.text, category: category.text, price: sellPrice, stock: stockValue, sku: sku.text, costPrice: costPrice, minStock: minValue, unit: unit.text);
        }
        await _refresh();
        _message(product == null ? 'Produk ditambahkan.' : 'Produk diperbarui.');
      } catch (error) {
        _message('Gagal menyimpan: $error');
      }
    }

    for (final controller in [name, sku, category, price, cost, stock, minStock, unit]) {
      controller.dispose();
    }
  }

  Future<void> _delete(Product product) async {
    final businessId = widget.businessId;
    if (businessId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: Text('Produk "${product.name}" akan dinonaktifkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _repo.archiveProduct(id: product.id, businessId: businessId);
        await _refresh();
        _message('Produk dinonaktifkan.');
      } catch (error) {
        _message('Gagal menghapus: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snapshot) {
          final products = snapshot.data ?? const <Product>[];
          final query = _query.toLowerCase().trim();
          final filtered = products.where((product) {
            return product.name.toLowerCase().contains(query) || product.category.toLowerCase().contains(query) || product.sku.toLowerCase().contains(query);
          }).toList();
          final children = <Widget>[
            IrkopSectionHeader(eyebrow: 'Produk & stok', title: 'Katalog Produk', subtitle: 'CRUD produk, stok minimum, SKU, harga modal dan satuan.', icon: Icons.inventory_2_outlined, action: 'Tambah Produk', onAction: _edit),
            const SizedBox(height: 14),
            TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari kode, nama atau kategori', border: OutlineInputBorder()), onChanged: (value) => setState(() => _query = value)),
            const SizedBox(height: 14),
          ];

          if (snapshot.connectionState != ConnectionState.done) {
            children.add(const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())));
          } else if (snapshot.hasError) {
            children.add(Card(child: Padding(padding: const EdgeInsets.all(18), child: Text('Gagal memuat produk: ${snapshot.error}'))));
          } else if (filtered.isEmpty) {
            children.add(const EmptyStateCard(icon: Icons.inventory_2_outlined, title: 'Belum ada produk', subtitle: 'Tambahkan produk baru dari tombol di atas.'));
          } else {
            for (final product in filtered) {
              final lowStock = product.minStock > 0 && product.stock <= product.minStock;
              children.add(
                Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(lowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined)),
                    title: Row(
                      children: [
                        Expanded(child: Text(product.name)),
                        if (lowStock)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Chip(label: Text('STOK MENIPIS')),
                          ),
                      ],
                    ),
                    subtitle: Text('${product.sku.isEmpty ? 'Tanpa kode' : product.sku} • ${product.category} • Stok ${product.stock.toStringAsFixed(0)} ${product.unit}${lowStock ? ' • Minimum ${product.minStock.toStringAsFixed(0)} ${product.unit}' : ''}'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(money.format(product.price), style: const TextStyle(fontWeight: FontWeight.w800)),
                      IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(product)),
                      IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(product)),
                    ]),
                    onTap: () => _edit(product),
                  ),
                ),
              );
            }
          }

          return ListView(padding: const EdgeInsets.all(16), children: children);
        },
      ),
    );
  }
}
