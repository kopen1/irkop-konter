import 'package:flutter_test/flutter_test.dart';
import 'package:irkop_konter/src/shared/app_page_index.dart';

void main() {
  test('all application page indexes are unique and contiguous', () {
    final indexes = <int>[
      AppPageIndex.dashboard,
      AppPageIndex.cashier,
      AppPageIndex.transactions,
      AppPageIndex.products,
      AppPageIndex.customers,
      AppPageIndex.reports,
      AppPageIndex.credits,
      AppPageIndex.outlets,
      AppPageIndex.devices,
      AppPageIndex.settings,
      AppPageIndex.expenses,
      AppPageIndex.payroll,
      AppPageIndex.service,
      AppPageIndex.more,
    ];

    expect(indexes, List<int>.generate(indexes.length, (i) => i));
    expect(indexes.toSet().length, indexes.length);
  });
}
