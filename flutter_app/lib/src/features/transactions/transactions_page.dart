import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/transaction_repository.dart';
import '../../shared/irkop_ui.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key,this.businessId});
  final String? businessId;
  @override State<TransactionsPage> createState()=>_TransactionsPageState();
}
class _TransactionsPageState extends State<TransactionsPage>{
  final _repo=TransactionRepository();late Future<List<TransactionSummary>> _future;String _query='';
  @override void initState(){super.initState();_future=_load();}
  Future<List<TransactionSummary>> _load()=>widget.businessId==null?Future.value(const[]):_repo.loadTransactions(widget.businessId!);
  Future<void> _refresh()async{setState(()=>_future=_load());await _future;}
  @override Widget build(BuildContext context){final c=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);return RefreshIndicator(onRefresh:_refresh,child:FutureBuilder<List<TransactionSummary>>(future:_future,builder:(context,s){final data=(s.data??const<TransactionSummary>[]).where((t)=>t.transactionNo.toLowerCase().contains(_query.toLowerCase())).toList();return ListView(padding:const EdgeInsets.all(16),children:[
    const IrkopSectionHeader(eyebrow:'Riwayat penjualan',title:'Transaksi',subtitle:'Cari dan pantau seluruh transaksi outlet.',icon:Icons.receipt_long_outlined,action:'Tarik untuk refresh'),
    const SizedBox(height:18),
    TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari nomor transaksi',border:OutlineInputBorder()),onChanged:(v)=>setState(()=>_query=v)),
    const SizedBox(height:14),Text('${data.length} transaksi',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
    if(s.connectionState!=ConnectionState.done)const Padding(padding:EdgeInsets.all(32),child:Center(child:CircularProgressIndicator())),
    if(s.hasError)Padding(padding:const EdgeInsets.all(20),child:Text('Gagal memuat transaksi: ${s.error}')),
    if(s.connectionState==ConnectionState.done&&!s.hasError&&data.isEmpty)const EmptyStateCard(icon:Icons.receipt_long_outlined,title:'Belum ada transaksi',subtitle:'Transaksi dari Kasir akan otomatis muncul di sini.'),
    ...data.map((t)=>Card(child:ListTile(contentPadding:const EdgeInsets.all(14),leading:const CircleAvatar(child:Icon(Icons.receipt_long)),title:Text(t.transactionNo,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('${t.paymentMethod.toUpperCase()} • ${DateFormat('dd MMM • HH:mm','id_ID').format(t.transactionAt.toLocal())}'),trailing:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.end,children:[Text(c.format(t.total),style:const TextStyle(fontWeight:FontWeight.w800)),Text(t.status,style:Theme.of(context).textTheme.labelSmall)])))),
  ]);}));}
}
