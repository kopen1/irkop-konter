import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

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
    final row=await _client.from('irkop_cell_customers').insert({'business_id':businessId,'name':name.trim(),'phone':phone?.trim().isEmpty??true?null:phone!.trim()}).select('id,name,phone').single();
    return Customer.fromMap(row);
  }
  Future<void> updateCustomer({required String id,required String businessId,required String name,String? phone})=>_client.from('irkop_cell_customers').update({'name':name.trim(),'phone':phone?.trim().isEmpty??true?null:phone!.trim()}).eq('id',id).eq('business_id',businessId);
  Future<void> deleteCustomer({required String id,required String businessId})=>_client.from('irkop_cell_customers').delete().eq('id',id).eq('business_id',businessId);
}