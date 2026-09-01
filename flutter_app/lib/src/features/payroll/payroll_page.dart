import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/payroll_repository.dart';
import '../../shared/rupiah_input.dart';

class PayrollPage extends StatefulWidget {
  const PayrollPage({super.key, this.businessId});
  final String? businessId;
  @override State<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends State<PayrollPage> {
  final _repo = PayrollRepository();
  late Future<List<PayrollRecord>> _future;
  @override void initState() { super.initState(); _future = _load(); }
  Future<List<PayrollRecord>> _load() => widget.businessId == null ? Future.value(const []) : _repo.load(widget.businessId!);
  Future<void> _reload() async { setState(() => _future = _load()); await _future; }
  Future<void> _openForm([PayrollRecord? row]) async {
    final id = widget.businessId;
    if (id == null) return;
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => PayrollFormPage(businessId: id, record: row)));
    if (saved == true && mounted) await _reload();
  }
  Future<void> _togglePaid(PayrollRecord row) async {
    final id = widget.businessId; if (id == null) return;
    try { await _repo.markPaid(id: row.id, businessId: id, paid: row.paidAt == null); await _reload(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengubah pembayaran: $e'))); }
  }
  @override Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Scaffold(
      floatingActionButton: widget.businessId == null ? null : FloatingActionButton.extended(onPressed: _openForm, icon: const Icon(Icons.add), label: const Text('Gaji')),
      body: FutureBuilder<List<PayrollRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 40), const SizedBox(height: 12), Text('Gagal memuat gaji\n${snapshot.error}', textAlign: TextAlign.center), const SizedBox(height: 16), OutlinedButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Coba lagi'))])));
          final rows = snapshot.data ?? const [];
          final total = rows.fold<double>(0, (sum, row) => sum + row.netAmount);
          return RefreshIndicator(onRefresh: _reload, child: ListView(padding: const EdgeInsets.fromLTRB(16,16,16,96), children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: Theme.of(context).colorScheme.primaryContainer), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const CircleAvatar(child: Icon(Icons.payments_outlined)), const SizedBox(width: 12), const Expanded(child: Text('GAJI KARYAWAN', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1))), IconButton(onPressed: () => _openForm(), icon: const Icon(Icons.add_circle_outline))]),
              const SizedBox(height: 18), const Text('Total periode ini'), const SizedBox(height: 4), Text(money.format(total), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 12), Text('${rows.where((r) => r.paidAt != null).length} dari ${rows.length} data sudah dibayar')
            ])),
            const SizedBox(height: 18), Text('Riwayat Gaji', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 8),
            if (rows.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(28), child: Column(children: [const Icon(Icons.badge_outlined, size: 56), const SizedBox(height: 12), const Text('Belum ada data gaji', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), const Text('Tambahkan data gaji pertama.', textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton.icon(onPressed: () => _openForm(), icon: const Icon(Icons.add), label: const Text('Tambah Gaji'))])))
            else ...rows.map((row) => Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(onTap: () => _openForm(row), onLongPress: () => _togglePaid(row), leading: CircleAvatar(child: Text(row.employeeName.isEmpty ? '?' : row.employeeName[0].toUpperCase())), title: Text(row.employeeName, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${DateFormat('MMMM yyyy', 'id_ID').format(row.period)} • ${row.paidAt == null ? 'Belum dibayar' : 'Sudah dibayar'}'), trailing: Text(money.format(row.netAmount), style: const TextStyle(fontWeight: FontWeight.w900))))),
          ]));
        },
      ),
    );
  }
}

class PayrollFormPage extends StatefulWidget {
  const PayrollFormPage({super.key, required this.businessId, this.record});
  final String businessId; final PayrollRecord? record;
  @override State<PayrollFormPage> createState() => _PayrollFormPageState();
}

class _PayrollFormPageState extends State<PayrollFormPage> {
  final _repo = PayrollRepository(); final _key = GlobalKey<FormState>();
  late final TextEditingController _name, _base, _bonus, _deduction, _notes;
  late DateTime _period; bool _saving = false;
  @override void initState() { super.initState(); final r = widget.record; _name = TextEditingController(text: r?.employeeName ?? ''); _base = TextEditingController(text: formatRupiahInput(r?.baseAmount ?? 0)); _bonus = TextEditingController(text: formatRupiahInput(r?.bonusAmount ?? 0)); _deduction = TextEditingController(text: formatRupiahInput(r?.deductionAmount ?? 0)); _notes = TextEditingController(text: r?.notes ?? ''); _period = r?.period ?? DateTime.now(); }
  @override void dispose() { _name.dispose(); _base.dispose(); _bonus.dispose(); _deduction.dispose(); _notes.dispose(); super.dispose(); }
  int _v(TextEditingController c) => parseRupiah(c.text);
  int get _net => _v(_base) + _v(_bonus) - _v(_deduction);
  Future<void> _pickPeriod() async { final p = await showDatePicker(context: context, initialDate: _period, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (p != null && mounted) setState(() => _period = p); }
  Future<void> _save() async {
    if (!(_key.currentState?.validate() ?? false)) return;
    if (_net < 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Potongan melebihi total gaji.'))); return; }
    setState(() => _saving = true);
    try { await _repo.save(id: widget.record?.id, businessId: widget.businessId, employeeName: _name.text, period: _period, baseAmount: _v(_base).toDouble(), bonusAmount: _v(_bonus).toDouble(), deductionAmount: _v(_deduction).toDouble(), notes: _notes.text); if (mounted) Navigator.pop(context, true); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan gaji: $e'))); }
    finally { if (mounted) setState(() => _saving = false); }
  }
  Widget _money(String label, TextEditingController c, IconData icon) => TextFormField(controller: c, keyboardType: TextInputType.number, inputFormatters: [RupiahInputFormatter(allowEmpty: false)], decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), prefixText: 'Rp '), validator: (v) => v == null || v.trim().isEmpty ? 'Nominal wajib diisi.' : null);
  @override Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Scaffold(appBar: AppBar(title: Text(widget.record == null ? 'Tambah Gaji' : 'Edit Gaji')), body: SafeArea(child: Form(key: _key, child: ListView(padding: const EdgeInsets.all(16), children: [
      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nama karyawan', prefixIcon: Icon(Icons.person_outline)), validator: (v) => v == null || v.trim().isEmpty ? 'Nama karyawan wajib diisi.' : null),
      const SizedBox(height: 14), ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_month_outlined), title: const Text('Periode gaji'), subtitle: Text(DateFormat('MMMM yyyy', 'id_ID').format(_period)), onTap: _pickPeriod),
      const SizedBox(height: 14), _money('Gaji pokok', _base, Icons.account_balance_wallet_outlined), const SizedBox(height: 14), _money('Bonus', _bonus, Icons.add_circle_outline), const SizedBox(height: 14), _money('Potongan', _deduction, Icons.remove_circle_outline),
      const SizedBox(height: 18), Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [const Expanded(child: Text('Total diterima', style: TextStyle(fontWeight: FontWeight.w800))), Text(money.format(_net), style: const TextStyle(fontWeight: FontWeight.w900))]))),
      const SizedBox(height: 14), TextFormField(controller: _notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Catatan', prefixIcon: Icon(Icons.notes_outlined))), const SizedBox(height: 22),
      FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Menyimpan...' : 'Simpan Gaji'))
    ]))));
  }
}
