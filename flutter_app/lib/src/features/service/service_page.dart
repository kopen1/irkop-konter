import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/data/service_repository.dart';
import '../../shared/rupiah_input.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key, this.businessId});
  final String? businessId;
  @override State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  final _repo = ServiceRepository();
  late Future<List<ServiceOrder>> _future;
  String _query = '';
  String _status = 'all';

  @override void initState() { super.initState(); _future = _load(); }
  Future<List<ServiceOrder>> _load() => widget.businessId == null ? Future.value(const []) : _repo.load(widget.businessId!);
  Future<void> _reload() async { setState(() => _future = _load()); await _future; }

  Future<void> _openForm([ServiceOrder? order]) async {
    if (widget.businessId == null) return;
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => ServiceFormPage(businessId: widget.businessId!, order: order)));
    if (saved == true && mounted) await _reload();
  }

  Future<void> _remove(ServiceOrder order) async {
    if (widget.businessId == null) return;
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Hapus tiket?'), content: Text(order.orderNo),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus'))],
    ));
    if (ok != true) return;
    try { await _repo.delete(id: order.id, businessId: widget.businessId!); await _reload(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus tiket: $e'))); }
  }

  String _statusLabel(String value) => const {'received':'Masuk','process':'Proses','waiting_parts':'Menunggu sparepart','ready':'Selesai','completed':'Diambil','cancelled':'Batal'}[value] ?? value;

  @override Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Scaffold(
      floatingActionButton: widget.businessId == null ? null : FloatingActionButton.extended(onPressed: _openForm, icon: const Icon(Icons.add), label: const Text('Tiket')),
      body: FutureBuilder<List<ServiceOrder>>(future: _future, builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Gagal memuat service: ${snapshot.error}')));
        final all = snapshot.data ?? const <ServiceOrder>[];
        final q = _query.trim().toLowerCase();
        final rows = all.where((o) => (_status == 'all' || o.status == _status) && (q.isEmpty || o.orderNo.toLowerCase().contains(q) || o.customerName.toLowerCase().contains(q) || o.customerPhone.toLowerCase().contains(q) || o.deviceName.toLowerCase().contains(q))).toList();
        final active = all.where((o) => !{'completed','cancelled'}.contains(o.status)).length;
        final ready = all.where((o) => o.status == 'ready').length;
        return RefreshIndicator(onRefresh: _reload, child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Row(children: [Expanded(child: _Stat(label: 'Total tiket', value: '${all.length}')), const SizedBox(width: 10), Expanded(child: _Stat(label: 'Berjalan', value: '$active')), const SizedBox(width: 10), Expanded(child: _Stat(label: 'Siap diambil', value: '$ready'))]),
            const SizedBox(height: 12),
            TextField(onChanged: (v) => setState(() => _query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari nomor, pelanggan, HP, atau perangkat')),
            const SizedBox(height: 10),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final s in const ['all','received','process','waiting_parts','ready','completed','cancelled']) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(s == 'all' ? 'Semua' : _statusLabel(s)), selected: _status == s, onSelected: (_) => setState(() => _status = s)))])),
            const SizedBox(height: 12),
            if (rows.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24), child: Column(children: [Icon(Icons.phone_android_outlined, size: 48), SizedBox(height: 10), Text('Tidak ada tiket yang cocok'), SizedBox(height: 4), Text('Ubah pencarian atau filter status.')])),
            ...rows.map((order) => Card(child: ListTile(
              leading: CircleAvatar(child: Icon(order.status == 'ready' ? Icons.check_circle_outline : Icons.phone_android_outlined)),
              title: Text('${order.customerName} • ${order.deviceName}', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${order.orderNo}\n${_statusLabel(order.status)} • Est. ${money.format(order.estimatedCost)}', maxLines: 2),
              isThreeLine: true, onTap: () => _openForm(order),
              trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _remove(order)),
            )))
          ],
        ));
      }),
    );
  }
}

class _Stat extends StatelessWidget { const _Stat({required this.label, required this.value}); final String label, value; @override Widget build(BuildContext c) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))]))); }

class ServiceFormPage extends StatefulWidget {
  const ServiceFormPage({super.key, required this.businessId, this.order});
  final String businessId; final ServiceOrder? order;
  @override State<ServiceFormPage> createState() => _ServiceFormPageState();
}
class _ServiceFormPageState extends State<ServiceFormPage> {
  final _repo = ServiceRepository();
  late final TextEditingController _customer, _phone, _device, _complaint, _estimate, _finalCost, _notes;
  late String _status; bool _saving = false;
  @override void initState() { super.initState(); final o = widget.order; _customer=TextEditingController(text:o?.customerName??''); _phone=TextEditingController(text:o?.customerPhone??''); _device=TextEditingController(text:o?.deviceName??''); _complaint=TextEditingController(text:o?.complaint??''); _estimate=TextEditingController(text:formatRupiahInput(o?.estimatedCost??0)); _finalCost=TextEditingController(text:o?.finalCost==null?'':formatRupiahInput(o!.finalCost!)); _notes=TextEditingController(text:o?.notes??''); _status=o?.status??'received'; }
  @override void dispose(){_customer.dispose();_phone.dispose();_device.dispose();_complaint.dispose();_estimate.dispose();_finalCost.dispose();_notes.dispose();super.dispose();}
  double _amount(TextEditingController c)=>parseRupiah(c.text).toDouble();
  Future<void> _save() async { if(_customer.text.trim().isEmpty||_device.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Nama pelanggan dan perangkat wajib diisi.')));return;} setState(()=>_saving=true); try {await _repo.save(id:widget.order?.id,businessId:widget.businessId,customerName:_customer.text,customerPhone:_phone.text,deviceName:_device.text,complaint:_complaint.text,status:_status,estimatedCost:_amount(_estimate),finalCost:_finalCost.text.trim().isEmpty?null:_amount(_finalCost),notes:_notes.text);if(mounted)Navigator.pop(context,true);} catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gagal menyimpan service: $e')));} finally{if(mounted)setState(()=>_saving=false);}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.order==null?'Tiket Service Baru':'Edit Service')),body:ListView(padding:const EdgeInsets.all(16),children:[TextField(controller:_customer,textCapitalization:TextCapitalization.words,decoration:const InputDecoration(labelText:'Nama pelanggan')),const SizedBox(height:14),TextField(controller:_phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Nomor HP')),const SizedBox(height:14),TextField(controller:_device,decoration:const InputDecoration(labelText:'Perangkat')),const SizedBox(height:14),TextField(controller:_complaint,maxLines:3,decoration:const InputDecoration(labelText:'Keluhan')),const SizedBox(height:14),DropdownButtonFormField<String>(initialValue:_status,decoration:const InputDecoration(labelText:'Status'),items:const [DropdownMenuItem(value:'received',child:Text('Masuk')),DropdownMenuItem(value:'process',child:Text('Proses')),DropdownMenuItem(value:'waiting_parts',child:Text('Menunggu sparepart')),DropdownMenuItem(value:'ready',child:Text('Selesai')),DropdownMenuItem(value:'completed',child:Text('Diambil')),DropdownMenuItem(value:'cancelled',child:Text('Batal'))],onChanged:(v){if(v!=null)setState(()=>_status=v);}),const SizedBox(height:14),TextField(controller:_estimate,keyboardType:TextInputType.number,inputFormatters:[FilteringTextInputFormatter.digitsOnly,RupiahInputFormatter(allowEmpty:false)],decoration:const InputDecoration(labelText:'Estimasi biaya',prefixText:'Rp ')),const SizedBox(height:14),TextField(controller:_finalCost,keyboardType:TextInputType.number,inputFormatters:[FilteringTextInputFormatter.digitsOnly,RupiahInputFormatter()],decoration:const InputDecoration(labelText:'Biaya akhir',prefixText:'Rp ')),const SizedBox(height:14),TextField(controller:_notes,maxLines:3,decoration:const InputDecoration(labelText:'Catatan')),const SizedBox(height:24),FilledButton.icon(onPressed:_saving?null:_save,icon:_saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.save_outlined),label:Text(_saving?'Menyimpan...':'Simpan Tiket'))]));
}