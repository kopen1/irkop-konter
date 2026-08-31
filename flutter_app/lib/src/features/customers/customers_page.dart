import 'package:flutter/material.dart';
import '../../core/data/customer_repository.dart';
import '../../shared/irkop_ui.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key,this.businessId});
  final String? businessId;
  @override State<CustomersPage> createState()=>_CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final _repo=CustomerRepository();
  late Future<List<Customer>> _future;

  @override
  void initState(){super.initState();_future=_load();}

  Future<List<Customer>> _load()=>widget.businessId==null
    ?Future.value(const <Customer>[]):_repo.loadCustomers(widget.businessId!);

  Future<void> _refresh() async {
    setState(()=>_future=_load());
    await _future;
  }

  Future<void> _addCustomer() async {
    if(widget.businessId==null)return;
    final name=TextEditingController();
    final phone=TextEditingController();
    final formKey=GlobalKey<FormState>();
    final saved=await showModalBottomSheet<bool>(
      context:context,
      isScrollControlled:true,
      builder:(sheetContext)=>Padding(
        padding:EdgeInsets.only(
          left:16,right:16,top:16,
          bottom:MediaQuery.of(sheetContext).viewInsets.bottom+16,
        ),
        child:Form(
          key:formKey,
          child:Column(
            mainAxisSize:MainAxisSize.min,
            crossAxisAlignment:CrossAxisAlignment.start,
            children:[
              Text('Pelanggan Baru',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),
              const SizedBox(height:16),
              TextFormField(
                controller:name,
                autofocus:true,
                decoration:const InputDecoration(labelText:'Nama pelanggan',border:OutlineInputBorder()),
                validator:(v)=>v==null||v.trim().isEmpty?'Nama wajib diisi':null,
              ),
              const SizedBox(height:12),
              TextField(
                controller:phone,
                keyboardType:TextInputType.phone,
                decoration:const InputDecoration(labelText:'Nomor telepon (opsional)',border:OutlineInputBorder()),
              ),
              const SizedBox(height:16),
              SizedBox(
                width:double.infinity,
                child:FilledButton.icon(
                  icon:const Icon(Icons.save_outlined),
                  label:const Text('Simpan Pelanggan'),
                  onPressed:() async {
                    if(!formKey.currentState!.validate())return;
                    try{
                      await _repo.createCustomer(
                        businessId:widget.businessId!,
                        name:name.text,
                        phone:phone.text,
                      );
                      if(sheetContext.mounted)Navigator.pop(sheetContext,true);
                    }catch(e){
                      if(sheetContext.mounted)ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content:Text('Gagal menyimpan pelanggan: '+e.toString())));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    name.dispose();
    phone.dispose();
    if(saved==true&&mounted){
      await _refresh();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Pelanggan berhasil ditambahkan.')));
    }
  }

  @override
  Widget build(BuildContext context)=>RefreshIndicator(
    onRefresh:_refresh,
    child:FutureBuilder<List<Customer>>(
      future:_future,
      builder:(context,snapshot){
        final customers=snapshot.data??const <Customer>[];
        return ListView(
          padding:const EdgeInsets.all(16),
          children:[
            IrkopSectionHeader(
              eyebrow:'Pelanggan',
              title:'Data Pelanggan',
              subtitle:'Kelola data pelanggan untuk transaksi dan riwayat bisnis.',
              icon:Icons.people_outline,
              action:'Tambah pelanggan',
            ),
            const SizedBox(height:16),
            FilledButton.icon(
              onPressed:widget.businessId==null?null:_addCustomer,
              icon:const Icon(Icons.person_add_alt_1_outlined),
              label:const Text('Tambah Pelanggan Baru'),
            ),
            const SizedBox(height:16),
            if(snapshot.connectionState!=ConnectionState.done)
              const Padding(padding:EdgeInsets.all(32),child:Center(child:CircularProgressIndicator()))
            else if(snapshot.hasError)
              EmptyStateCard(icon:Icons.error_outline,title:'Gagal memuat pelanggan',subtitle:snapshot.error.toString())
            else if(customers.isEmpty)
              const EmptyStateCard(icon:Icons.people_outline,title:'Belum ada pelanggan',subtitle:'Tambahkan pelanggan baru untuk mulai menyimpan data pelanggan.')
            else
              ...customers.map((customer)=>Card(
                child:ListTile(
                  leading:CircleAvatar(child:Text(customer.name.isEmpty?'P':customer.name.substring(0,1).toUpperCase())),
                  title:Text(customer.name,style:const TextStyle(fontWeight:FontWeight.w700)),
                  subtitle:Text(customer.phone==null||customer.phone!.isEmpty?'Tanpa nomor telepon':customer.phone!),
                ),
              )),
          ],
        );
      },
    ),
  );
}
