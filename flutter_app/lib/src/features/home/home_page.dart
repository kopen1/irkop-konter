import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/data/transaction_repository.dart';
import '../cashier/cashier_page.dart';
import '../reports/reports_page.dart';
import '../transactions/transactions_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.demoMode});

  final bool demoMode;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Dashboard(demoMode: widget.demoMode),
      const TransactionsPage(),
      const CashierPage(),
      const ReportsPage(),
    ];
    const titles = ['Dashboard', 'Transaksi', 'Kasir', 'Laporan'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
        actions: widget.demoMode
            ? const [
                Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Center(child: Chip(label: Text('MODE DEMO'))),
                ),
              ]
            : null,
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transaksi',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Kasir',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }
}

class _Dashboard extends StatefulWidget {
  const _Dashboard({required this.demoMode});

  final bool demoMode;

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  final _repository = TransactionRepository();
  late Future<DashboardMetrics> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadDemoDashboard();
  }

  Future<void> _refresh() async {
    setState(() => _future = _repository.loadDemoDashboard());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<DashboardMetrics>(
        future: _future,
        builder: (context, snapshot) {
          final metrics = snapshot.data;
          final revenue = metrics?.todayRevenue ?? 0;
          final transactions = metrics?.todayTransactions ?? 0;
          final recent = metrics?.recentTransactions ?? const <TransactionSummary>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'IRKOP Konter',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                widget.demoMode
                    ? 'Data demo dari Supabase'
                    : 'Data operasional outlet',
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState != ConnectionState.done)
                const LinearProgressIndicator(),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.28,
                children: [
                  _MetricCard(
                    icon: Icons.payments_outlined,
                    label: 'Omzet Hari Ini',
                    value: currency.format(revenue),
                  ),
                  _MetricCard(
                    icon: Icons.receipt_long_outlined,
                    label: 'Transaksi',
                    value: transactions.toString(),
                  ),
                  const _MetricCard(
                    icon: Icons.credit_score_outlined,
                    label: 'Kasbon Aktif',
                    value: '-',
                  ),
                  const _MetricCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Saldo Kas',
                    value: '-',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Transaksi Terbaru',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (snapshot.hasError)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('Gagal memuat data Supabase'),
                ),
              if (!snapshot.hasError && recent.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('Belum ada transaksi demo'),
                ),
              ...recent.map(
                (transaction) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.receipt),
                    ),
                    title: Text(transaction.transactionNo),
                    subtitle: Text(
                      '${transaction.paymentMethod} • ${transaction.status}',
                    ),
                    trailing: Text(currency.format(transaction.total)),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const Spacer(),
            Text(label),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
