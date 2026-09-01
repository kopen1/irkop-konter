import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/data/expense_repository.dart';
import '../../shared/irkop_ui.dart';
import '../../shared/rupiah_input.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key,this.businessId});
  final String? businessId;
  @override State<ExpensesPage> createState()=>_ExpensesPageState();
}
class _ExpensesPageState extends State<ExpensesPage>{
  final _repo=ExpenseRepository(); late Future<List<Expense>> _future; String _query='';
  @override void initState(){super.initState();_future=_load();}
  Future<List<Expense>> _load()=>widget.businessId==null?Future.value(const []):_repo.load(widget.businessId!);
  Future<void> _refresh()async{setState(()=>_future=_load());await _future;}
  Future<void> _save([Expense? expense]) async {
    if(widget.businessId==null)return;
    final category=TextEditingController(text:expense?.category ?? 'Operasional');
    final amount=TextEditingController(text:expense == null ? '' : formatRupiahInput(expense.amount));
    final description=TextEditingController(text:expense?.description ?? '');
    final ok=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,builder:(context)=>Padding(
      padding:EdgeInsets.fromLTRB(20,20,20,20+MediaQuery.of(context).viewInsets.bottom),
      child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(expense==null?'Tambah Pengeluaran':'Ubah Pengeluaran',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),
        const SizedBox(height:16),
        TextField(controller:category,decoration:const InputDecoration(labelText:'Kategori')),
        const SizedBox(height:10),
        TextField(controller:amount,keyboardType:TextInputType.number,inputFormatters:[FilteringTextInputFormatter.digitsOnly,RupiahInputFormatter()],decoration:const InputDecoration(labelText:'Nominal',prefixText:'Rp ')),
        const SizedBox(height:10),
        TextField(controller:description,maxLines:2,decoration:const InputDecoration(labelText:'Keterangan (opsional)')),
        const SizedBox(height:16),
        SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Simpan'))),
      ],
    )));
    if(ok!=true)return;
    final value=parseRupiah(amount.text).toDouble();
    try{
      if(expense==null){await _repo.create(businessId:widget.businessId!,category:category.text,amount:value,description:description.text);}
      else{await _repo.update(id:expense.id,businessId:widget.businessId!,category:category.text,amount:value,description:description.text);}
      if(mounted){await _refresh();ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Pengeluaran tersimpan.')));}
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gagal menyimpan: '+e.toString())));}
  }
  Future<void> _delete(Expense e)async{
    if(widget.businessId==null)return;
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Hapus pengeluaran?'),content:const Text('Data yang dihapus tidak dapat dikembalikan.'),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Hapus'))]));
    if(ok==true){try{await _repo.delete(id:e.id,businessId:widget.businessId!);await _refresh();}catch(err){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gagal menghapus: '+err.toString())));}}
  }
  @override Widget build(BuildContext context){
    final money=NumberFormat.currency(locale:'id_ID',symbol:'Rp ',decimalDigits:0);
    return RefreshIndicator(onRefresh:_refresh,child:FutureBuilder<List<Expense>>(future:_future,builder:(context,s){
      final all=s.data??const <Expense>[]; final items=all.where((e)=>(e.category+' '+e.description).toLowerCase().contains(_query.toLowerCase())).toList();
      final now=DateTime.now(); final month=all.where((e)=>e.expenseAt.toLocal().year==now.year&&e.expenseAt.toLocal().month==now.month).fold<double>(0,(a,e)=>a+e.amount);
      return ListView(padding:const EdgeInsets.fromLTRB(16,12,16,28),children:[
        const IrkopSectionHeader(eyebrow:'OPERASIONAL',title:'Pengeluaran',subtitle:'Catat dan pantau biaya operasional bisnis.',icon:Icons.account_balance_wallet_outlined,action:'Data aktual'),
        const SizedBox(height:14),
        Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Pengeluaran bulan ini',style:Theme.of(context).textTheme.labelLarge),const SizedBox(height:6),Text(money.format(month),style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800))]))),
        const SizedBox(height:12),
        TextField(onChanged:(v)=>setState(()=>_query=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari kategori atau keterangan')),
        const SizedBox(height:14),
        if(s.connectionState!=ConnectionState.done)const LinearProgressIndicator(),
        if(s.hasError)Card(child:Padding(padding:const EdgeInsets.all(16),child:Text('Gagal memuat pengeluaran: '+s.error.toString()))),
        if(!s.hasError&&s.connectionState==ConnectionState.done&&items.isEmpty)const EmptyStateCard(icon:Icons.account_balance_wallet_outlined,title:'Belum ada pengeluaran',subtitle:'Tambahkan biaya operasional pertama Anda.'),
        ...items.map((e)=>Card(margin:const EdgeInsets.only(bottom:10),child:ListTile(
          leading:const CircleAvatar(child:Icon(Icons.payments_outlined)),
          title:Text(e.category,style:const TextStyle(fontWeight:FontWeight.w800)),
          subtitle:Text(DateFormat('dd MMM yyyy','id_ID').format(e.expenseAt.toLocal())+(e.description.isEmpty?'':' • '+e.description)),
          trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit'){_save(e);}else{_delete(e);}},itemBuilder:(c)=>const [PopupMenuItem(value:'edit',child:Text('Ubah')),PopupMenuItem(value:'delete',child:Text('Hapus'))],child:Row(mainAxisSize:MainAxisSize.min,children:[Text(money.format(e.amount),style:const TextStyle(fontWeight:FontWeight.w800)),const Icon(Icons.more_vert)])),
        ))),
      ]);
    }));
  }
}