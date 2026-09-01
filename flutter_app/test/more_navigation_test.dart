import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irkop_cell/src/features/more/more_page.dart';
import 'package:irkop_cell/src/shared/app_page_index.dart';

void main() {
  Future<void> pumpMenu(
    WidgetTester tester,
    void Function(int) onOpen,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MorePage(onOpen: onOpen)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('every menu item opens the expected page index', (tester) async {
    int? opened;

    await pumpMenu(tester, (value) => opened = value);

    final cases = <String, int>{
      'Produk': AppPageIndex.products,
      'Pelanggan': AppPageIndex.customers,
      'Kasbon / Piutang': AppPageIndex.credits,
      'Pengeluaran': AppPageIndex.expenses,
      'Gaji Karyawan': AppPageIndex.payroll,
      'Service HP': AppPageIndex.service,
      'Outlet': AppPageIndex.outlets,
      'Perangkat': AppPageIndex.devices,
      'Laporan': AppPageIndex.reports,
      'Pengaturan': AppPageIndex.settings,
    };

    for (final item in cases.entries) {
      opened = null;
      await tester.ensureVisible(find.text(item.key));
      await tester.tap(find.text(item.key));
      await tester.pump();
      expect(opened, item.value, reason: 'Route ' + item.key + ' tidak boleh salah indeks');
    }
  });
}
