import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/transaction_repository.dart';
import '../../shared/irkop_ui.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key, this.businessId});
  final String? businessId;
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _repo = TransactionRepository();
  late Future<List<TransactionSummary>> _future;
  int _days = 7;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<TransactionSummary>> _load() =>
      widget.businessId == null ? Future.value(const []) : _repo.loadTransactions(widget.businessId!, limit: 500);

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
          final now = DateTime.now();
          final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: _days - 1));
          final transactions = (snapshot.data ?? const <TransactionSummary>[])
              .where((t) => t.status == 'completed' && !t.transactionAt.toLocal().isBefore(start))
              .toList();
          final revenue = transactions.fold<double>(0, (value, item) => value + item.total);
          final average = transactions.isEmpty ? 0.0 : revenue / transactions.length;
          final payments = <String, double>{};
          for (final transaction in transactions) {
            payments[transaction.paymentMethod] = (payments[transaction.paymentMethod] ?? 0) + transaction.total;
          }
          final bestPayment = payments.entries.isEmpty ? null : payments.entries.reduce((a, b) => a.value >= b.value ? a : b);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              const IrkopSectionHeader(
                eyebrow: 'Analitik bisnis',
                title: 'Laporan Penjualan',
                subtitle: 'Lihat performa penjualan dan pola pembayaran bisnis Anda.',
                icon: Icons.bar_chart_outlined,
                action: 'Data aktual',
              ),
              const SizedBox(height: 14),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7 Hari')),
                  ButtonSegment(value: 30, label: Text('30 Hari')),
                  ButtonSegment(value: 90, label: Text('90 Hari')),
                ],
                selected: {_days},
                onSelectionChanged: (value) => setState(() => _days = value.first),
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState != ConnectionState.done) const LinearProgressIndicator(),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _MetricCard(icon: Icons.payments_outlined, label: 'Omzet', value: money.format(revenue))),
                const SizedBox(width: 10),
                Expanded(child: _MetricCard(icon: Icons.receipt_long_outlined, label: 'Transaksi', value: transactions.length.toString())),
              ]),
              const SizedBox(height: 10),
              _MetricCard(icon: Icons.trending_up_outlined, label: 'Rata-rata transaksi', value: money.format(average)),
              if (bestPayment != null) ...[
                const SizedBox(height: 20),
                Card(child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.star_outline)),
                  title: const Text('Pembayaran teratas'),
                  subtitle: Text(bestPayment.key.toUpperCase()),
                  trailing: Text(money.format(bestPayment.value), style: const TextStyle(fontWeight: FontWeight.w800)),
                )),
              ],
              const SizedBox(height: 20),
              Text('Metode Pembayaran', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (snapshot.hasError)
                Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Gagal memuat laporan: ${snapshot.error}'))),
              if (!snapshot.hasError && snapshot.connectionState == ConnectionState.done && payments.isEmpty)
                const EmptyStateCard(icon: Icons.bar_chart_outlined, title: 'Belum ada data periode ini', subtitle: 'Transaksi akan muncul setelah ada penjualan.'),
              ...payments.entries.map((entry) => Card(
                child: ListTile(
                  leading: CircleAvatar(child: Icon(Icons.account_balance_wallet_outlined, color: Theme.of(context).colorScheme.primary)),
                  title: Text(entry.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: LinearProgressIndicator(value: revenue <= 0 ? 0 : entry.value / revenue, minHeight: 5, borderRadius: BorderRadius.circular(8)),
                  trailing: Text(money.format(entry.value), style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              )),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        CircleAvatar(child: Icon(icon)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 3),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ])),
      ]),
    ),
  );
}
