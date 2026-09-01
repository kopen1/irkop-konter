import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/payroll_repository.dart';

class PayrollPage extends StatefulWidget {
  const PayrollPage({super.key, this.businessId});
  final String? businessId;

  @override
  State<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends State<PayrollPage> {
  final _repo = PayrollRepository();
  late Future<List<PayrollRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<PayrollRecord>> _load() {
    if (widget.businessId == null) return Future.value(const <PayrollRecord>[]);
    return _repo.load(widget.businessId!);
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _openForm([PayrollRecord? row]) async {
    if (widget.businessId == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PayrollFormPage(
          businessId: widget.businessId!,
          record: row,
        ),
      ),
    );
    if (saved == true && mounted) await _reload();
  }

  Future<void> _togglePaid(PayrollRecord row) async {
    if (widget.businessId == null) return;
    try {
      await _repo.markPaid(
        id: row.id,
        businessId: widget.businessId!,
        paid: row.paidAt == null,
      );
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah pembayaran: ' + e.toString())),
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
              label: const Text('Gaji'),
            ),
      body: FutureBuilder<List<PayrollRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat gaji: ' + snapshot.error.toString()),
            );
          }

          final rows = snapshot.data ?? const <PayrollRecord>[];
          return RefreshIndicator(
            onRefresh: _reload,
            child: rows.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: const [
                      SizedBox(height: 120),
                      Icon(Icons.badge_outlined, size: 64),
                      SizedBox(height: 16),
                      Center(child: Text('Belum ada data gaji.')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final period = DateFormat('MMMM yyyy', 'id_ID').format(row.period);
                      final status = row.paidAt == null
                          ? 'Belum dibayar'
                          : 'Sudah dibayar';
                      return Card(
                        child: ListTile(
                          title: Text(row.employeeName),
                          subtitle: Text(period + ' • ' + status),
                          trailing: Text(
                            money.format(row.netAmount),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          onTap: () => _openForm(row),
                          onLongPress: () => _togglePaid(row),
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

class PayrollFormPage extends StatefulWidget {
  const PayrollFormPage({
    super.key,
    required this.businessId,
    this.record,
  });

  final String businessId;
  final PayrollRecord? record;

  @override
  State<PayrollFormPage> createState() => _PayrollFormPageState();
}

class _PayrollFormPageState extends State<PayrollFormPage> {
  final _repo = PayrollRepository();
  late final TextEditingController _name;
  late final TextEditingController _base;
  late final TextEditingController _bonus;
  late final TextEditingController _deduction;
  late final TextEditingController _notes;
  late DateTime _period;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final row = widget.record;
    _name = TextEditingController(text: row?.employeeName ?? '');
    _base = TextEditingController(text: row?.baseAmount.toStringAsFixed(0) ?? '0');
    _bonus = TextEditingController(text: row?.bonusAmount.toStringAsFixed(0) ?? '0');
    _deduction = TextEditingController(text: row?.deductionAmount.toStringAsFixed(0) ?? '0');
    _notes = TextEditingController(text: row?.notes ?? '');
    _period = row?.period ?? DateTime.now();
  }

  @override
  void dispose() {
    _name.dispose();
    _base.dispose();
    _bonus.dispose();
    _deduction.dispose();
    _notes.dispose();
    super.dispose();
  }

  double _amount(TextEditingController controller) {
    return double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
  }

  Future<void> _pickPeriod() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _period,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _period = picked);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama karyawan wajib diisi.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _repo.save(
        id: widget.record?.id,
        businessId: widget.businessId,
        employeeName: _name.text,
        period: _period,
        baseAmount: _amount(_base),
        bonusAmount: _amount(_bonus),
        deductionAmount: _amount(_deduction),
        notes: _notes.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan gaji: ' + e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final month = DateFormat('MMMM yyyy', 'id_ID').format(_period);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.record == null ? 'Tambah Gaji' : 'Edit Gaji'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nama karyawan'),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Periode gaji'),
              subtitle: Text(month),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickPeriod,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _base,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Gaji pokok'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _bonus,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Bonus'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _deduction,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Potongan'),
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
            label: Text(_saving ? 'Menyimpan...' : 'Simpan Gaji'),
          ),
        ],
      ),
    );
  }
}
