import 'package:flutter/material.dart';
import '../../core/data/outlet_repository.dart';
import '../../shared/irkop_ui.dart';

class OutletsPage extends StatefulWidget {
  const OutletsPage({super.key,this.businessId});
  final String? businessId;
  @override State<OutletsPage> createState()=>_OutletsPageState();
}
class _OutletsPageState extends State<OutletsPage> {
  final _repo=OutletRepository();
  late Future<List<OutletRecord>> _future;
  @override void initState(){super.initState();_future=_load();}
  Future<List<OutletRecord>> _load()=>widget.businessId==null?Future.value(const []):_repo.load(widget.businessId!);
  Future<void> _refresh()async{setState(()=>_future=_load());await _future;}
  Future<void> _add()async{
    final businessId=widget.businessId;if(businessId==null)return;
    final controller=TextEditingController();
    final saved=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,builder:(c)=>Padding(
      padding:EdgeInsets.fromLTRB(16,16,16,MediaQuery.of(c).viewInsets.bottom+16),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:controller,decoration:const InputDecoration(labelText:'Nama outlet',border:OutlineInputBorder())),
        const SizedBox(height:12),
        SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Tambah Outlet')))
      ])));
    if(saved==true&&controller.text.trim().isNotEmpty){try{await _repo.create(businessId:businessId,name:controller.text);await _refresh();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Outlet ditambahkan.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gagal menambah outlet: '+e.toString())));}}
    controller.dispose();
  }
  @override Widget build(BuildContext context)=>RefreshIndicator(
    onRefresh:_refresh,
    child:FutureBuilder<List<OutletRecord>>(
      future:_future,
      builder:(context,snapshot)=>ListView(
        padding:const EdgeInsets.all(16),
        children:[
          IrkopSectionHeader(eyebrow:'Bisnis',title:'Kelola Outlet',subtitle:'Tambah outlet dan atur status aktif.',icon:Icons.storefront_outlined,action:'Tambah Outlet',onAction:_add),
          const SizedBox(height:12),
          if(snapshot.connectionState!=ConnectionState.done)const Center(child:Padding(padding:EdgeInsets.all(30),child:CircularProgressIndicator())),
          if(snapshot.hasError)Text('Gagal memuat outlet: '+snapshot.error.toString()),
          if(snapshot.connectionState==ConnectionState.done&&!snapshot.hasError&&(snapshot.data??const []).isEmpty)
            const EmptyStateCard(icon:Icons.storefront_outlined,title:'Belum ada outlet',subtitle:'Tambahkan outlet untuk bisnis Anda.'),
          ...(snapshot.data??const <OutletRecord>[]).map((outlet)=>Card(child:SwitchListTile(
            value:outlet.active,
            title:Text(outlet.name),
            subtitle:Text(outlet.active?'Aktif':'Nonaktif'),
            onChanged:(value)async{final businessId=widget.businessId;if(businessId==null)return;try{await _repo.setActive(id:outlet.id,businessId:businessId,active:value);await _refresh();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gagal mengubah status: '+e.toString())));}}
          )))
        ],
      ),
    ),
  );
}
