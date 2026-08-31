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
 Future<void> _refresh()async{setState(()=>_future=_load());await _future;}
 Future<void> _edit([Product? product])async{
  if(widget.businessId==null)return;
  final n=TextEditingController(text:product?.name??''),h=TextEditingController(text:product?.category??''),p=TextEditingController(text:product?.price.toString()??''),s=TextEditingController(text:product?.stock.toString()??'');
  final ok=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,builder:(c)=>Padding(padding:EdgeInsets.fromLTRB(16,16,16,MediaQuery.of(c).viewInsets.bottom+16),child:Column(mainAxisSize:MainAxisSize.min,children:[
   Text(product==null?'Tambah Produk':'Edit Produk',style:Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:14),
   TextField(controller:n,decoration:const InputDecoration(labelText:'Nama produk',border:OutlineInputBorder())),const SizedBox(height:10),
   TextField(controller:h,decoration:const InputDecoration(labelText:'Kategori',border:OutlineInputBorder())),const SizedBox(height:10),
   TextField(controller:p,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Harga jual',border:OutlineInputBorder())),const SizedBox(height:10),
   TextField(controller:s,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Stok',border:OutlineInputBorder())),const SizedBox(height:14),
   SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Simpan')))
  ])));
  if(ok==true&&n.text.trim().isNotEmpty&&double.tryParse(p.text)!=null&&double.tryParse(s.text)!=null){try{if(product==null){await _repo.createProduct(businessId:widget.businessId!,name:n.text,category:h.text,price:double.parse(p.text),stock:double.parse(s.text));}else{await _repo.updateProduct(id:product.id,businessId:widget.businessId!,name:n.text,category:h.text,price:double.parse(p.text),stock:double.parse(s.text));}await _refresh();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gagal menyimpan: '+e.toString())));}}
  n.dispose();h.dispose();p.dispose();s.dispose();
 }
 Future<void> _archive(Product p)async{if(widget.businessId==null)return;final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Nonaktifkan produk?'),content:Text(p.name+' tidak akan muncul di Kasir.'),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Nonaktifkan'))]));if(ok==true){try{await _repo.archiveProduct(id:p.id,businessId:widget.businessId!);await _refresh();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gagal: '+e.toString())));}}}
 @override Widget build(BuildContext context){final money=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);return RefreshIndicator(onRefresh:_refresh,child:FutureBuilder<List<Product>>(future:_future,builder:(context,s){final data=(s.data??const<Product>[]).where((p)=>p.name.toLowerCase().contains(_query.toLowerCase())||p.category.toLowerCase().contains(_query.toLowerCase())).toList();return Scaffold(body: ListView(padding:const EdgeInsets.all(16),children:[
 const IrkopSectionHeader(eyebrow:'Produk & stok',title:'Katalog Produk',subtitle:'Tambah, edit, cari dan pantau stok produk.',icon:Icons.inventory_2_outlined,action:'Sinkron database'),const SizedBox(height:14),
 FilledButton.icon(onPressed:widget.businessId==null?null:()=>_edit(),icon:const Icon(Icons.add),label:const Text('Tambah Produk')),const SizedBox(height:12),
 TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari nama atau kategori',border:OutlineInputBorder()),onChanged:(v)=>setState(()=>_query=v)),const SizedBox(height:10),Text(data.length.toString()+' produk',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
 if(s.connectionState!=ConnectionState.done)const Padding(padding:EdgeInsets.all(32),child:Center(child:CircularProgressIndicator())),
 if(s.hasError)Padding(padding:const EdgeInsets.all(20),child:Text('Gagal memuat: '+s.error.toString())),
 if(s.connectionState==ConnectionState.done&&!s.hasError&&data.isEmpty)const EmptyStateCard(icon:Icons.inventory_2_outlined,title:'Belum ada produk',subtitle:'Tambahkan produk pertama Anda.'),
 ...data.map((p)=>Card(child:ListTile(onTap:()=>_edit(p),contentPadding:const EdgeInsets.all(14),leading:CircleAvatar(child:Icon(p.stock<=5?Icons.warning_amber_rounded:Icons.inventory_2_outlined)),title:Text(p.name,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(p.category+' • Stok '+p.stock.toStringAsFixed(0)),trailing:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(money.format(p.price),style:const TextStyle(fontWeight:FontWeight.bold)),IconButton(icon:const Icon(Icons.more_vert),onPressed:()=>_archive(p))]))),
 ]);}));}
}