import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/business_context_repository.dart';
import '../../core/data/transaction_repository.dart';
import '../cashier/cashier_page.dart';
import '../transactions/transactions_page.dart';
import '../products/products_page.dart';
import '../customers/customers_page.dart';
import '../reports/reports_page.dart';
import '../settings/settings_page.dart';
import '../more/more_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key,required this.demoMode,this.businessContext});
  final bool demoMode;final BusinessContext? businessContext;
  @override State<HomePage> createState()=>_HomePageState();
}
class _HomePageState extends State<HomePage>{
 int index=0;
 void _open(int value)=>setState(()=>index=value);
 @override Widget build(BuildContext context){
  final ctx=widget.businessContext;
  final pages=[
   _Dashboard(demoMode:widget.demoMode,businessId:ctx?.businessId),
   CashierPage(businessId:ctx?.businessId,outletId:ctx?.outletId),
   TransactionsPage(businessId:ctx?.businessId),
   ProductsPage(businessId:ctx?.businessId),
   CustomersPage(businessId:ctx?.businessId),
   ReportsPage(businessId:ctx?.businessId),
   SettingsPage(businessContext:ctx),
  ];
  final compactIndex=index<=2?index:3;
  final body=index==7?MorePage(onOpen:_open):pages[index];
  return Scaffold(
   appBar:AppBar(title:Text(index==0?'IRKOP CELL':ctx==null?'MODE DEMO':ctx.outletName),centerTitle:false),
   body:body,
   bottomNavigationBar:NavigationBar(selectedIndex:compactIndex,onDestinationSelected:(value){if(value==3){setState(()=>index=7);}else{setState(()=>index=value);}},destinations:const[
    NavigationDestination(icon:Icon(Icons.grid_view_outlined),selectedIcon:Icon(Icons.grid_view),label:'Beranda'),
    NavigationDestination(icon:Icon(Icons.point_of_sale_outlined),selectedIcon:Icon(Icons.point_of_sale),label:'Kasir'),
    NavigationDestination(icon:Icon(Icons.receipt_long_outlined),selectedIcon:Icon(Icons.receipt_long),label:'Transaksi'),
    NavigationDestination(icon:Icon(Icons.apps_outlined),selectedIcon:Icon(Icons.apps),label:'Lainnya'),
   ]),
  );
 }
}
class _Dashboard extends StatefulWidget{const _Dashboard({required this.demoMode,required this.businessId});final bool demoMode;final String? businessId;@override State<_Dashboard> createState()=>_DashboardState();}
class _DashboardState extends State<_Dashboard>{
 final _repo=TransactionRepository();late Future<DashboardMetrics> _future;
 @override void initState(){super.initState();_future=_load();}
 Future<DashboardMetrics> _load()=>widget.businessId==null?Future.value(const DashboardMetrics(todayRevenue:0,todayTransactions:0,recentTransactions:[])):_repo.loadDashboard(widget.businessId!);
 Future<void> _refresh()async{setState(()=>_future=_load());await _future;}
 @override Widget build(BuildContext context){final c=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);return RefreshIndicator(onRefresh:_refresh,child:FutureBuilder<DashboardMetrics>(future:_future,builder:(context,s){final m=s.data??const DashboardMetrics(todayRevenue:0,todayTransactions:0,recentTransactions:[]);return ListView(padding:const EdgeInsets.all(16),children:[
 Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(borderRadius:BorderRadius.circular(26),color:Theme.of(context).colorScheme.primary),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(widget.demoMode?'SELAMAT DATANG':'OUTLET AKTIF',style:TextStyle(color:Theme.of(context).colorScheme.onPrimary.withOpacity(.72),fontWeight:FontWeight.bold)),const SizedBox(height:8),Text(widget.demoMode?'IRKOP Konter Demo':'Bisnis Anda siap beroperasi',style:Theme.of(context).textTheme.headlineSmall?.copyWith(color:Theme.of(context).colorScheme.onPrimary,fontWeight:FontWeight.w800)),const SizedBox(height:8),Text('Pantau penjualan, transaksi dan aktivitas bisnis dari satu tempat.',style:TextStyle(color:Theme.of(context).colorScheme.onPrimary.withOpacity(.8)))]),
 const SizedBox(height:18),if(s.connectionState!=ConnectionState.done)const LinearProgressIndicator(),const SizedBox(height:12),
 GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:1.18,children:[
 _MetricCard(icon:Icons.payments_outlined,label:'Omzet Hari Ini',value:c.format(m.todayRevenue)),
 _MetricCard(icon:Icons.receipt_long_outlined,label:'Transaksi',value:m.todayTransactions.toString()),
 const _MetricCard(icon:Icons.credit_score_outlined,label:'Kasbon Aktif',value:'0'),
 const _MetricCard(icon:Icons.account_balance_wallet_outlined,label:'Saldo Kas',value:'Terkoneksi'),
 ]),
 const SizedBox(height:24),Text('Aktivitas Terbaru',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:8),
 if(s.hasError)Text('Gagal memuat data: ${s.error}'),
 if(!s.hasError&&m.recentTransactions.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('Belum ada transaksi hari ini. Mulai transaksi dari menu Kasir.'))),
 ...m.recentTransactions.map((t)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.receipt)),title:Text(t.transactionNo),subtitle:Text('${t.paymentMethod} • ${t.status}'),trailing:Text(c.format(t.total),style:const TextStyle(fontWeight:FontWeight.bold))))),
 ]);}));}}
class _MetricCard extends StatelessWidget{const _MetricCard({required this.icon,required this.label,required this.value});final IconData icon;final String label,value;@override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[CircleAvatar(radius:18,child:Icon(icon,size:19)),const Spacer(),Text(label,style:Theme.of(context).textTheme.labelLarge),const SizedBox(height:4),Text(value,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800))])));}
