import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/data/business_context_repository.dart';
import '../../core/data/transaction_repository.dart';
import '../cashier/cashier_page.dart';
import '../reports/reports_page.dart';
import '../transactions/transactions_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key,required this.demoMode,this.businessContext});
  final bool demoMode; final BusinessContext? businessContext;
  @override State<HomePage> createState()=>_HomePageState();
}
class _HomePageState extends State<HomePage>{
  int index=0;
  @override Widget build(BuildContext context){
    final ctx=widget.businessContext;
    final pages=ctx==null?[_Dashboard(demoMode:true,businessId:null),const TransactionsPage(),const CashierPage(),const ReportsPage()]:[
      _Dashboard(demoMode:false,businessId:ctx.businessId),
      TransactionsPage(businessId:ctx.businessId),
      CashierPage(businessId:ctx.businessId,outletId:ctx.outletId),
      ReportsPage(businessId:ctx.businessId),
    ];
    const titles=['Dashboard','Transaksi','Kasir','Laporan'];
    return Scaffold(appBar:AppBar(title:Text(ctx==null?titles[index]:'${titles[index]} • ${ctx.outletName}'),actions:[
      if(widget.demoMode) const Padding(padding:EdgeInsets.only(right:8),child:Center(child:Chip(label:Text('MODE DEMO')))),
      if(!widget.demoMode) IconButton(tooltip:'Logout',onPressed:()=>AuthRepository().signOut(),icon:const Icon(Icons.logout)),
    ]),body:IndexedStack(index:index,children:pages),bottomNavigationBar:NavigationBar(selectedIndex:index,onDestinationSelected:(v)=>setState(()=>index=v),destinations:const[
      NavigationDestination(icon:Icon(Icons.dashboard_outlined),selectedIcon:Icon(Icons.dashboard),label:'Dashboard'),
      NavigationDestination(icon:Icon(Icons.receipt_long_outlined),selectedIcon:Icon(Icons.receipt_long),label:'Transaksi'),
      NavigationDestination(icon:Icon(Icons.point_of_sale_outlined),selectedIcon:Icon(Icons.point_of_sale),label:'Kasir'),
      NavigationDestination(icon:Icon(Icons.bar_chart_outlined),selectedIcon:Icon(Icons.bar_chart),label:'Laporan'),
    ]));
  }
}
class _Dashboard extends StatefulWidget{const _Dashboard({required this.demoMode,required this.businessId});final bool demoMode;final String? businessId;@override State<_Dashboard> createState()=>_DashboardState();}
class _DashboardState extends State<_Dashboard>{
 final _repo=TransactionRepository(); late Future<DashboardMetrics> _future;
 @override void initState(){super.initState();_future=_load();}
 Future<DashboardMetrics> _load()=>widget.businessId==null?Future.value(const DashboardMetrics(todayRevenue:0,todayTransactions:0,recentTransactions:[])):_repo.loadDashboard(widget.businessId!);
 Future<void> _refresh()async{setState(()=>_future=_load());await _future;}
 @override Widget build(BuildContext context){final c=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);
 return RefreshIndicator(onRefresh:_refresh,child:FutureBuilder<DashboardMetrics>(future:_future,builder:(context,s){
 final m=s.data??const DashboardMetrics(todayRevenue:0,todayTransactions:0,recentTransactions:[]);
 return ListView(padding:const EdgeInsets.all(16),children:[
 const Text('IRKOP Konter',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:4),
 Text(widget.demoMode?'Mode demo':'Data operasional outlet'),const SizedBox(height:16),
 if(s.connectionState!=ConnectionState.done)const LinearProgressIndicator(),const SizedBox(height:12),
 GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:1.28,children:[
 _MetricCard(icon:Icons.payments_outlined,label:'Omzet Hari Ini',value:c.format(m.todayRevenue)),
 _MetricCard(icon:Icons.receipt_long_outlined,label:'Transaksi',value:m.todayTransactions.toString()),
 const _MetricCard(icon:Icons.credit_score_outlined,label:'Kasbon Aktif',value:'-'),
 const _MetricCard(icon:Icons.account_balance_wallet_outlined,label:'Saldo Kas',value:'-')]),
 const SizedBox(height:20),const Text('Transaksi Terbaru',style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
 if(s.hasError)Padding(padding:const EdgeInsets.only(top:16),child:Text('Gagal memuat data: ${s.error}')),
 if(!s.hasError&&m.recentTransactions.isEmpty)const Padding(padding:EdgeInsets.only(top:16),child:Text('Belum ada transaksi')),
 ...m.recentTransactions.map((t)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.receipt)),title:Text(t.transactionNo),subtitle:Text('${t.paymentMethod} • ${t.status}'),trailing:Text(c.format(t.total))))),
 ]);}));}}
class _MetricCard extends StatelessWidget{const _MetricCard({required this.icon,required this.label,required this.value});final IconData icon;final String label,value;@override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon),const Spacer(),Text(label),Text(value,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold))])));}
