import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/product_repository.dart';
import '../../core/data/transaction_repository.dart';
import '../../core/models/business_models.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key,this.businessId,this.outletId});
  final String? businessId,outletId;
  @override State<CashierPage> createState()=>_CashierPageState();
}
class _CashierPageState extends State<CashierPage>{
 final _products=ProductRepository();final _transactions=TransactionRepository();final cart=<CartItem>[];late Future<List<Product>> _future;String query='';
 @override void initState(){super.initState();_future=widget.businessId==null?Future.value(const<Product>[]):_products.loadProducts(widget.businessId!);}
 @override Widget build(BuildContext context){final total=cart.fold<double>(0,(s,i)=>s+i.subtotal);final currency=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);return Column(children:[
  Container(width:double.infinity,padding:const EdgeInsets.fromLTRB(16,14,16,18),child:Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),color:Theme.of(context).colorScheme.secondaryContainer),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('KASIR CEPAT',style:Theme.of(context).textTheme.labelLarge),const SizedBox(height:5),Text('Mulai Penjualan',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:4),Text('${cart.length} item di keranjang • ${currency.format(total)}')]))),
  Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari produk untuk dijual',border:OutlineInputBorder()),onChanged:(v)=>setState(()=>query=v))),
  const SizedBox(height:8),
  Expanded(child:FutureBuilder<List<Product>>(future:_future,builder:(context,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());if(s.hasError)return Center(child:Text('Gagal memuat produk: ${s.error}'));final products=(s.data??const<Product>[]).where((p)=>p.name.toLowerCase().contains(query.toLowerCase())).toList();if(products.isEmpty)return const Center(child:Text('Belum ada produk. Tambahkan produk di database.'));return ListView.separated(padding:const EdgeInsets.fromLTRB(16,8,16,16),itemCount:products.length,separatorBuilder:(_,__)=>const SizedBox(height:6),itemBuilder:(context,i){final p=products[i];return Card(child:ListTile(contentPadding:const EdgeInsets.all(12),leading:CircleAvatar(child:Icon(Icons.inventory_2_outlined)),title:Text(p.name,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('${p.category} • Stok ${p.stock}'),trailing:Row(mainAxisSize:MainAxisSize.min,children:[Text(currency.format(p.price),style:const TextStyle(fontWeight:FontWeight.bold)),IconButton(icon:const Icon(Icons.add_circle),onPressed:()=>_add(p))]));});}))),
  Container(padding:const EdgeInsets.fromLTRB(16,12,16,20),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface,boxShadow:const[BoxShadow(blurRadius:14,offset:Offset(0,-2),color:Color(0x22000000))]),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Total Belanja'),Text(currency.format(total),style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800))])),FilledButton.icon(onPressed:cart.isEmpty||widget.businessId==null?null:()=>_checkout(currency),icon:const Icon(Icons.payments),label:Text('Bayar ${cart.length}'))]),
 ]);}
 void _add(Product p){final i=cart.indexWhere((x)=>x.product.id==p.id);setState(()=>i<0?cart.add(CartItem(product:p,qty:1)):cart[i]=cart[i].copyWith(qty:cart[i].qty+1));}
 Future<void> _checkout(NumberFormat currency)async{final payment=await showModalBottomSheet<String>(context:context,builder:(sheet)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:['cash','transfer','credit'].map((m)=>ListTile(leading:Icon(m=='cash'?Icons.payments_outlined:m=='transfer'?Icons.account_balance_outlined:Icons.credit_score_outlined),title:Text(m=='cash'?'Tunai':m=='credit'?'Kasbon':'Transfer'),onTap:()=>Navigator.pop(sheet,m))).toList())));if(payment==null||!mounted)return;try{final total=cart.fold<double>(0,(s,i)=>s+i.subtotal);await _transactions.checkout(businessId:widget.businessId!,outletId:widget.outletId!,items:List.of(cart),paymentMethod:payment);if(!mounted)return;setState(cart.clear);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Transaksi berhasil • ${currency.format(total)}')));}catch(e){if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Transaksi gagal: $e')));}}
}
