import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/product_repository.dart';
import '../../core/models/business_models.dart';
import '../../shared/irkop_ui.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, this.businessId});
  final String? businessId;
  @override State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _repo = ProductRepository();
  late Future<List<Product>> _future;
  String _query = '';

  @override
  void initState() { super.initState(); _future = _load(); }

  Future<List<Product>> _load() => widget.businessId == null
      ? Future.value(const [])
      : _repo.loadProducts(widget.businessId!);

  Future<void> _refresh() async { setState(() => _future = _load()); await _future; }

  Future<void> _edit([Product? product]) async {
    if (widget.businessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bisnis belum siap.')));
      return;
    }
    final name = TextEditingController(text: product?.name ?? '');
    final category = TextEditingController(text: product?.category ?? '');
    final price = TextEditingController(text: product?.price.toStringAsFixed(0) ?? '');
    final stock = TextEditingController(text: product?.stock.toStringAsFixed(0) ?? '');
    final ok = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(product == null ? 'Tambah Produk' : 'Edit Produk', style: Theme.of(sheetContext).textTheme.titleLarge),
          const SizedBox(height: 14),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama produk', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: category, decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Harga jual', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: stock, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Stok', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(sheetContext, true), child: const Text('Simpan'))),
        ])),
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      try {
        final parsedPrice = double.tryParse(price.text.replaceAll(',', '.')) ?? 0;
        final parsedStock = double.tryParse(stock.text.replaceAll(',', '.')) ?? 0;
        if (product == null) {
          await _repo.createProduct(businessId: widget.businessId!, name: name.text, category: category.text, price: parsedPrice, stock: parsedStock);
        } else {
          await _repo.updateProduct(id: product.id, businessId: widget.businessId!, name: name.text, category: category.text, price: parsedPrice, stock: parsedStock);
        }
        await _refresh();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    }
    name.dispose(); category.dispose(); price.dispose(); stock.dispose();
  }

  Future<void> _archive(Product product) async {
    if (widget.businessId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Nonaktifkan produk?'), content: Text(product.name),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Nonaktifkan')),
        ],
      ),
    );
    if (ok == true) {
      try { await _repo.archiveProduct(id: product.id, businessId: widget.businessId!); await _refresh(); }
      catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'))); }
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
          final data = (snapshot.data ?? const <Product>[])
              .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()) || p.category.toLowerCase().contains(_query.toLowerCase()))
              .toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            IrkopSectionHeader(
              eyebrow: 'Produk & stok', title: 'Katalog Produk',
              subtitle: 'Tambah, ubah, nonaktifkan dan pantau stok produk.',
              icon: Icons.inventory_2_outlined, action: 'Tambah', onAction: () => _edit(),
            ),
            const SizedBox(height: 14),
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari produk atau kategori', border: OutlineInputBorder()),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            if (snapshot.connectionState != ConnectionState.done) const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            if (snapshot.hasError) Text('Gagal memuat: ${snapshot.error}'),
            if (snapshot.connectionState == ConnectionState.done && !snapshot.hasError && data.isEmpty)
              const EmptyStateCard(icon: Icons.inventory_2_outlined, title: 'Belum ada produk', subtitle: 'Tambahkan produk baru dari tombol Tambah.'),
            ...data.map((p) => Card(child: ListTile(
              onTap: () => _edit(p),
              leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
              title: Text(p.name),
              subtitle: Text('${p.category} • Stok ${p.stock.toStringAsFixed(0)}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(money.format(p.price), style: const TextStyle(fontWeight: FontWeight.w800)),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () => _archive(p)),
              ]),
            ))),
          ]);
        },
      ),
    );
  }
}