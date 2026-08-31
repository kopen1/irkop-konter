import 'package:flutter/material.dart';
import '../../shared/app_page_index.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key, required this.onOpen});
  final void Function(int) onOpen;

  @override
  Widget build(BuildContext context) {
    final groups = <_MoreGroup>[
      _MoreGroup('Master Data', [
        _MoreItem(Icons.inventory_2_outlined, 'Produk', 'Katalog, kategori & stok', AppPageIndex.products),
        _MoreItem(Icons.people_outline, 'Pelanggan', 'Data pelanggan', AppPageIndex.customers),
      ]),
      _MoreGroup('Operasional', [
        _MoreItem(Icons.credit_score_outlined, 'Kasbon / Piutang', 'Tagihan & pembayaran', AppPageIndex.credits),
        _MoreItem(Icons.account_balance_wallet_outlined, 'Pengeluaran', 'Biaya operasional', AppPageIndex.expenses),
        _MoreItem(Icons.storefront_outlined, 'Outlet', 'Kelola outlet aktif', AppPageIndex.outlets),
        _MoreItem(Icons.devices_outlined, 'Perangkat', 'Slot & perangkat', AppPageIndex.devices),
      ]),
      _MoreGroup('Analitik & Sistem', [
        _MoreItem(Icons.bar_chart_outlined, 'Laporan', 'Penjualan & ringkasan bisnis', AppPageIndex.reports),
        _MoreItem(Icons.settings_outlined, 'Pengaturan', 'Bisnis, akun & sistem', AppPageIndex.settings),
      ]),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Menu',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pusat pengelolaan IRKOP Konter',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        ...groups.expand((group) => [
              _GroupLabel(title: group.title),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < group.items.length; i++) ...[
                      _MenuTile(
                        item: group.items[i],
                        onTap: () => onOpen(group.items[i].index),
                      ),
                      if (i != group.items.length - 1)
                        const Divider(height: 1, indent: 68),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ]),
        const _ConnectionCard(),
      ],
    );
  }
}

class _MoreGroup {
  const _MoreGroup(this.title, this.items);
  final String title;
  final List<_MoreItem> items;
}

class _MoreItem {
  const _MoreItem(this.icon, this.title, this.subtitle, this.index);
  final IconData icon;
  final String title;
  final String subtitle;
  final int index;
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
        ),
      );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item, required this.onTap});
  final _MoreItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(item.subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard();
  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(child: Icon(Icons.cloud_done_outlined)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sinkronisasi cloud', style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text('Data bisnis tersimpan dan siap disinkronkan.'),
                  ],
                ),
              ),
              Icon(Icons.verified_rounded, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      );
}
