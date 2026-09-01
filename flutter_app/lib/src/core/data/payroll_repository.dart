import 'package:supabase_flutter/supabase_flutter.dart';

class PayrollRecord {
  const PayrollRecord({required this.id,required this.employeeName,required this.period,required this.baseAmount,required this.bonusAmount,required this.deductionAmount,required this.paidAt,required this.notes});
  final String id,employeeName,notes; final DateTime period; final double baseAmount,bonusAmount,deductionAmount; final DateTime? paidAt;
  double get netAmount=>baseAmount+bonusAmount-deductionAmount;
  factory PayrollRecord.fromMap(Map<String,dynamic> r)=>PayrollRecord(id:r['id'] as String,employeeName:r['employee_name'] as String,period:DateTime.parse(r['period'] as String),baseAmount:(r['base_amount'] as num).toDouble(),bonusAmount:(r['bonus_amount'] as num).toDouble(),deductionAmount:(r['deduction_amount'] as num).toDouble(),paidAt:r['paid_at']==null?null:DateTime.parse(r['paid_at'] as String),notes:(r['notes']??'') as String);
}
class PayrollRepository {
 final _client=Supabase.instance.client;
 Future<List<PayrollRecord>> load(String businessId) async {final rows=await _client.from('irkop_cell_payroll_records').select().eq('business_id',businessId).order('period',ascending:false);return rows.map<PayrollRecord>((r)=>PayrollRecord.fromMap(r)).toList();}
 Future<void> save({String? id,required String businessId,required String employeeName,required DateTime period,required double baseAmount,required double bonusAmount,required double deductionAmount,required String notes}) async {
  final data={'business_id':businessId,'employee_name':employeeName.trim(),'period':period.toIso8601String().substring(0,7)+'-01','base_amount':baseAmount,'bonus_amount':bonusAmount,'deduction_amount':deductionAmount,'notes':notes.trim()};
  if(id==null) await _client.from('irkop_cell_payroll_records').insert(data); else await _client.from('irkop_cell_payroll_records').update(data).eq('id',id).eq('business_id',businessId);
 }
 Future<void> markPaid({required String id,required String businessId,bool paid=true})=>_client.from('irkop_cell_payroll_records').update({'paid_at':paid?DateTime.now().toUtc().toIso8601String():null}).eq('id',id).eq('business_id',businessId);
 Future<void> delete({required String id,required String businessId})=>_client.from('irkop_cell_payroll_records').delete().eq('id',id).eq('business_id',businessId);
}