import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';
import 'transaction_repository.dart';

class Customer {
  const Customer({required this.id,required this.name,this.phone});
  final String id,name; final String? phone;
  factory Customer.fromMap(Map<String,dynamic> row)=>Customer(id:row['id'] as String,name:row['name'] as String,phone:row['phone'] as String?);
}
class CustomerRepository {
  final SupabaseClient _client=Supabase.instance.client;
  Future<List<Customer>> loadCustomers(String businessId) async {
    if(!Env.isSupabaseConfigured)return const [];
    final rows=await _client.from('irkop_cell_customers').select('id,name,phone').eq('business_id',businessId).order('name');
    return rows.map<Customer>((row)=>Customer.fromMap(row)).toList();
  }
  Future<Customer> createCustomer({required String businessId,required String name,String? phone}) async {
    if(name.trim().isEmpty)throw StateError('Nama pelanggan wajib diisi.');
    final normalized=phone?.trim();
    final row=await _client.from('irkop_cell_customers').insert({'business_id':businessId,'name':name.trim(),'phone':normalized==null||normalized.isEmpty?null:normalized}).select('id,name,phone').single();
    return Customer.fromMap(row);
  }
  Future<void> updateCustomer({required String id,required String businessId,required String name,String? phone}) {
    if(name.trim().isEmpty)throw StateError('Nama pelanggan wajib diisi.');
    final normalized=phone?.trim();
    return _client.from('irkop_cell_customers').update({'name':name.trim(),'phone':normalized==null||normalized.isEmpty?null:normalized}).eq('id',id).eq('business_id',businessId);
  }
  Future<void> deleteCustomer({required String id,required String businessId})=>_client.from('irkop_cell_customers').delete().eq('id',id).eq('business_id',businessId);
  Future<List<TransactionSummary>> history({required String businessId,required String customerId}) async {
    if(!Env.isSupabaseConfigured)return const [];
    final rows=await _client.from('irkop_cell_transactions').select('id,transaction_no,payment_method,status,total,transaction_at').eq('business_id',businessId).eq('customer_id',customerId).order('transaction_at',ascending:false);
    return rows.map<TransactionSummary>((r)=>TransactionSummary.fromMap(r)).toList();
  }
}