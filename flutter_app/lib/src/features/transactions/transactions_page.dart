import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/transaction_repository.dart';
import '../../shared/irkop_ui.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key, this.businessId});
  final String? businessId;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _repo = TransactionRepository();
  late Future<List<TransactionSummary>> _future;
  String _query = ''; String _status='all'; String _method='all'; int _days=30;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<TransactionSummary>> _load() {
    final businessId = widget.businessId;
    if (businessId == null) return Future.value(const []);
    return _repo.loadTransactions(businessId);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<TransactionSummary>>(
        future: _future,
        builder: (context, snapshot) {
          final transactions = (snapshot.data ?? const <TransactionSummary>[])
              .where((item) {
                final q = _query.trim().toLowerCase();
                final start=DateTime.now().subtract(Duration(days:_days)); return (q.isEmpty||item.transactionNo.toLowerCase().contains(q)||item.paymentMethod.toLowerCase().contains(q)||item.status.toLowerCase().contains(q))&&(_status=='all'||item.status==_status)&&(_method=='all'||item.paymentMethod==_method)&&!item.transactionAt.toLocal().isBefore(start);
              })
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const IrkopSectionHeader(
                eyebrow: 'Riwayat penjualan',
                title: 'Transaksi',
                subtitle: 'Tarik ke bawah untuk memperbarui riwayat transaksi.',
                icon: Icons.receipt_long_outlined,
                action: 'Riwayat aktif',
              ),
              const SizedBox(height: 14),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Cari nomor transaksi',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 10),Wrap(spacing:8,children:[ChoiceChip(label:const Text('30 Hari'),selected:_days==30,onSelected:(_)=>setState(()=>_days=30)),ChoiceChip(label:const Text('90 Hari'),selected:_days==90,onSelected:(_)=>setState(()=>_days=90)),DropdownButton<String>(value:_status,items:const [DropdownMenuItem(value:'all',child:Text('Semua status')),DropdownMenuItem(value:'completed',child:Text('Selesai'))],onChanged:(v)=>setState(()=>_status=v??'all')),DropdownButton<String>(value:_method,items:const [DropdownMenuItem(value:'all',child:Text('Semua bayar')),DropdownMenuItem(value:'cash',child:Text('Tunai')),DropdownMenuItem(value:'transfer',child:Text('Transfer')),DropdownMenuItem(value:'credit',child:Text('Kasbon'))],onChanged:(v)=>setState(()=>_method=v??'all'))]),const SizedBox(height: 12),
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
                    child: Text('Gagal memuat transaksi: ${snapshot.error}'),
                  ),
                ),
              if (snapshot.connectionState == ConnectionState.done &&
                  !snapshot.hasError &&
                  transactions.isEmpty)
                const EmptyStateCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'Belum ada transaksi',
                  subtitle: 'Transaksi dari Kasir akan muncul di halaman ini.',
                ),
              ...transactions.map(
                (item) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.receipt_long_outlined),
                    ),
                    title: Text(item.transactionNo),
                    subtitle: Text(
                      '${item.paymentMethod} • ${item.status}\n'
                      '${item.transactionAt.toLocal().toString().substring(0, 16)}',
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      money.format(item.total),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onTap: () => _showDetails(item),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDetails(TransactionSummary transaction) async {
    List<TransactionItemSummary> items;
    try{items=await _repo.loadTransactionItems(transaction.id);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gagal memuat detail transaksi: '+e.toString())));return;}
    if (!mounted) return;
    final money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          children: [
            Text(
              transaction.transactionNo,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('${transaction.paymentMethod} • ${transaction.status}'),
            const Divider(height: 28),
            ...items.map(
              (item) => ListTile(
                title: Text(item.productName),
                subtitle: Text('${item.qty.toStringAsFixed(0)} × ${money.format(item.unitPrice)}'),
                trailing: Text(money.format(item.subtotal)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
