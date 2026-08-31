import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

class Expense {
  const Expense({required this.id,required this.category,required this.amount,required this.description,required this.expenseAt});
  final String id,category,description; final double amount; final DateTime expenseAt;
  factory Expense.fromMap(Map<String,dynamic> r)=>Expense(id:r['id'] as String,category:r['category'] as String,amount:(r['amount'] as num).toDouble(),description:(r['description'] ?? '') as String,expenseAt:DateTime.parse(r['expense_at'] as String));
}
class ExpenseRepository {
  final _client=Supabase.instance.client;
  Future<List<Expense>> load(String businessId,{int limit=300}) async {
    if(!Env.isSupabaseConfigured)return const [];
    final rows=await _client.from('irkop_cell_expenses').select().eq('business_id',businessId).order('expense_at',ascending:false).limit(limit);
    return rows.map<Expense>((r)=>Expense.fromMap(r)).toList();
  }
  Future<void> create({required String businessId,required String category,required double amount,required String description}) async {
    if(amount<=0)throw StateError('Nominal pengeluaran harus lebih dari 0.');
    await _client.from('irkop_cell_expenses').insert({'business_id':businessId,'category':category.trim(),'amount':amount,'description':description.trim()});
  }
  Future<void> update({required String id,required String businessId,required String category,required double amount,required String description}) async {
    if(amount<=0)throw StateError('Nominal pengeluaran harus lebih dari 0.');
    await _client.from('irkop_cell_expenses').update({'category':category.trim(),'amount':amount,'description':description.trim()}).eq('id',id).eq('business_id',businessId);
  }
  Future<void> delete({required String id,required String businessId}) async => _client.from('irkop_cell_expenses').delete().eq('id',id).eq('business_id',businessId);
}