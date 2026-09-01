import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/data/service_repository.dart';
import '../../shared/rupiah_input.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key, this.businessId});
  final String? businessId;

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  final _repo = ServiceRepository();
  late Future<List<ServiceOrder>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ServiceOrder>> _load() {
    if (widget.businessId == null) return Future.value(const <ServiceOrder>[]);
    return _repo.load(widget.businessId!);
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _openForm([ServiceOrder? order]) async {
    if (widget.businessId == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ServiceFormPage(
          businessId: widget.businessId!,
          order: order,
        ),
      ),
    );
    if (saved == true && mounted) await _reload();
  }

  Future<void> _remove(ServiceOrder order) async {
    if (widget.businessId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus tiket?'),
        content: Text(order.orderNo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _repo.delete(id: order.id, businessId: widget.businessId!);
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus tiket: ' + e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      floatingActionButton: widget.businessId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _openForm,
              icon: const Icon(Icons.add),
              label: const Text('Tiket'),
            ),
      body: FutureBuilder<List<ServiceOrder>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat service: ' + snapshot.error.toString()),
            );
          }

          final rows = snapshot.data ?? const <ServiceOrder>[];
          return RefreshIndicator(
            onRefresh: _reload,
            child: rows.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: const [
                      SizedBox(height: 120),
                      Icon(Icons.phone_android_outlined, size: 64),
                      SizedBox(height: 16),
                      Center(child: Text('Belum ada tiket service.')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final order = rows[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.phone_android_outlined),
                          title: Text(
                            order.customerName + ' • ' + order.deviceName,
                          ),
                          subtitle: Text(
                            order.orderNo +
                                '\n' +
                                order.status +
                                ' • Est. ' +
                                money.format(order.estimatedCost),
                          ),
                          isThreeLine: true,
                          onTap: () => _openForm(order),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _remove(order),
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class ServiceFormPage extends StatefulWidget {
  const ServiceFormPage({
    super.key,
    required this.businessId,
    this.order,
  });

  final String businessId;
  final ServiceOrder? order;

  @override
  State<ServiceFormPage> createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends State<ServiceFormPage> {
  final _repo = ServiceRepository();
  late final TextEditingController _customer;
  late final TextEditingController _phone;
  late final TextEditingController _device;
  late final TextEditingController _complaint;
  late final TextEditingController _estimate;
  late final TextEditingController _finalCost;
  late final TextEditingController _notes;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    _customer = TextEditingController(text: order?.customerName ?? '');
    _phone = TextEditingController(text: order?.customerPhone ?? '');
    _device = TextEditingController(text: order?.deviceName ?? '');
    _complaint = TextEditingController(text: order?.complaint ?? '');
    _estimate = TextEditingController(
      text: formatRupiahInput(order?.estimatedCost ?? 0),
    );
    _finalCost = TextEditingController(
      text: order?.finalCost == null ? '' : formatRupiahInput(order!.finalCost!),
    );
    _notes = TextEditingController(text: order?.notes ?? '');
    _status = order?.status ?? 'received';
  }

  @override
  void dispose() {
    _customer.dispose();
    _phone.dispose();
    _device.dispose();
    _complaint.dispose();
    _estimate.dispose();
    _finalCost.dispose();
    _notes.dispose();
    super.dispose();
  }

  double _amount(TextEditingController controller) {
    return parseRupiah(controller.text).toDouble();
  }

  Future<void> _save() async {
    if (_customer.text.trim().isEmpty || _device.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama pelanggan dan perangkat wajib diisi.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _repo.save(
        id: widget.order?.id,
        businessId: widget.businessId,
        customerName: _customer.text,
        customerPhone: _phone.text,
        deviceName: _device.text,
        complaint: _complaint.text,
        status: _status,
        estimatedCost: _amount(_estimate),
        finalCost: _finalCost.text.trim().isEmpty
            ? null
            : _amount(_finalCost),
        notes: _notes.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan service: ' + e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.order == null ? 'Tiket Service Baru' : 'Edit Service'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _customer,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nama pelanggan'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Nomor HP'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _device,
            decoration: const InputDecoration(labelText: 'Perangkat'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _complaint,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Keluhan'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'received', child: Text('Masuk')),
              DropdownMenuItem(value: 'process', child: Text('Proses')),
              DropdownMenuItem(
                value: 'waiting_parts',
                child: Text('Menunggu sparepart'),
              ),
              DropdownMenuItem(value: 'ready', child: Text('Selesai')),
              DropdownMenuItem(value: 'completed', child: Text('Diambil')),
              DropdownMenuItem(value: 'cancelled', child: Text('Batal')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _status = value);
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _estimate,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              RupiahInputFormatter(allowEmpty: false),
            ],
            decoration: const InputDecoration(
              labelText: 'Estimasi biaya',
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _finalCost,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              RupiahInputFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: 'Biaya akhir',
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Catatan'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Menyimpan...' : 'Simpan Tiket'),
          ),
        ],
      ),
    );
  }
}
