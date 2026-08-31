import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/transaction_repository.dart';
import '../../shared/irkop_ui.dart';

class ReportsPage extends StatefulWidget{const ReportsPage({super.key,this.businessId});final String? businessId;@override State<ReportsPage> createState()=>_ReportsPageState();}
class _ReportsPageState extends State<ReportsPage>{
 final _repo=TransactionRepository();late Future<List<TransactionSummary>> _future;int _days=7;
 @override void initState(){super.initState();_future=_load();}
 Future<List<TransactionSummary>> _load()=>widget.businessId==null?Future.value(const[]):_repo.loadTransactions(widget.businessId!,limit:500);
 @override Widget build(BuildContext context){final money=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);return FutureBuilder<List<TransactionSummary>>(future:_future,builder:(context,s){final now=DateTime.now(),start=DateTime(now.year,now.month,now.day).subtract(Duration(days:_days-1));final all=(s.data??const <TransactionSummary>[]).where((t)=>t.status=='completed'&&!t.transactionAt.toLocal().isBefore(start)).toList();final revenue=all.fold<double>(0,(x,t)=>x+t.total);final payments=<String,double>{};for(final t in all){payments[t.paymentMethod]=(payments[t.paymentMethod]??0)+t.total;}return ListView(padding:const EdgeInsets.all(16),children:[
 const IrkopSectionHeader(eyebrow:'Analitik bisnis',title:'Laporan',subtitle:'Ringkasan transaksi berdasarkan periode yang dipilih.',icon:Icons.bar_chart_outlined,action:'Data aktual'),const SizedBox(height:14),
 SegmentedButton<int>(segments:const[ButtonSegment(value:7,label:Text('7 Hari')),ButtonSegment(value:30,label:Text('30 Hari')),ButtonSegment(value:90,label:Text('90 Hari'))],selected:{_days},onSelectionChanged:(v)=>setState(()=>_days=v.first)),const SizedBox(height:16),
 Row(children:[Expanded(child:_Metric(label:'Omzet',value:money.format(revenue),icon:Icons.payments_outlined)),const SizedBox(width:10),Expanded(child:_Metric(label:'Transaksi',value:all.length.toString(),icon:Icons.receipt_long_outlined))]),const SizedBox(height:20),
 Text('Metode Pembayaran',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),
 if(s.connectionState!=ConnectionState.done)const Padding(padding:EdgeInsets.all(30),child:Center(child:CircularProgressIndicator())),
 if(s.hasError)Text('Gagal memuat laporan: '+s.error.toString()),
 if(!s.hasError&&payments.isEmpty)const EmptyStateCard(icon:Icons.bar_chart_outlined,title:'Belum ada data periode ini',subtitle:'Transaksi akan muncul setelah ada penjualan.'),
 ...payments.entries.map((e)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.account_balance_wallet_outlined)),title:Text(e.key.toUpperCase()),trailing:Text(money.format(e.value),style:const TextStyle(fontWeight:FontWeight.w800))))),
 ]);});}
}
class _Metric extends StatelessWidget{const _Metric({required this.label,required this.value,required this.icon});final String label,value;final IconData icon;@override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon),const SizedBox(height:14),Text(label),const SizedBox(height:4),Text(value,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16))])));}
