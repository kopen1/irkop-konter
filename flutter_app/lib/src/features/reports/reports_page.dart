import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/transaction_repository.dart';
import '../../shared/irkop_ui.dart';

class ReportsPage extends StatefulWidget{const ReportsPage({super.key,this.businessId});final String? businessId;@override State<ReportsPage> createState()=>_ReportsPageState();}
class _ReportsPageState extends State<ReportsPage>{final _repo=TransactionRepository();late Future<DashboardMetrics> _future;@override void initState(){super.initState();_future=widget.businessId==null?Future.value(const DashboardMetrics(todayRevenue:0,todayTransactions:0,recentTransactions:[])):_repo.loadDashboard(widget.businessId!);}@override Widget build(BuildContext context){final c=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);return FutureBuilder<DashboardMetrics>(future:_future,builder:(context,s){final m=s.data??const DashboardMetrics(todayRevenue:0,todayTransactions:0,recentTransactions:[]);return ListView(padding:const EdgeInsets.all(16),children:[
 const IrkopSectionHeader(eyebrow:'Analitik bisnis',title:'Laporan',subtitle:'Ringkasan performa bisnis berdasarkan transaksi aktual.',icon:Icons.bar_chart_outlined,action:'Data real-time'),
 const SizedBox(height:18),
 Row(children:[Expanded(child:_ReportMetric(icon:Icons.payments_outlined,label:'Omzet Hari Ini',value:c.format(m.todayRevenue))),const SizedBox(width:12),Expanded(child:_ReportMetric(icon:Icons.receipt_long_outlined,label:'Transaksi',value:m.todayTransactions.toString()))]),
 const SizedBox(height:20),Text('Laporan Lainnya',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:8),
 const Card(child:ListTile(leading:CircleAvatar(child:Icon(Icons.calendar_month)),title:Text('Laporan Bulanan'),subtitle:Text('Rekap omzet dan transaksi per periode'),trailing:Icon(Icons.chevron_right))),
 const Card(child:ListTile(leading:CircleAvatar(child:Icon(Icons.inventory_2_outlined)),title:Text('Stok Produk'),subtitle:Text('Pantau ketersediaan dan produk stok rendah'),trailing:Icon(Icons.chevron_right))),
 const Card(child:ListTile(leading:CircleAvatar(child:Icon(Icons.account_balance_wallet_outlined)),title:Text('Arus Kas'),subtitle:Text('Ringkasan pemasukan dan mutasi kas'),trailing:Icon(Icons.chevron_right))),
 ]);});}}
class _ReportMetric extends StatelessWidget{const _ReportMetric({required this.icon,required this.label,required this.value});final IconData icon;final String label,value;@override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon),const SizedBox(height:18),Text(label),const SizedBox(height:4),Text(value,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:17))])));}
