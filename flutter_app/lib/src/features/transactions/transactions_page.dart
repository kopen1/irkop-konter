import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/transaction_repository.dart';
import '../../shared/irkop_ui.dart';
import '../../core/data/demo_store.dart';
class TransactionsPage extends StatefulWidget { const TransactionsPage({super.key,this.businessId}); final String? businessId; @override State<TransactionsPage> createState()=>_TransactionsPageState(); }
class _TransactionsPageState extends State<TransactionsPage> { final _repo=TransactionRepository(); late Future<List<TransactionSummary>> _future; String _query='';
List<TransactionSummary> _demoTransactions()=>[
  TransactionSummary(id:'demo-1',transactionNo:'TRX-DEMO-001',paymentMethod:'cash',status:'completed',total:DemoStore.products[0].price,transactionAt:DateTime.now().subtract(const Duration(minutes:12))),
  TransactionSummary(id:'demo-2',transactionNo:'TRX-DEMO-002',paymentMethod:'transfer',status:'completed',total:DemoStore.products[2].price,transactionAt:DateTime.now().subtract(const Duration(hours:2))),
];
Future<List<TransactionSummary>> _load()=>Future.value(_demoTransactions());
@override void initState(){super.initState();_future=_load();}
String _date(DateTime v)=>DateFormat('dd/MM/yyyy HH:mm','id_ID').format(v.toLocal());
Future<void> _refresh()async{setState(()=>_future=_load());await _future;}
@override Widget build(BuildContext context){final money=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);return RefreshIndicator(onRefresh:_refresh,child:FutureBuilder<List<TransactionSummary>>(future:_future,builder:(context,s){final data=(s.data??const <TransactionSummary>[]).where((t)=>t.transactionNo.toLowerCase().contains(_query.toLowerCase())).toList();return ListView(padding:const EdgeInsets.all(16),children:[const IrkopSectionHeader(eyebrow:'Riwayat penjualan',title:'Transaksi',subtitle:'Riwayat transaksi tersedia di sini.',icon:Icons.receipt_long_outlined,action:'Demo siap'),const SizedBox(height:14),TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari nomor transaksi',border:OutlineInputBorder()),onChanged:(v)=>setState(()=>_query=v)),const SizedBox(height:12),if(s.connectionState!=ConnectionState.done)const Center(child:Padding(padding:EdgeInsets.all(32),child:CircularProgressIndicator())),if(s.hasError)Text('Gagal memuat: '+s.error.toString()),if(s.connectionState==ConnectionState.done&&!s.hasError&&data.isEmpty)const EmptyStateCard(icon:Icons.receipt_long_outlined,title:'Belum ada transaksi',subtitle:'Transaksi dari Kasir akan muncul di sini.'),...data.map((t)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.receipt_long)),title:Text(t.transactionNo),subtitle:Text(t.paymentMethod.toUpperCase()+' • '+_date(t.transactionAt)),trailing:Text(money.format(t.total),style:const TextStyle(fontWeight:FontWeight.w800)))))]);}));}}