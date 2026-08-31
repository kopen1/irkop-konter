import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/product_repository.dart';
import '../../core/models/business_models.dart';
import '../../shared/irkop_ui.dart';

class ProductsPage extends StatefulWidget{const ProductsPage({super.key,this.businessId});final String? businessId;@override State<ProductsPage> createState()=>_ProductsPageState();}
class _ProductsPageState extends State<ProductsPage>{
 final _repo=ProductRepository();late Future<List<Product>> _future;String _query='';
 @override void initState(){super.initState();_future=_load();}
 Future<List<Product>> _load()=>widget.businessId==null?Future.value(const[]):_repo.loadProducts(widget.businessId!);
 @override Widget build(BuildContext context){final c=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);return FutureBuilder<List<Product>>(future:_future,builder:(context,s){final all=s.data??const<Product>[];final data=all.where((p)=>p.name.toLowerCase().contains(_query.toLowerCase())).toList();return ListView(padding:const EdgeInsets.all(16),children:[
 const IrkopSectionHeader(eyebrow:'Produk & stok',title:'Katalog Produk',subtitle:'Pantau harga dan ketersediaan produk Anda.',icon:Icons.inventory_2_outlined,action:'Sinkron dengan database'),
 const SizedBox(height:18),TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari produk',border:OutlineInputBorder()),onChanged:(v)=>setState(()=>_query=v)),const SizedBox(height:12),
 Text('${data.length} produk',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.bold)),
 if(s.connectionState!=ConnectionState.done)const Padding(padding:EdgeInsets.all(32),child:Center(child:CircularProgressIndicator())),
 if(s.hasError)Padding(padding:const EdgeInsets.all(24),child:Text('Gagal memuat produk: ${s.error}')),
 if(s.connectionState==ConnectionState.done&&!s.hasError&&data.isEmpty)const EmptyStateCard(icon:Icons.inventory_2_outlined,title:'Belum ada produk',subtitle:'Produk dari database akan tampil di sini.'),
 ...data.map((p)=>Card(child:ListTile(contentPadding:const EdgeInsets.all(14),leading:CircleAvatar(child:Icon(p.stock<=5?Icons.warning_amber_rounded:Icons.inventory_2_outlined)),title:Text(p.name,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('${p.category} • Stok ${p.stock}'),trailing:Text(c.format(p.price),style:const TextStyle(fontWeight:FontWeight.bold))))),
 ]);});}
}
