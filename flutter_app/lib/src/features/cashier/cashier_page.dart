import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/product_repository.dart';
import '../../core/models/business_models.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key,this.businessId,this.outletId});
  final String? businessId;
  final String? outletId;
  @override State<CashierPage> createState()=>_CashierPageState();
}
class _CashierPageState extends State<CashierPage> {
  final ProductRepository _products=ProductRepository();
  final List<CartItem> _cart=[];
  late Future<List<Product>> _future;
  String _query='';
  @override void initState(){super.initState();_future=widget.businessId==null?Future.value(const <Product>[]):_products.loadProducts(widget.businessId!);}
  void _add(Product p){final i=_cart.indexWhere((x)=>x.product.id==p.id);setState((){if(i<0){_cart.add(CartItem(product:p,qty:1));}else{_cart[i]=_cart[i].copyWith(qty:_cart[i].qty+1);}});}
  @override Widget build(BuildContext context){
    final currency=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);
    final total=_cart.fold<double>(0,(sum,item)=>sum+item.subtotal);
    return Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,14,16,10),child:Container(width:double.infinity,padding:const EdgeInsets.all(18),decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),color:Theme.of(context).colorScheme.secondaryContainer),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('KASIR CEPAT',style:Theme.of(context).textTheme.labelLarge),const SizedBox(height:5),Text('Mulai Penjualan',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(_cart.length.toString()+' item di keranjang • '+currency.format(total))]))),
      Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari produk untuk dijual',border:OutlineInputBorder()),onChanged:(v)=>setState(()=>_query=v))),
      const SizedBox(height:8),
      Expanded(child:FutureBuilder<List<Product>>(future:_future,builder:(context,snapshot){
        if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
        if(snapshot.hasError)return Center(child:Text('Gagal memuat produk: '+snapshot.error.toString()));
        final products=(snapshot.data??const <Product>[]).where((p)=>p.name.toLowerCase().contains(_query.toLowerCase())).toList();
        if(products.isEmpty)return const Center(child:Text('Belum ada produk. Tambahkan produk di menu Produk.'));
        return ListView.separated(padding:const EdgeInsets.fromLTRB(16,8,16,16),itemCount:products.length,separatorBuilder:(_,__)=>const SizedBox(height:6),itemBuilder:(context,index){final p=products[index];return Card(child:ListTile(contentPadding:const EdgeInsets.all(12),leading:const CircleAvatar(child:Icon(Icons.inventory_2_outlined)),title:Text(p.name,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(p.category+' • Stok '+p.stock.toString()),trailing:Row(mainAxisSize:MainAxisSize.min,children:[Text(currency.format(p.price),style:const TextStyle(fontWeight:FontWeight.bold)),IconButton(icon:const Icon(Icons.add_circle),onPressed:()=>_add(p))])));});
      })),
      Container(padding:const EdgeInsets.fromLTRB(16,12,16,20),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Total Belanja'),Text(currency.format(total),style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800))])),FilledButton.icon(onPressed:_cart.isEmpty?null:(){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Pembayaran akan diproses pada tahap berikutnya.')));},icon:const Icon(Icons.payments),label:Text('Bayar '+_cart.length.toString()))]))
    ]);
  }
}