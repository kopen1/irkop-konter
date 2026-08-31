import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/product_repository.dart';
import '../../core/data/transaction_repository.dart';
import '../../core/models/business_models.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key,this.businessId,this.outletId});
  final String? businessId;
  final String? outletId;
  @override State<CashierPage> createState()=>_CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final ProductRepository _products=ProductRepository();
  final TransactionRepository _transactions=TransactionRepository();
  final List<CartItem> _cart=[];
  late Future<List<Product>> _future;
  String _query='';
  bool _paying=false;

  @override
  void initState(){
    super.initState();
    _future=widget.businessId==null?Future.value(const <Product>[]):_products.loadProducts(widget.businessId!);
  }

  void _add(Product p){
    final i=_cart.indexWhere((x)=>x.product.id==p.id);
    setState((){
      if(i<0){_cart.add(CartItem(product:p,qty:1));}
      else{_cart[i]=_cart[i].copyWith(qty:_cart[i].qty+1);}
    });
  }

  void _changeQty(Product product,int delta){
    final index=_cart.indexWhere((x)=>x.product.id==product.id);
    if(index<0)return;
    setState((){
      final next=_cart[index].qty+delta;
      if(next<=0){_cart.removeAt(index);}else{_cart[index]=_cart[index].copyWith(qty:next);}
    });
  }

  Future<void> _showCart(NumberFormat currency) async {
    await showModalBottomSheet<void>(
      context:context,
      isScrollControlled:true,
      builder:(sheetContext)=>SafeArea(
        child:Padding(
          padding:const EdgeInsets.fromLTRB(16,16,16,20),
          child:StatefulBuilder(
            builder:(context,setSheetState)=>Column(
              mainAxisSize:MainAxisSize.min,
              crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                Row(children:[
                  Expanded(child:Text('Keranjang Belanja',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800))),
                  IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close)),
                ]),
                const SizedBox(height:8),
                if(_cart.isEmpty)
                  const Padding(padding:EdgeInsets.all(24),child:Center(child:Text('Keranjang masih kosong.')))
                else ...[
                  ..._cart.map((item)=>ListTile(
                    contentPadding:EdgeInsets.zero,
                    title:Text(item.product.name,style:const TextStyle(fontWeight:FontWeight.w700)),
                    subtitle:Text(currency.format(item.product.price)+' per item'),
                    leading:IconButton(
                      icon:const Icon(Icons.remove_circle_outline),
                      onPressed:(){_changeQty(item.product,-1);setSheetState((){});},
                    ),
                    trailing:Row(mainAxisSize:MainAxisSize.min,children:[
                      Text(item.qty.toString(),style:const TextStyle(fontWeight:FontWeight.w800)),
                      IconButton(
                        icon:const Icon(Icons.add_circle_outline),
                        onPressed:(){_changeQty(item.product,1);setSheetState((){});},
                      ),
                    ]),
                  )),
                  const Divider(),
                  Row(children:[
                    const Expanded(child:Text('Total',style:TextStyle(fontWeight:FontWeight.w800,fontSize:18))),
                    Text(currency.format(_cart.fold<double>(0,(s,i)=>s+i.subtotal)),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:18)),
                  ]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pay(NumberFormat currency) async {
    if(_cart.isEmpty||widget.businessId==null||widget.outletId==null)return;
    final method=await showModalBottomSheet<String>(
      context:context,
      builder:(sheetContext)=>SafeArea(
        child:Column(
          mainAxisSize:MainAxisSize.min,
          children:[
            ListTile(title:const Text('Pilih metode pembayaran'),subtitle:Text('Total '+currency.format(_cart.fold<double>(0,(s,i)=>s+i.subtotal)))),
            ListTile(leading:const Icon(Icons.payments_outlined),title:const Text('Tunai'),subtitle:const Text('Catat sebagai pemasukan kas'),onTap:()=>Navigator.pop(sheetContext,'cash')),
            ListTile(leading:const Icon(Icons.account_balance_outlined),title:const Text('Transfer'),onTap:()=>Navigator.pop(sheetContext,'transfer')),
            ListTile(leading:const Icon(Icons.credit_score_outlined),title:const Text('Kasbon'),onTap:()=>Navigator.pop(sheetContext,'credit')),
          ],
        ),
      ),
    );
    if(method==null||!mounted)return;
    setState(()=>_paying=true);
    final total=_cart.fold<double>(0,(s,i)=>s+i.subtotal);
    try{
      await _transactions.checkout(
        businessId:widget.businessId!,
        outletId:widget.outletId!,
        items:List<CartItem>.from(_cart),
        paymentMethod:method,
      );
      if(!mounted)return;
      setState(()=>_cart.clear());
      _future=_products.loadProducts(widget.businessId!);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Pembayaran berhasil • '+currency.format(total))));
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Pembayaran gagal: '+e.toString())));
    }finally{
      if(mounted)setState(()=>_paying=false);
    }
  }

  @override
  Widget build(BuildContext context){
    final currency=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);
    final total=_cart.fold<double>(0,(sum,item)=>sum+item.subtotal);
    return Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,14,16,10),child:Container(width:double.infinity,padding:const EdgeInsets.all(18),decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),color:Theme.of(context).colorScheme.secondaryContainer),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('KASIR CEPAT',style:Theme.of(context).textTheme.labelLarge),
        const SizedBox(height:5),
        Text('Mulai Penjualan',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),
        const SizedBox(height:4),
        Text(_cart.fold<int>(0,(sum,item)=>sum+item.qty).toString()+' item di keranjang • '+currency.format(total)),
      ]))),
      Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari produk untuk dijual',border:OutlineInputBorder()),onChanged:(v)=>setState(()=>_query=v))),
      const SizedBox(height:8),
      Expanded(child:FutureBuilder<List<Product>>(future:_future,builder:(context,snapshot){
        if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
        if(snapshot.hasError)return Center(child:Text('Gagal memuat produk: '+snapshot.error.toString()));
        final products=(snapshot.data??const <Product>[]).where((p)=>p.name.toLowerCase().contains(_query.toLowerCase())).toList();
        if(products.isEmpty)return const Center(child:Text('Belum ada produk. Tambahkan produk di menu Produk.'));
        return ListView.separated(
          padding:const EdgeInsets.fromLTRB(16,8,16,16),
          itemCount:products.length,
          separatorBuilder:(_,__)=>const SizedBox(height:6),
          itemBuilder:(context,index){
            final p=products[index];
            return Card(child:ListTile(
              contentPadding:const EdgeInsets.all(12),
              leading:const CircleAvatar(child:Icon(Icons.inventory_2_outlined)),
              title:Text(p.name,style:const TextStyle(fontWeight:FontWeight.w700)),
              subtitle:Text(p.category+' • Stok '+p.stock.toString()),
              trailing:Row(mainAxisSize:MainAxisSize.min,children:[
                Text(currency.format(p.price),style:const TextStyle(fontWeight:FontWeight.bold)),
                IconButton(icon:const Icon(Icons.add_circle),onPressed:()=>_add(p)),
              ]),
            ));
          },
        );
      })),
      if(_cart.isNotEmpty)
        Padding(
          padding:const EdgeInsets.fromLTRB(16,0,16,4),
          child:OutlinedButton.icon(
            onPressed:()=>_showCart(currency),
            icon:const Icon(Icons.shopping_cart_outlined),
            label:Text('Lihat Keranjang • '+_cart.fold<int>(0,(sum,item)=>sum+item.qty).toString()+' item'),
          ),
        ),
      Container(padding:const EdgeInsets.fromLTRB(16,12,16,20),child:Row(children:[
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Total Belanja'),
          Text(currency.format(total),style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),
        ])),
        FilledButton.icon(
          onPressed:_cart.isEmpty||_paying?null:()=>_pay(currency),
          icon:_paying?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.payments),
          label:Text(_paying?'Memproses':'Bayar '+_cart.length.toString()),
        ),
      ])),
    ]);
  }
}
