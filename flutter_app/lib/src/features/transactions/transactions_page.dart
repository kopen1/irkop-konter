import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/transaction_repository.dart';
import '../../shared/irkop_ui.dart';

class TransactionsPage extends StatefulWidget{const TransactionsPage({super.key,this.businessId});final String? businessId;@override State<TransactionsPage> createState()=>_TransactionsPageState();}
class _TransactionsPageState extends State<TransactionsPage>{
 final _repo=TransactionRepository();late Future<List<TransactionSummary>> _future;String _query='',_payment='Semua';
 @override void initState(){super.initState();_future=_load();}
 Future<List<TransactionSummary>> _load()=>widget.businessId==null?Future.value(const <TransactionSummary>[]):_repo.loadTransactions(widget.businessId!);
 Future<void> _refresh()async{setState(()=>_future=_load());await _future;}
 String _date(DateTime v)=>DateFormat('dd/MM/yyyy • HH:mm','id_ID').format(v.toLocal());
 Future<void> _detail(TransactionSummary t)async{final money=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);await showModalBottomSheet<void>(context:context,isScrollControlled:true,builder:(c)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(18,18,18,24),child:FutureBuilder<List<TransactionItemSummary>>(future:_repo.loadTransactionItems(t.id),builder:(c,s)=>Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
 Row(children:[Expanded(child:Text('Detail Transaksi',style:Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800))),IconButton(onPressed:()=>Navigator.pop(c),icon:const Icon(Icons.close))]),
 Text(t.transactionNo,style:const TextStyle(fontWeight:FontWeight.w700)),Text(_date(t.transactionAt)),Text('Pembayaran: '+t.paymentMethod.toUpperCase()),const Divider(height:24),
 if(s.connectionState!=ConnectionState.done)const Center(child:Padding(padding:EdgeInsets.all(24),child:CircularProgressIndicator()))
 else if(s.hasError)Text('Gagal memuat item: '+s.error.toString())
 else ...[...s.data!.map((i)=>ListTile(contentPadding:EdgeInsets.zero,title:Text(i.productName),subtitle:Text(i.qty.toStringAsFixed(0)+' × '+money.format(i.unitPrice)),trailing:Text(money.format(i.subtotal),style:const TextStyle(fontWeight:FontWeight.w700)))),const Divider(),Row(children:[const Expanded(child:Text('Total',style:TextStyle(fontWeight:FontWeight.w800,fontSize:18))),Text(money.format(t.total),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:18))])]
 ])))));}
 @override Widget build(BuildContext context){final money=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);return RefreshIndicator(onRefresh:_refresh,child:FutureBuilder<List<TransactionSummary>>(future:_future,builder:(context,s){var data=(s.data??const <TransactionSummary>[]).where((t)=>t.transactionNo.toLowerCase().contains(_query.toLowerCase())&&(_payment=='Semua'||t.paymentMethod==_payment)).toList();final methods={'Semua',...data.map((e)=>e.paymentMethod)}.toList();return Scaffold(body: ListView(padding:const EdgeInsets.all(16),children:[
 const IrkopSectionHeader(eyebrow:'Riwayat penjualan',title:'Transaksi',subtitle:'Cari, filter dan buka detail transaksi.',icon:Icons.receipt_long_outlined,action:'Tarik untuk refresh'),const SizedBox(height:14),
 TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari nomor transaksi',border:OutlineInputBorder()),onChanged:(v)=>setState(()=>_query=v)),const SizedBox(height:10),
 DropdownButtonFormField<String>(value:methods.contains(_payment)?_payment:'Semua',decoration:const InputDecoration(labelText:'Metode pembayaran',border:OutlineInputBorder()),items:methods.map((m)=>DropdownMenuItem(value:m,child:Text(m=='Semua'?m:m.toUpperCase()))).toList(),onChanged:(v)=>setState(()=>_payment=v??'Semua')),const SizedBox(height:10),
 Text(data.length.toString()+' transaksi',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
 if(s.connectionState!=ConnectionState.done)const Padding(padding:EdgeInsets.all(32),child:Center(child:CircularProgressIndicator())),
 if(s.hasError)Padding(padding:const EdgeInsets.all(20),child:Text('Gagal memuat: '+s.error.toString())),
 if(s.connectionState==ConnectionState.done&&!s.hasError&&data.isEmpty)const EmptyStateCard(icon:Icons.receipt_long_outlined,title:'Belum ada transaksi',subtitle:'Transaksi dari Kasir akan muncul di sini.'),
 ...data.map((t)=>Card(child:ListTile(onTap:()=>_detail(t),contentPadding:const EdgeInsets.all(14),leading:const CircleAvatar(child:Icon(Icons.receipt_long)),title:Text(t.transactionNo,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(t.paymentMethod.toUpperCase()+' • '+_date(t.transactionAt)),trailing:Text(money.format(t.total),style:const TextStyle(fontWeight:FontWeight.w800))))),
 ]));}