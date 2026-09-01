import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/service_repository.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key,this.businessId});
  final String? businessId;
  @override State<ServicePage> createState()=>_ServicePageState();
}
class _ServicePageState extends State<ServicePage>{
  final _repo=ServiceRepository();
  late Future<List<ServiceOrder>> _future;
  @override void initState(){super.initState();_future=widget.businessId==null?Future.value(const []):_repo.load(widget.businessId!);}
  void _reload(){if(widget.businessId!=null)setState(()=>_future=_repo.load(widget.businessId!));}
  Future<void> _edit([ServiceOrder? order]) async {
    if(widget.businessId==null)return;
    final customer=TextEditingController(text:order?.customerName??'');
    final phone=TextEditingController(text:order?.customerPhone??'');
    final device=TextEditingController(text:order?.deviceName??'');
    final complaint=TextEditingController(text:order?.complaint??'');
    final estimate=TextEditingController(text:order?.estimatedCost.toStringAsFixed(0)??'0');
    final finalCost=TextEditingController(text:order?.finalCost?.toStringAsFixed(0)??'');
    final notes=TextEditingController(text:order?.notes??'');
    var status=order?.status??'received';
    final saved=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(builder:(c,setDialog)=>AlertDialog(
      title:Text(order==null?'Tiket Service Baru':'Edit '+order.orderNo),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:customer,decoration:const InputDecoration(labelText:'Nama pelanggan')),
        TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Nomor HP')),
        TextField(controller:device,decoration:const InputDecoration(labelText:'Perangkat')),
        TextField(controller:complaint,maxLines:2,decoration:const InputDecoration(labelText:'Keluhan')),
        DropdownButtonFormField<String>(initialValue:status,items:const [
          DropdownMenuItem(value:'received',child:Text('Masuk')),DropdownMenuItem(value:'process',child:Text('Proses')),DropdownMenuItem(value:'waiting_parts',child:Text('Menunggu sparepart')),DropdownMenuItem(value:'ready',child:Text('Selesai')),DropdownMenuItem(value:'completed',child:Text('Diambil')),DropdownMenuItem(value:'cancelled',child:Text('Batal')),
        ],onChanged:(v)=>setDialog(()=>status=v??status),decoration:const InputDecoration(labelText:'Status')),
        TextField(controller:estimate,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Estimasi biaya')),
        TextField(controller:finalCost,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Biaya akhir')),
        TextField(controller:notes,maxLines:2,decoration:const InputDecoration(labelText:'Catatan')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Simpan'))],
    )));
    if(saved!=true)return;
    try{await _repo.save(id:order?.id,businessId:widget.businessId!,customerName:customer.text,customerPhone:phone.text,deviceName:device.text,complaint:complaint.text,status:status,estimatedCost:double.tryParse(estimate.text.replaceAll(',','.'))??0,finalCost:finalCost.text.trim().isEmpty?null:double.tryParse(finalCost.text.replaceAll(',','.')),notes:notes.text);_reload();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gagal menyimpan: '+e.toString())));}
  }
  Future<void> _remove(ServiceOrder order) async{final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Hapus tiket?'),content:Text(order.orderNo),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Hapus'))]));if(ok==true){await _repo.delete(id:order.id,businessId:widget.businessId!);_reload();}}
  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Scaffold(
      floatingActionButton: widget.businessId == null ? null : FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Tiket'),
      ),
      body: FutureBuilder<List<ServiceOrder>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Gagal memuat service: ' + snapshot.error.toString()));
          final rows = snapshot.data ?? const <ServiceOrder>[];
          if (rows.isEmpty) return const Center(child: Text('Belum ada tiket service.'));
          return RefreshIndicator(
            onRefresh: () async { _reload(); await _future; },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final order = rows[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.phone_android_outlined),
                    title: Text(order.customerName + ' • ' + order.deviceName),
                    subtitle: Text(order.orderNo + '\n' + order.status + ' • Est. ' + money.format(order.estimatedCost)),
                    isThreeLine: true,
                    onTap: () => _edit(order),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _remove(order),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
