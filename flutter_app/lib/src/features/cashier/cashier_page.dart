import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/product_repository.dart';
import '../../core/data/transaction_repository.dart';
import '../../core/models/business_models.dart';

class CashierPage extends StatefulWidget{
 const CashierPage({super.key,this.businessId,this.outletId});
 final String? businessId,outletId;
 @override State<CashierPage> createState()=>_CashierPageState();
}
class _CashierPageState extends State<CashierPage>{
 final _products=ProductRepository();final _transactions=TransactionRepository();final cart=<CartItem>[];late Future<List<Product>> _future;String query='';
 @override void initState(){super.initState();_future=widget.businessId==null?Future.value(const []):_products.loadProducts(widget.businessId!);}
 @override Widget build(BuildContext context){final total=cart.fold<double>(0,(s,i)=>s+i.subtotal);final c=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);
 return Column(children:[Padding(padding:const EdgeInsets.all(16),child:TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari produk'),onChanged:(v)=>setState(()=>query=v))),Expanded(child:FutureBuilder<List<Product>>(future:_future,builder:(context,s){
 if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
 if(s.hasError)return Center(child:Text('Gagal memuat produk: ${s.error}'));
 final products=(s.data??const <Product>[]).where((p)=>p.name.toLowerCase().contains(query.toLowerCase())).toList();
 if(products.isEmpty)return const Center(child:Text('Belum ada produk. Tambahkan produk di database.'));
 return ListView(children:products.map((p)=>ListTile(leading:const CircleAvatar(child:Icon(Icons.inventory_2_outlined)),title:Text(p.name),subtitle:Text('${p.category} • ${c.format(p.price)} • Stok ${p.stock}'),trailing:IconButton(icon:const Icon(Icons.add_circle),onPressed:()=>_add(p))).toList());})),Container(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text('Total ${c.format(total)}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:8),FilledButton.icon(onPressed:cart.isEmpty||widget.businessId==null?null:()=>_checkout(c),icon:const Icon(Icons.payments),label:Text('Bayar (${cart.length} item)'))]))]);}
 void _add(Product p){final i=cart.indexWhere((x)=>x.product.id==p.id);setState((){if(i<0){cart.add(CartItem(product:p,qty:1));}else{cart[i]=cart[i].copyWith(qty:cart[i].qty+1);}});}
 Future<void> _checkout(NumberFormat c)async{final payment=await showModalBottomSheet<String>(context:context,builder:(sheet)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:['cash','transfer','credit'].map((m)=>ListTile(title:Text(m=='cash'?'Tunai':m=='credit'?'Kasbon':'Transfer'),onTap:()=>Navigator.pop(sheet,m))).toList())));if(payment==null||!mounted)return;try{final total=cart.fold<double>(0,(s,i)=>s+i.subtotal);await _transactions.checkout(businessId:widget.businessId!,outletId:widget.outletId!,items:List.of(cart),paymentMethod:payment);if(!mounted)return;setState(cart.clear);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Transaksi berhasil • ${c.format(total)}')));}catch(e){if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Transaksi gagal: $e')));}}
}
