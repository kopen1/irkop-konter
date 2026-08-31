import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

class TransactionSummary {
  const TransactionSummary({
    required this.id,
    required this.transactionNo,
    required this.paymentMethod,
    required this.status,
    required this.total,
    required this.transactionAt,
  });

  final String id;
  final String transactionNo;
  final String paymentMethod;
  final String status;
  final double total;
  final DateTime transactionAt;

  factory TransactionSummary.fromMap(Map<String, dynamic> row) {
    return TransactionSummary(
      id: row['id'] as String,
      transactionNo: row['transaction_no'] as String,
      paymentMethod: row['payment_method'] as String,
      status: row['status'] as String,
      total: (row['total'] as num).toDouble(),
      transactionAt: DateTime.parse(row['transaction_at'] as String),
    );
  }
}

class DashboardMetrics {
  const DashboardMetrics({
    required this.todayRevenue,
    required this.todayTransactions,
    required this.recentTransactions,
  });

  final double todayRevenue;
  final int todayTransactions;
  final List<TransactionSummary> recentTransactions;
}

class TransactionRepository {
  Future<String?> _demoBusinessId() async {
    if (!Env.isSupabaseConfigured) return null;

    final business = await Supabase.instance.client
        .from('irkop_cell_businesses')
        .select('id')
        .eq('is_demo', true)
        .limit(1)
        .maybeSingle();

    return business?['id'] as String?;
  }

  Future<List<TransactionSummary>> loadDemoTransactions({int limit = 50}) async {
    final businessId = await _demoBusinessId();
    if (businessId == null) return const [];

    final rows = await Supabase.instance.client
        .from('irkop_cell_transactions')
        .select('id,transaction_no,payment_method,status,total,transaction_at')
        .eq('business_id', businessId)
        .order('transaction_at', ascending: false)
        .limit(limit);

    return rows
        .map<TransactionSummary>(
          (row) => TransactionSummary.fromMap(row),
        )
        .toList();
  }

  Future<DashboardMetrics> loadDemoDashboard() async {
    final transactions = await loadDemoTransactions(limit: 150);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayTransactions = transactions.where((transaction) {
      final value = transaction.transactionAt.toLocal();
      return !value.isBefore(today) && transaction.status == 'completed';
    }).toList();

    return DashboardMetrics(
      todayRevenue: todayTransactions.fold<double>(
        0,
        (total, transaction) => total + transaction.total,
      ),
      todayTransactions: todayTransactions.length,
      recentTransactions: transactions.take(8).toList(),
    );
  }
}
