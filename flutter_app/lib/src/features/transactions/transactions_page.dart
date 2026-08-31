import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/transaction_repository.dart';
import '../../shared/irkop_ui.dart';

class TransactionsPage extends StatefulWidget { const TransactionsPage({super.key,this.businessId}); final String? businessId; @override State<TransactionsPage> createState()=>_TransactionsPageState(); }
class _TransactionsPageState extends State<TransactionsPage> {
  String _query = '';
  final List<_TransactionRow> _rows = const [
    _TransactionRow('TRX-DEMO-001', 'CASH', 25000),
    _TransactionRow('TRX-DEMO-002', 'TRANSFER', 18000),
  ];
  @override
  Widget build(BuildContext context) {
    final money=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);
    final rows=_rows.where((r)=>r.no.toLowerCase().contains(_query.toLowerCase())).toList();
    return ListView(padding:const EdgeInsets.all(16),children:[
      const IrkopSectionHeader(eyebrow:'Riwayat penjualan',title:'Transaksi',subtitle:'Riwayat transaksi tersedia di sini.',icon:Icons.receipt_long_outlined,action:'Demo siap'),
      const SizedBox(height:14),
      TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari nomor transaksi',border:OutlineInputBorder()),onChanged:(v)=>setState(()=>_query=v)),
      const SizedBox(height:12),
      ...rows.map((r)=>Card(child:ListTile(
        leading:const CircleAvatar(child:Icon(Icons.receipt_long)),
        title:Text(r.no),
        subtitle:Text(r.method),
        trailing:Text(money.format(r.total),style:const TextStyle(fontWeight:FontWeight.w800)),
      ))),
    ]);
  }
}
class _TransactionRow {
  const _TransactionRow(this.no,this.method,this.total);
  final String no,method; final double total;
}
