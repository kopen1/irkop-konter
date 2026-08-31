import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';
import '../models/business_models.dart';

class TransactionSummary {
  const TransactionSummary({required this.id,required this.transactionNo,required this.paymentMethod,required this.status,required this.total,required this.transactionAt});
  final String id, transactionNo, paymentMethod, status;
  final double total;
  final DateTime transactionAt;
  factory TransactionSummary.fromMap(Map<String,dynamic> row)=>TransactionSummary(
    id:row['id'] as String, transactionNo:row['transaction_no'] as String,
    paymentMethod:row['payment_method'] as String,status:row['status'] as String,
    total:(row['total'] as num).toDouble(),transactionAt:DateTime.parse(row['transaction_at'] as String));
}
class DashboardMetrics {
  const DashboardMetrics({required this.todayRevenue,required this.todayTransactions,required this.recentTransactions});
  final double todayRevenue; final int todayTransactions; final List<TransactionSummary> recentTransactions;
}
class TransactionRepository {
  final SupabaseClient _client=Supabase.instance.client;

  Future<List<TransactionSummary>> loadTransactions(String businessId,{int limit=50}) async {
    if(!Env.isSupabaseConfigured) return const [];
    final rows=await _client.from('irkop_cell_transactions')
      .select('id,transaction_no,payment_method,status,total,transaction_at')
      .eq('business_id',businessId).order('transaction_at',ascending:false).limit(limit);
    return rows.map<TransactionSummary>((row)=>TransactionSummary.fromMap(row)).toList();
  }

  Future<DashboardMetrics> loadDashboard(String businessId) async {
    final transactions=await loadTransactions(businessId,limit:150);
    final now=DateTime.now(); final today=DateTime(now.year,now.month,now.day);
    final completed=transactions.where((t){final d=t.transactionAt.toLocal();return !d.isBefore(today)&&t.status=='completed';}).toList();
    return DashboardMetrics(todayRevenue:completed.fold(0,(sum,t)=>sum+t.total),todayTransactions:completed.length,recentTransactions:transactions.take(8).toList());
  }

  Future<TransactionSummary> checkout({
    required String businessId, required String outletId, required List<CartItem> items, required String paymentMethod,
  }) async {
    if(items.isEmpty) throw StateError('Keranjang kosong.');
    final total=items.fold<double>(0,(sum,item)=>sum+item.subtotal);
    final no='TRX-${DateTime.now().microsecondsSinceEpoch}';
    final transaction=await _client.from('irkop_cell_transactions').insert({
      'business_id':businessId,'outlet_id':outletId,'transaction_no':no,
      'payment_method':paymentMethod,'status':'completed','total':total,
    }).select('id,transaction_no,payment_method,status,total,transaction_at').single();
    final id=transaction['id'] as String;
    await _client.from('irkop_cell_transaction_items').insert(items.map((item)=>({
      'transaction_id':id,'product_id':item.product.id,'product_name':item.product.name,
      'qty':item.qty,'unit_price':item.product.price,'subtotal':item.subtotal,
    })).toList());
    for(final item in items){
      final nextStock=item.product.stock-item.qty;
      await _client.from('irkop_cell_products').update({'stock':nextStock<0?0:nextStock}).eq('id',item.product.id).eq('business_id',businessId);
    }
    if(paymentMethod=='cash'){
      await _client.from('irkop_cell_cash_mutations').insert({
        'business_id':businessId,'outlet_id':outletId,'transaction_id':id,
        'mutation_type':'in','amount':total,'description':'Penjualan $no',
      });
    }
    return TransactionSummary.fromMap(transaction);
  }
}
