import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';
import '../models/business_models.dart';

class TransactionSummary {
  const TransactionSummary({required this.id,required this.transactionNo,required this.paymentMethod,required this.status,required this.total,required this.transactionAt});
  final String id,transactionNo,paymentMethod,status; final double total; final DateTime transactionAt;
  factory TransactionSummary.fromMap(Map<String,dynamic> r)=>TransactionSummary(id:r['id'] as String,transactionNo:r['transaction_no'] as String,paymentMethod:r['payment_method'] as String,status:r['status'] as String,total:(r['total'] as num).toDouble(),transactionAt:DateTime.parse(r['transaction_at'] as String));
}
class TransactionItemSummary {
  const TransactionItemSummary({required this.productName,required this.qty,required this.unitPrice,required this.subtotal});
  final String productName; final double qty,unitPrice,subtotal;
  factory TransactionItemSummary.fromMap(Map<String,dynamic> r)=>TransactionItemSummary(productName:r['product_name'] as String,qty:(r['qty'] as num).toDouble(),unitPrice:(r['unit_price'] as num).toDouble(),subtotal:(r['subtotal'] as num).toDouble());
}
class DashboardMetrics {
  const DashboardMetrics({required this.todayRevenue,required this.todayTransactions,required this.recentTransactions});
  final double todayRevenue; final int todayTransactions; final List<TransactionSummary> recentTransactions;
}
class TransactionRepository {
  final SupabaseClient _client=Supabase.instance.client;
  Future<List<TransactionSummary>> loadTransactions(String businessId,{int limit=200}) async {
    if(!Env.isSupabaseConfigured)return const [];
    final rows=await _client.from('irkop_cell_transactions').select('id,transaction_no,payment_method,status,total,transaction_at').eq('business_id',businessId).order('transaction_at',ascending:false).limit(limit);
    return rows.map<TransactionSummary>((r)=>TransactionSummary.fromMap(r)).toList();
  }
  Future<List<TransactionItemSummary>> loadTransactionItems(String transactionId) async {
    if(!Env.isSupabaseConfigured)return const [];
    final rows=await _client.from('irkop_cell_transaction_items').select('product_name,qty,unit_price,subtotal').eq('transaction_id',transactionId).order('created_at');
    return rows.map<TransactionItemSummary>((r)=>TransactionItemSummary.fromMap(r)).toList();
  }
  Future<void> voidTransaction({required String id,required String businessId,required String reason}) async {
    final clean=reason.trim();if(clean.isEmpty)throw StateError('Alasan void wajib diisi.');
    await _client.rpc('irkop_cell_void_transaction',params:{'p_transaction_id':id,'p_business_id':businessId,'p_reason':clean});
  }
  Future<DashboardMetrics> loadDashboard(String businessId) async {
    final transactions=await loadTransactions(businessId);final now=DateTime.now(),today=DateTime(now.year,now.month,now.day);
    final completed=transactions.where((t){final d=t.transactionAt.toLocal();return !d.isBefore(today)&&t.status=='completed';}).toList();
    return DashboardMetrics(todayRevenue:completed.fold<double>(0,(s,t)=>s+t.total),todayTransactions:completed.length,recentTransactions:transactions.take(8).toList());
  }
  Future<TransactionSummary> checkout({required String businessId,required String outletId,required List<CartItem> items,required String paymentMethod,String? customerId}) async {
    if(items.isEmpty)throw StateError('Keranjang kosong.');
    if(!const {'cash','cash_tunai','transfer','credit'}.contains(paymentMethod))throw StateError('Metode pembayaran tidak valid.');
    if(paymentMethod=='credit'&&customerId==null)throw StateError('Pelanggan wajib dipilih untuk kasbon.');
    if(items.any((i)=>i.qty<=0))throw StateError('Jumlah item tidak valid.');
    final rows=await _client.rpc('irkop_cell_checkout',params:{
      'p_business_id':businessId,'p_outlet_id':outletId,'p_items':items.map((i)=>{'product_id':i.product.id,'qty':i.qty}).toList(),'p_payment_method':paymentMethod,'p_customer_id':customerId,
    });
    final data=rows is List?rows.first:rows;
    return TransactionSummary.fromMap(Map<String,dynamic>.from(data as Map));
  }
}