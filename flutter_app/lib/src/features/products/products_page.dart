import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<List<Product>> _load() =>
      widget.businessId == null ? Future.value(const []) : _repo.loadProducts(widget.businessId!);

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _edit([Product? product]) async {
    final businessId = widget.businessId;
    if (businessId == null) {
      _message('Bisnis belum siap.');
      return;
    }

    final name = TextEditingController(text: product?.name ?? '');
    final category = TextEditingController(text: product?.category ?? '');
    final price = TextEditingController(text: product == null ? '' : formatRupiahInput(product.price));
    final stock = TextEditingController(text: product?.stock.toStringAsFixed(0) ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product == null ? 'Tambah Produk' : 'Edit Produk',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nama produk', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: category,
                decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Harga jual', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: stock,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Stok', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == true && name.text.trim().isNotEmpty) {
      try {
        final parsedPrice = parseRupiah(price.text).toDouble();
        final parsedStock = double.tryParse(stock.text.replaceAll(',', '.'));
        if(parsedPrice<0||parsedStock==null||parsedStock<0){_message('Harga dan stok harus berupa angka 0 atau lebih.');return;}
        if (product == null) {
          await _repo.createProduct(
            businessId: businessId,
            name: name.text,
            category: category.text,
            price: parsedPrice,
            stock: parsedStock,
          );
        } else {
          await _repo.updateProduct(
            id: product.id,
            businessId: businessId,
            name: name.text,
            category: category.text,
            price: parsedPrice,
            stock: parsedStock,
          );
        }
        await _refresh();
        _message(product == null ? 'Produk ditambahkan.' : 'Produk diperbarui.');
      } catch (e) {
        _message('Gagal menyimpan: $e');
      }
    }

    name.dispose();
    category.dispose();
    price.dispose();
    stock.dispose();
  }

  Future<void> _delete(Product product) async {
    final businessId = widget.businessId;
    if (businessId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: Text('Produk "${product.name}" akan dihapus dari daftar aktif.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repo.archiveProduct(id: product.id, businessId: businessId);
        await _refresh();
        _message('Produk dihapus dari daftar aktif.');
      } catch (e) {
        _message('Gagal menghapus: $e');
      }
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snapshot) {
          final data = (snapshot.data ?? const <Product>[])
              .where((p) {
                final q = _query.toLowerCase();
                return p.name.toLowerCase().contains(q) ||
                    p.category.toLowerCase().contains(q);
              })
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              IrkopSectionHeader(
                eyebrow: 'Produk & stok',
                title: 'Katalog Produk',
                subtitle: 'Tambah, edit, hapus dan pantau stok produk.',
                icon: Icons.inventory_2_outlined,
                action: 'Tambah Produk',
                onAction: () => _edit(),
              ),
              const SizedBox(height: 14),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Cari produk atau kategori',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (snapshot.hasError)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text('Gagal memuat produk: ${snapshot.error}'),
                  ),
                ),
              if (snapshot.connectionState == ConnectionState.done &&
                  !snapshot.hasError &&
                  data.isEmpty)
                EmptyStateCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Belum ada produk',
                  subtitle: 'Tambahkan produk baru dari tombol Tambah Produk.',
                ),
              ...data.map(
                (product) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.inventory_2_outlined),
                    ),
                    title: Text(product.name),
                    subtitle: Text(
                      '${product.category} • Stok ${product.stock.toStringAsFixed(0)}',
                    ),
                    trailing: Wrap(
                      spacing: 2,
                      children: [
                        Text(
                          money.format(product.price),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _edit(product),
                        ),
                        IconButton(
                          tooltip: 'Hapus',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(product),
                        ),
                      ],
                    ),
                    onTap: () => _edit(product),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
