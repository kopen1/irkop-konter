import 'package:flutter/material.dart';
import '../../core/data/customer_repository.dart';
import '../../shared/irkop_ui.dart';

class CustomersPage extends StatefulWidget{const CustomersPage({super.key,this.businessId});final String? businessId;@override State<CustomersPage> createState()=>_CustomersPageState();}
class _CustomersPageState extends State<CustomersPage>{
 final _repo=CustomerRepository();late Future<List<Customer>> _future;String _query='';
 @override void initState(){super.initState();_future=_load();}
 Future<List<Customer>> _load()=>widget.businessId==null?Future.value(const <Customer>[]):_repo.loadCustomers(widget.businessId!);
 Future<void> _refresh()async{setState(()=>_future=_load());await _future;}
 Future<void> _edit([Customer? customer])async{
  if(widget.businessId==null)return;
  final name=TextEditingController(text:customer?.name??''),phone=TextEditingController(text:customer?.phone??'');
  final saved=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,builder:(c)=>Padding(padding:EdgeInsets.fromLTRB(16,16,16,MediaQuery.of(c).viewInsets.bottom+16),child:Column(mainAxisSize:MainAxisSize.min,children:[
   Text(customer==null?'Pelanggan Baru':'Edit Pelanggan',style:Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:14),
   TextField(controller:name,decoration:const InputDecoration(labelText:'Nama pelanggan',border:OutlineInputBorder())),const SizedBox(height:10),
   TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Nomor telepon',border:OutlineInputBorder())),const SizedBox(height:14),
   SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Simpan')))
  ])));
  if(saved==true&&name.text.trim().isNotEmpty){try{if(customer==null){await _repo.createCustomer(businessId:widget.businessId!,name:name.text,phone:phone.text);}else{await _repo.updateCustomer(id:customer.id,businessId:widget.businessId!,name:name.text,phone:phone.text);}await _refresh();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gagal menyimpan: '+e.toString())));}}
  name.dispose();phone.dispose();
 }
 Future<void> _delete(Customer c)async{if(widget.businessId==null)return;final ok=await showDialog<bool>(context:context,builder:(x)=>AlertDialog(title:const Text('Hapus pelanggan?'),content:Text(c.name),actions:[TextButton(onPressed:()=>Navigator.pop(x),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(x,true),child:const Text('Hapus'))]));if(ok==true){try{await _repo.deleteCustomer(id:c.id,businessId:widget.businessId!);await _refresh();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gagal menghapus: '+e.toString())));}}}
 @override Widget build(BuildContext context)=>RefreshIndicator(onRefresh:_refresh,child:FutureBuilder<List<Customer>>(future:_future,builder:(context,s){final data=(s.data??const <Customer>[]).where((c)=>c.name.toLowerCase().contains(_query.toLowerCase())||(c.phone??'').contains(_query)).toList();return Scaffold(body: ListView(padding:const EdgeInsets.all(16),children:[
 const IrkopSectionHeader(eyebrow:'Pelanggan',title:'Data Pelanggan',subtitle:'Tambah, cari, edit dan kelola pelanggan.',icon:Icons.people_outline,action:'Database pelanggan'),const SizedBox(height:14),
 FilledButton.icon(onPressed:widget.businessId==null?null:()=>_edit(),icon:const Icon(Icons.person_add_alt_1_outlined),label:const Text('Tambah Pelanggan')),const SizedBox(height:12),
 TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari pelanggan atau nomor',border:OutlineInputBorder()),onChanged:(v)=>setState(()=>_query=v)),const SizedBox(height:10),Text(data.length.toString()+' pelanggan',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
 if(s.connectionState!=ConnectionState.done)const Padding(padding:EdgeInsets.all(32),child:Center(child:CircularProgressIndicator())),
 if(s.hasError)EmptyStateCard(icon:Icons.error_outline,title:'Gagal memuat pelanggan',subtitle:s.error.toString()),
 if(s.connectionState==ConnectionState.done&&!s.hasError&&data.isEmpty)const EmptyStateCard(icon:Icons.people_outline,title:'Belum ada pelanggan',subtitle:'Tambahkan pelanggan baru.'),
 ...data.map((c)=>Card(child:ListTile(onTap:()=>_edit(c),leading:CircleAvatar(child:Text(c.name.isEmpty?'P':c.name.substring(0,1).toUpperCase())),title:Text(c.name,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(c.phone?.isEmpty??true?'Tanpa nomor telepon':c.phone!),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()=>_delete(c)))),
 ]));}