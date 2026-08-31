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
  final _repo=TransactionRepository();
  late Future<List<TransactionSummary>> _future;
  String _query='';
  @override void initState(){super.initState();_future=_load();}
  Future<List<TransactionSummary>> _load()=>widget.businessId==null?Future.value(const <TransactionSummary>[]):_repo.loadTransactions(widget.businessId!);
  Future<void> _refresh()async{setState(()=>_future=_load());await _future;}
  String _date(DateTime value){final d=value.toLocal();return d.day.toString().padLeft(2,'0')+'/'+d.month.toString().padLeft(2,'0')+'/'+d.year.toString()+' • '+d.hour.toString().padLeft(2,'0')+':'+d.minute.toString().padLeft(2,'0');}

  Future<void> _showDetail(TransactionSummary transaction) async {
    final currency=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);
    await showModalBottomSheet<void>(
      context:context,
      builder:(context)=>SafeArea(
        child:Padding(
          padding:const EdgeInsets.fromLTRB(20,18,20,24),
          child:Column(
            mainAxisSize:MainAxisSize.min,
            crossAxisAlignment:CrossAxisAlignment.start,
            children:[
              Row(children:[
                Expanded(child:Text('Detail Transaksi',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800))),
                IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close)),
              ]),
              const SizedBox(height:8),
              Text(transaction.transactionNo,style:const TextStyle(fontWeight:FontWeight.w700)),
              const SizedBox(height:12),
              Text('Tanggal: '+_date(transaction.transactionAt)),
              Text('Pembayaran: '+transaction.paymentMethod.toUpperCase()),
              Text('Status: '+transaction.status),
              const Divider(height:28),
              Row(children:[
                const Expanded(child:Text('Total',style:TextStyle(fontWeight:FontWeight.w800,fontSize:18))),
                Text(currency.format(transaction.total),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:18)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override Widget build(BuildContext context){
    final currency=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);
    return RefreshIndicator(onRefresh:_refresh,child:FutureBuilder<List<TransactionSummary>>(future:_future,builder:(context,snapshot){
      final data=(snapshot.data??const <TransactionSummary>[]).where((t)=>t.transactionNo.toLowerCase().contains(_query.toLowerCase())).toList();
      return ListView(padding:const EdgeInsets.all(16),children:[
        const IrkopSectionHeader(eyebrow:'Riwayat penjualan',title:'Transaksi',subtitle:'Cari, buka detail, dan pantau seluruh transaksi outlet.',icon:Icons.receipt_long_outlined,action:'Tarik untuk refresh'),
        const SizedBox(height:18),
        TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari nomor transaksi',border:OutlineInputBorder()),onChanged:(v)=>setState(()=>_query=v)),
        const SizedBox(height:14),Text(data.length.toString()+' transaksi',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
        if(snapshot.connectionState!=ConnectionState.done)const Padding(padding:EdgeInsets.all(32),child:Center(child:CircularProgressIndicator())),
        if(snapshot.hasError)Padding(padding:const EdgeInsets.all(20),child:Text('Gagal memuat transaksi: '+snapshot.error.toString())),
        if(snapshot.connectionState==ConnectionState.done&&!snapshot.hasError&&data.isEmpty)const EmptyStateCard(icon:Icons.receipt_long_outlined,title:'Belum ada transaksi',subtitle:'Transaksi dari Kasir akan otomatis muncul di sini.'),
        ...data.map((t)=>Card(child:ListTile(onTap:()=>_showDetail(t),contentPadding:const EdgeInsets.all(14),leading:const CircleAvatar(child:Icon(Icons.receipt_long)),title:Text(t.transactionNo,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(t.paymentMethod.toUpperCase()+' • '+_date(t.transactionAt)),trailing:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.end,children:[Text(currency.format(t.total),style:const TextStyle(fontWeight:FontWeight.w800)),Text(t.status,style:Theme.of(context).textTheme.labelSmall)])))),
        const SizedBox(height:24),
      ]);
    }));
  }
}