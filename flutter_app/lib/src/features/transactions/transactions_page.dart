import 'package:flutter/material.dart';
import '../../shared/irkop_ui.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key, this.businessId});
  final String? businessId;
  @override State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _query = '';
  static const _rows = [
    _TransactionRow('TRX-DEMO-001', 'CASH', 25000),
    _TransactionRow('TRX-DEMO-002', 'TRANSFER', 18000),
  ];
  String _rupiah(double value) => 'Rp ' + value.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    final rows = _rows.where((row) => row.no.toLowerCase().contains(_query.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const IrkopSectionHeader(
            eyebrow: 'Riwayat penjualan',
            title: 'Transaksi',
            subtitle: 'Riwayat transaksi tersedia di sini.',
            icon: Icons.receipt_long_outlined,
            action: 'Demo siap',
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
          const SizedBox(height: 12),
          ...rows.map((row) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
              title: Text(row.no),
              subtitle: Text(row.method),
              trailing: Text(_rupiah(row.total), style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          )),
        ],
      ),
    );
  }
}

class _TransactionRow {
  const _TransactionRow(this.no, this.method, this.total);
  final String no;
  final String method;
  final double total;
}
