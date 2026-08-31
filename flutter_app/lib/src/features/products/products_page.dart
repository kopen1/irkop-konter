import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/product_repository.dart';
import '../../core/models/business_models.dart';
import '../../shared/irkop_ui.dart';

class ProductsPage extends StatefulWidget{const ProductsPage({super.key,this.businessId});final String? businessId;@override State<ProductsPage> createState()=>_ProductsPageState();}
class _ProductsPageState extends State<ProductsPage>{
 final _repo=ProductRepository();late Future<List<Product>> _future;String _query='';
 @override void initState(){super.initState();_future=_load();}
 Future<List<Product>> _load()=>widget.businessId==null?Future.value(const[]):_repo.loadProducts(widget.businessId!); Future<void> _addProduct()async{final n=TextEditingController(),h=TextEditingController(),p=TextEditingController(),s=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Tambah Produk Baru'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'Nama produk')),TextField(controller:h,decoration:const InputDecoration(labelText:'Kategori')),TextField(controller:p,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Harga jual')),TextField(controller:s,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Stok awal'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Simpan'))]));if(ok==true&&n.text.trim().isNotEmpty&&double.tryParse(p.text)!=null&&double.tryParse(s.text)!=null){try{await _repo.createProduct(businessId:widget.businessId!,name:n.text,category:h.text,price:double.parse(p.text),stock:double.parse(s.text));setState(()=>_future=_load());}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gagal menyimpan produk: $e')));}}n.dispose();h.dispose();p.dispose();s.dispose();}
 @override Widget build(BuildContext context){final c=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);return FutureBuilder<List<Product>>(future:_future,builder:(context,s){final all=s.data??const<Product>[];final data=all.where((p)=>p.name.toLowerCase().contains(_query.toLowerCase())).toList();return ListView(padding:const EdgeInsets.all(16),children:[
 const IrkopSectionHeader(eyebrow:'Produk & stok',title:'Katalog Produk',subtitle:'Pantau harga dan ketersediaan produk Anda.',icon:Icons.inventory_2_outlined,action:'Sinkron dengan database'),
 const SizedBox(height:14),FilledButton.icon(onPressed:widget.businessId==null?null:_addProduct,icon:const Icon(Icons.add),label:const Text('Tambah Produk Baru')),const SizedBox(height:14),TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari produk',border:OutlineInputBorder()),onChanged:(v)=>setState(()=>_query=v)),const SizedBox(height:12),
 Text('${data.length} produk',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.bold)),
 if(s.connectionState!=ConnectionState.done)const Padding(padding:EdgeInsets.all(32),child:Center(child:CircularProgressIndicator())),
 if(s.hasError)Padding(padding:const EdgeInsets.all(24),child:Text('Gagal memuat produk: ${s.error}')),
 if(s.connectionState==ConnectionState.done&&!s.hasError&&data.isEmpty)const EmptyStateCard(icon:Icons.inventory_2_outlined,title:'Belum ada produk',subtitle:'Tekan Tambah Produk Baru untuk membuat produk pertama.'),
 ...data.map((p)=>Card(child:ListTile(contentPadding:const EdgeInsets.all(14),leading:CircleAvatar(child:Icon(p.stock<=5?Icons.warning_amber_rounded:Icons.inventory_2_outlined)),title:Text(p.name,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('${p.category} • Stok ${p.stock}'),trailing:Text(c.format(p.price),style:const TextStyle(fontWeight:FontWeight.bold))))),
 ]);});}
}
