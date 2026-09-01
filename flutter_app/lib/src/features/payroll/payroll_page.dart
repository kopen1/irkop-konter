import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/payroll_repository.dart';
import '../../shared/rupiah_input.dart';

class PayrollPage extends StatefulWidget {
  const PayrollPage({super.key, this.businessId});

  final String? businessId;

  @override
  State<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends State<PayrollPage> {
  final repo = PayrollRepository();
  late Future<List<PayrollRecord>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<PayrollRecord>> _load() {
    final id = widget.businessId;
    if (id == null) return Future.value(const <PayrollRecord>[]);
    return repo.load(id);
  }

  Future<void> refresh() async {
    setState(() => future = _load());
    await future;
  }

  Future<void> openForm([PayrollRecord? record]) async {
    final businessId = widget.businessId;
    if (businessId == null) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PayrollFormPage(
          businessId: businessId,
          record: record,
        ),
      ),
    );

    if (saved == true && mounted) await refresh();
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Gaji Karyawan')),
      floatingActionButton: widget.businessId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: openForm,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Gaji'),
            ),
      body: FutureBuilder<List<PayrollRecord>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Gagal memuat gaji\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: refresh,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final rows = snapshot.data ?? const <PayrollRecord>[];
          final total = rows.fold<double>(
            0,
            (value, record) => value + record.netAmount,
          );
          final paid = rows.where((record) => record.paidAt != null).length;

          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL GAJI',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          money.format(total),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text('$paid dari ${rows.length} sudah dibayar'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (rows.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          const Icon(Icons.badge_outlined, size: 52),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada data gaji',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: openForm,
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Gaji'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...rows.map(
                    (record) => Card(
                      child: ListTile(
                        onTap: () => openForm(record),
                        leading: CircleAvatar(
                          child: Text(
                            record.employeeName.isEmpty
                                ? '?'
                                : record.employeeName[0].toUpperCase(),
                          ),
                        ),
                        title: Text(
                          record.employeeName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          DateFormat('MMMM yyyy', 'id_ID').format(record.period),
                        ),
                        trailing: Text(
                          money.format(record.netAmount),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PayrollFormPage extends StatefulWidget {
  const PayrollFormPage({super.key, required this.businessId, this.record});

  final String businessId;
  final PayrollRecord? record;

  @override
  State<PayrollFormPage> createState() => _PayrollFormPageState();
}

class _PayrollFormPageState extends State<PayrollFormPage> {
  final repo = PayrollRepository();
  final formKey = GlobalKey<FormState>();

  late final TextEditingController name;
  late final TextEditingController base;
  late final TextEditingController bonus;
  late final TextEditingController deduction;
  late final TextEditingController notes;
  late DateTime period;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    name = TextEditingController(text: record?.employeeName ?? '');
    base = TextEditingController(
      text: formatRupiahInput(record?.baseAmount ?? 0),
    );
    bonus = TextEditingController(
      text: formatRupiahInput(record?.bonusAmount ?? 0),
    );
    deduction = TextEditingController(
      text: formatRupiahInput(record?.deductionAmount ?? 0),
    );
    notes = TextEditingController(text: record?.notes ?? '');
    period = record?.period ?? DateTime.now();
  }

  @override
  void dispose() {
    name.dispose();
    base.dispose();
    bonus.dispose();
    deduction.dispose();
    notes.dispose();
    super.dispose();
  }

  int valueOf(TextEditingController controller) => parseRupiah(controller.text);

  int get net => valueOf(base) + valueOf(bonus) - valueOf(deduction);

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (net < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Potongan tidak boleh melebihi gaji.')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      await repo.save(
        id: widget.record?.id,
        businessId: widget.businessId,
        employeeName: name.text.trim(),
        period: period,
        baseAmount: valueOf(base).toDouble(),
        bonusAmount: valueOf(bonus).toDouble(),
        deductionAmount: valueOf(deduction).toDouble(),
        notes: notes.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget moneyField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [RupiahInputFormatter(allowEmpty: false)],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        prefixText: 'Rp ',
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Nominal wajib diisi' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.record == null ? 'Tambah Gaji' : 'Edit Gaji'),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nama karyawan',
                  hintText: 'Contoh: Andi',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nama wajib diisi'
                    : null,
              ),
              const SizedBox(height: 14),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('Periode'),
                  subtitle: Text(
                    DateFormat('MMMM yyyy', 'id_ID').format(period),
                  ),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: period,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (selected != null && mounted) {
                      setState(() => period = selected);
                    }
                  },
                ),
              ),
              const SizedBox(height: 14),
              moneyField('Gaji pokok', base, Icons.account_balance_wallet_outlined),
              const SizedBox(height: 12),
              moneyField('Bonus', bonus, Icons.add_circle_outline),
              const SizedBox(height: 12),
              moneyField('Potongan', deduction, Icons.remove_circle_outline),
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: ListTile(
                  title: const Text(
                    'Total diterima',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  trailing: Text(
                    money.format(net),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  hintText: 'Opsional',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: saving ? null : save,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(saving ? 'Menyimpan...' : 'Simpan Gaji'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
