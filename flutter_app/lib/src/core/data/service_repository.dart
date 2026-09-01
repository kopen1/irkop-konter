import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceOrder {
 const ServiceOrder({required this.id,required this.orderNo,required this.customerName,required this.customerPhone,required this.deviceName,required this.complaint,required this.status,required this.estimatedCost,required this.finalCost,required this.receivedAt,required this.notes});
 final String id,orderNo,customerName,customerPhone,deviceName,complaint,status,notes; final double estimatedCost; final double? finalCost; final DateTime receivedAt;
 factory ServiceOrder.fromMap(Map<String,dynamic> r)=>ServiceOrder(id:r['id'] as String,orderNo:r['order_no'] as String,customerName:r['customer_name'] as String,customerPhone:(r['customer_phone']??'') as String,deviceName:r['device_name'] as String,complaint:(r['complaint']??'') as String,status:r['status'] as String,estimatedCost:(r['estimated_cost'] as num).toDouble(),finalCost:r['final_cost']==null?null:(r['final_cost'] as num).toDouble(),receivedAt:DateTime.parse(r['received_at'] as String),notes:(r['notes']??'') as String);
}
class ServiceRepository {
 final _client=Supabase.instance.client;
 Future<List<ServiceOrder>> load(String businessId) async {final rows=await _client.from('irkop_cell_service_orders').select().eq('business_id',businessId).order('received_at',ascending:false);return rows.map<ServiceOrder>((r)=>ServiceOrder.fromMap(r)).toList();}
 Future<void> save({String? id,required String businessId,required String customerName,required String customerPhone,required String deviceName,required String complaint,required String status,required double estimatedCost,required double? finalCost,required String notes}) async {
  final data={'business_id':businessId,'customer_name':customerName.trim(),'customer_phone':customerPhone.trim(),'device_name':deviceName.trim(),'complaint':complaint.trim(),'status':status,'estimated_cost':estimatedCost,'final_cost':finalCost,'notes':notes.trim()};
  if(id==null){data['order_no']='SRV-'+DateTime.now().millisecondsSinceEpoch.toString();await _client.from('irkop_cell_service_orders').insert(data);}
  else await _client.from('irkop_cell_service_orders').update(data).eq('id',id).eq('business_id',businessId);
 }
 Future<void> delete({required String id,required String businessId})=>_client.from('irkop_cell_service_orders').delete().eq('id',id).eq('business_id',businessId);
}