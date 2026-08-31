import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/data/transaction_repository.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _repository = TransactionRepository();
  late Future<List<TransactionSummary>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _repository.loadDemoTransactions();
  }

  Future<void> _refresh() async {
    setState(() => _future = _repository.loadDemoTransactions());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Cari nomor transaksi',
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: FutureBuilder<List<TransactionSummary>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Gagal memuat transaksi demo')),
                    ],
                  );
                }

                final transactions = (snapshot.data ?? const [])
                    .where(
                      (transaction) => transaction.transactionNo
                          .toLowerCase()
                          .contains(_query.toLowerCase()),
                    )
                    .toList();

                if (transactions.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Belum ada transaksi demo')),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.receipt_long),
                        ),
                        title: Text(transaction.transactionNo),
                        subtitle: Text(
                          '${_paymentLabel(transaction.paymentMethod)} • ${_statusLabel(transaction.status)}',
                        ),
                        trailing: Text(currency.format(transaction.total)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _paymentLabel(String value) {
    switch (value) {
      case 'cash':
      case 'cash_tunai':
        return 'Tunai';
      case 'transfer':
        return 'Transfer';
      case 'credit':
        return 'Kasbon';
      default:
        return value;
    }
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'completed':
        return 'Selesai';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return value;
    }
  }
}
