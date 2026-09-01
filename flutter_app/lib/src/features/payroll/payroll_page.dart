import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat gaji\n' + snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final rows = snapshot.data ?? const <PayrollRecord>[];
          final total = rows.fold<double>(
            0,
            (sum, row) => sum + row.netAmount,
          );

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _PayrollHero(
                  total: money.format(total),
                  paidCount: rows.where((row) => row.paidAt != null).length,
                  totalCount: rows.length,
                  onAdd: () => _openForm(),
                ),
                const SizedBox(height: 18),
                Text(
                  'Riwayat Gaji',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                if (rows.isEmpty)
                  _EmptyPayroll(onAdd: () => _openForm())
                else
                  ...rows.map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PayrollCard(
                        row: row,
                        money: money,
                        onTap: () => _openForm(row),
                        onTogglePaid: () => _togglePaid(row),
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

class _PayrollHero extends StatelessWidget {
  const _PayrollHero({
    required this.total,
    required this.paidCount,
    required this.totalCount,
    required this.onAdd,
  });

  final String total;
  final int paidCount;
  final int totalCount;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.primaryContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                child: const Icon(Icons.payments_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'GAJI KARYAWAN',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                ),
              ),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Tambah gaji',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Total periode ini',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            total,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            '$paidCount dari $totalCount data sudah dibayar',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _EmptyPayroll extends StatelessWidget {
  const _EmptyPayroll({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.badge_outlined, size: 56),
            const SizedBox(height: 14),
            Text(
              'Belum ada data gaji',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tambahkan data gaji pertama untuk mulai mencatat pengeluaran karyawan.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Gaji'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayrollCard extends StatelessWidget {
  const _PayrollCard({
    required this.row,
    required this.money,
    required this.onTap,
    required this.onTogglePaid,
  });

  final PayrollRecord row;
  final NumberFormat money;
  final VoidCallback onTap;
  final VoidCallback onTogglePaid;

  @override
  Widget build(BuildContext context) {
    final paid = row.paidAt != null;
    final period = DateFormat('MMMM yyyy', 'id_ID').format(row.period);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onTogglePaid,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                child: Text(
                  row.employeeName.isEmpty
                      ? '?'
                      : row.employeeName.substring(0, 1).toUpperCase(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.employeeName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(period),
                    const SizedBox(height: 8),
                    Text(
                      paid ? 'Sudah dibayar' : 'Belum dibayar',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: paid
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                money.format(row.netAmount),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
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
  final _formKey = GlobalKey<FormState>();

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
    _base = TextEditingController(
      text: formatRupiahInput(row?.baseAmount ?? 0),
    );
    _bonus = TextEditingController(
      text: formatRupiahInput(row?.bonusAmount ?? 0),
    );
    _deduction = TextEditingController(
      text: formatRupiahInput(row?.deductionAmount ?? 0),
    );
    _notes = TextEditingController(text: row?.notes ?? '');
    _period = row?.period ?? DateTime.now();

    _base.addListener(_refreshTotal);
    _bonus.addListener(_refreshTotal);
    _deduction.addListener(_refreshTotal);
  }

  @override
  void dispose() {
    _base.removeListener(_refreshTotal);
    _bonus.removeListener(_refreshTotal);
    _deduction.removeListener(_refreshTotal);
    _name.dispose();
    _base.dispose();
    _bonus.dispose();
    _deduction.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _refreshTotal() {
    if (mounted) setState(() {});
  }

  int _amount(TextEditingController controller) {
    return parseRupiah(controller.text);
  }

  int get _netAmount =>
      _amount(_base) + _amount(_bonus) - _amount(_deduction);

  Future<void> _pickPeriod() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _period,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih periode gaji',
    );
    if (picked != null && mounted) {
      setState(() => _period = picked);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await _repo.save(
        id: widget.record?.id,
        businessId: widget.businessId,
        employeeName: _name.text,
        period: _period,
        baseAmount: _amount(_base).toDouble(),
        bonusAmount: _amount(_bonus).toDouble(),
        deductionAmount: _amount(_deduction).toDouble(),
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

  Widget _moneyField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? helper,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        RupiahInputFormatter(allowEmpty: false),
      ],
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        prefixIcon: Icon(icon),
        prefixText: 'Rp ',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final month = DateFormat('MMMM yyyy', 'id_ID').format(_period);
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
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      child: Icon(
                        widget.record == null
                            ? Icons.person_add_alt_1_outlined
                            : Icons.edit_outlined,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.record == null
                            ? 'Isi data gaji dengan lengkap'
                            : 'Perbarui data gaji karyawan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nama karyawan',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama karyawan wajib diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          child: Icon(Icons.calendar_month_outlined),
                        ),
                        title: const Text('Periode gaji'),
                        subtitle: Text(month),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _pickPeriod,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Rincian Nominal',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _moneyField(
                        label: 'Gaji pokok',
                        controller: _base,
                        icon: Icons.account_balance_wallet_outlined,
                        helper: 'Contoh: ketik 10000 menjadi 10.000',
                      ),
                      const SizedBox(height: 14),
                      _moneyField(
                        label: 'Bonus',
                        controller: _bonus,
                        icon: Icons.add_circle_outline,
                      ),
                      const SizedBox(height: 14),
                      _moneyField(
                        label: 'Potongan',
                        controller: _deduction,
                        icon: Icons.remove_circle_outline,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).colorScheme.secondaryContainer,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calculate_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Total diterima',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Text(
                      money.format(_netAmount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _notes,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Catatan',
                      hintText: 'Opsional',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
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
        ),
      ),
    );
  }
}
