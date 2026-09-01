import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/payroll_repository.dart';

class PayrollPage extends StatefulWidget {
  const PayrollPage({super.key,this.businessId});
  final String? businessId;
  @override State<PayrollPage> createState()=>_PayrollPageState();
}
class _PayrollPageState extends State<PayrollPage>{
  final _repo=PayrollRepository();late Future<List<PayrollRecord>> _future;
  @override void initState(){super.initState();_future=widget.businessId==null?Future.value(const []):_repo.load(widget.businessId!);}
  void _reload(){if(widget.businessId!=null)setState(()=>_future=_repo.load(widget.businessId!));}
  Future<void> _edit([PayrollRecord? row]) async{
    if(widget.businessId==null)return;final name=TextEditingController(text:row?.employeeName??'');final base=TextEditingController(text:row?.baseAmount.toStringAsFixed(0)??'0');final bonus=TextEditingController(text:row?.bonusAmount.toStringAsFixed(0)??'0');final deduction=TextEditingController(text:row?.deductionAmount.toStringAsFixed(0)??'0');final notes=TextEditingController(text:row?.notes??'');var period=row?.period??DateTime.now();
    final ok=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(builder:(c,setDialog)=>AlertDialog(title:Text(row==null?'Tambah gaji':'Edit gaji'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:name,decoration:const InputDecoration(labelText:'Nama karyawan')),ListTile(contentPadding:EdgeInsets.zero,title:Text('Periode '+DateFormat('MMMM yyyy','id_ID').format(period)),trailing:const Icon(Icons.calendar_month),onTap:()async{final d=await showDatePicker(context:c,initialDate:period,firstDate:DateTime(2020),lastDate:DateTime(2100));if(d!=null)setDialog(()=>period=d);}),TextField(controller:base,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Gaji pokok')),TextField(controller:bonus,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Bonus')),TextField(controller:deduction,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Potongan')),TextField(controller:notes,maxLines:2,decoration:const InputDecoration(labelText:'Catatan')),
    ])),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Simpan'))])));
    if(ok!=true)return;try{await _repo.save(id:row?.id,businessId:widget.businessId!,employeeName:name.text,period:period,baseAmount:double.tryParse(base.text.replaceAll(',','.'))??0,bonusAmount:double.tryParse(bonus.text.replaceAll(',','.'))??0,deductionAmount:double.tryParse(deduction.text.replaceAll(',','.'))??0,notes:notes.text);_reload();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gagal menyimpan: '+e.toString())));}
  }
  @override Widget build(BuildContext context){final money=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);return Scaffold(floatingActionButton:widget.businessId==null?null:FloatingActionButton.extended(onPressed:()=>_edit(),icon:const Icon(Icons.add),label:const Text('Gaji')),body:FutureBuilder<List<PayrollRecord>>(future:_future,builder:(c,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());if(s.hasError)return Center(child:Text('Gagal memuat gaji: '+s.error.toString()));final rows=s.data??const <PayrollRecord>[];if(rows.isEmpty)return const Center(child:Text('Belum ada data gaji.'));return RefreshIndicator(onRefresh:()async{_reload();await _future;},child:ListView.builder(padding:const EdgeInsets.all(12),itemCount:rows.length,itemBuilder:(c,i){final r=rows[i];return Card(child:ListTile(title:Text(r.employeeName),subtitle:Text(DateFormat('MMMM yyyy','id_ID').format(r.period)+' • '+(r.paidAt==null?'Belum dibayar':'Sudah dibayar')),trailing:Text(money.format(r.netAmount)),onTap:()=>_edit(r),onLongPress:()async{await _repo.markPaid(id:r.id,businessId:widget.businessId!,paid:r.paidAt==null);_reload();}));}));}));}
}