import 'package:flutter/material.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/data/business_context_repository.dart';
import '../../core/data/business_settings_repository.dart';
import '../../core/data/money_account_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.businessContext});
  final BusinessContext? businessContext;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final TextEditingController _businessName;
  late final TextEditingController _address;
  late final TextEditingController _header;
  late final TextEditingController _footer;
  final _businessRepository = BusinessContextRepository();
  final _settingsRepository = BusinessSettingsRepository();
  final _moneyRepository = MoneyAccountRepository();
  late Future<List<MoneyAccount>> _moneyFuture;
  bool _autoInput = true;
  bool _darkMode = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _businessName = TextEditingController(
      text: widget.businessContext?.businessName ?? 'IRKOP KONTER',
    );
    _address = TextEditingController(text: 'Alamat toko belum diatur');
    _header = TextEditingController(text: 'TERIMA KASIH ATAS KUNJUNGAN ANDA');
    _footer = TextEditingController(text: 'Semoga harimu menyenangkan!');
    _loadPersistedSettings();
    _moneyFuture = _loadMoneyAccounts();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _businessName.dispose();
    _address.dispose();
    _header.dispose();
    _footer.dispose();
    super.dispose();
  }

  Future<List<MoneyAccount>> _loadMoneyAccounts() => widget.businessContext == null ? Future.value(const []) : _moneyRepository.load(widget.businessContext!.businessId);
  Future<void> _refreshMoneyAccounts() async { setState(() => _moneyFuture = _loadMoneyAccounts()); await _moneyFuture; }

  Future<void> _addMoneyAccount() async { final b=widget.businessContext?.businessId; if(b==null)return; final name=TextEditingController(); String type='cash'; final amount=TextEditingController(text:'0'); final ok=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,builder:(c)=>StatefulBuilder(builder:(c,setSheet)=>Padding(padding:EdgeInsets.fromLTRB(16,16,16,16+MediaQuery.of(c).viewInsets.bottom),child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('Tambah akun uang'),const SizedBox(height:10),TextField(controller:name,decoration:const InputDecoration(labelText:'Nama akun')),const SizedBox(height:8),DropdownButtonFormField(value:type,items:const [DropdownMenuItem(value:'cash',child:Text('Tunai')),DropdownMenuItem(value:'bank',child:Text('Bank')),DropdownMenuItem(value:'ewallet',child:Text('E-Wallet')),DropdownMenuItem(value:'other',child:Text('Lainnya'))],onChanged:(v)=>setSheet(()=>type=v!),decoration:const InputDecoration(labelText:'Jenis')),const SizedBox(height:8),TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Saldo awal')),const SizedBox(height:12),SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Simpan')))])))); if(ok==true&&name.text.trim().isNotEmpty){await _moneyRepository.create(businessId:b,name:name.text,type:type,openingBalance:double.tryParse(amount.text.replaceAll(RegExp(r'[^0-9.]'),''))??0);await _refreshMoneyAccounts();}}

  Future<void> _loadPersistedSettings() async {
    final contextData = widget.businessContext;
    if (contextData == null) return;
    try {
      final settings = await _settingsRepository.load(contextData.businessId);
      if (!mounted || settings == null) return;
      setState(() {
        _address.text = settings.address;
        _header.text = settings.receiptHeader;
        _footer.text = settings.receiptFooter;
        _darkMode = settings.darkMode;
        _autoInput = settings.autoInput;
      });
    } catch (_) {
      // Defaults tetap dapat digunakan bila pengaturan belum tersedia.
    }
  }

  Future<void> _saveGeneral() async {
    final contextData = widget.businessContext;
    if (contextData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan bisnis tidak tersedia di mode demo.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _businessRepository.updateBusinessName(
        businessId: contextData.businessId,
        name: _businessName.text,
      );
      await _settingsRepository.save(
        businessId: contextData.businessId,
        address: _address.text,
        receiptHeader: _header.text,
        receiptFooter: _footer.text,
        darkMode: _darkMode,
        autoInput: _autoInput,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama bisnis berhasil disimpan.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan pengaturan: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pengaturan',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            )),
                    const SizedBox(height: 3),
                    const Text('Kontrol bisnis, akses dan sistem'),
                  ],
                ),
              ),
              const CircleAvatar(child: Icon(Icons.tune_rounded)),
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tabs: const [
            Tab(text: 'Umum'),
            Tab(text: 'NotifHook'),
            Tab(text: 'Akun Uang'),
            Tab(text: 'User & Akses'),
            Tab(text: 'Audit'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _generalTab(),
              _notifHookTab(),
              _accountsTab(),
              _usersTab(),
              _auditTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _generalTab() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Informasi toko', Icons.storefront_outlined),
          const SizedBox(height: 12),
          TextField(
            controller: _businessName,
            decoration: const InputDecoration(labelText: 'Nama bisnis'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Alamat toko'),
          ),
          const SizedBox(height: 20),
          _section('Tampilan aplikasi', Icons.palette_outlined),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Mode gelap'),
                  subtitle: const Text('Preferensi tampilan perangkat'),
                  value: _darkMode,
                  onChanged: (value) => setState(() => _darkMode = value),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.phone_android_outlined),
                  title: Text('Fokus Mobile'),
                  subtitle: Text('Tampilan dioptimalkan untuk layar kasir'),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _section('Template struk', Icons.receipt_long_outlined),
          const SizedBox(height: 12),
          TextField(
            controller: _header,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Header struk'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _footer,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Footer struk'),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _saving ? null : _saveGeneral,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Menyimpan...' : 'Simpan perubahan'),
          ),
        ],
      );

  Widget _notifHookTab() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('NotifHook', Icons.hub_outlined),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Auto-input transaksi'),
                  subtitle: const Text('Terima transaksi dari sumber notifikasi'),
                  value: _autoInput,
                  onChanged: (value) => setState(() => _autoInput = value),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.cloud_done_outlined),
                  title: Text('Status'),
                  subtitle: Text('Terhubung'),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Endpoint webhook',
              hintText: 'https://domain.com/webhook/irkop',
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(labelText: 'API key'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () {},
            icon: const Icon(Icons.refresh),
            label: const Text('Generate ulang API key'),
          ),
          const SizedBox(height: 20),
          _section('Sumber notifikasi', Icons.notifications_active_outlined),
          const SizedBox(height: 10),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(child: Icon(Icons.account_balance)),
                  title: Text('Midtrans'),
                  subtitle: Text('Pembayaran online'),
                  trailing: Text('Aktif'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(child: Icon(Icons.bolt_outlined)),
                  title: Text('Xendit'),
                  subtitle: Text('Payment gateway'),
                  trailing: Text('Aktif'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Tambah sumber'),
          ),
        ],
      );

  Widget _accountsTab() => FutureBuilder<List<MoneyAccount>>(future:_moneyFuture,builder:(context,snapshot)=>ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Akun uang', Icons.account_balance_wallet_outlined),
          const SizedBox(height: 10),
          if(snapshot.connectionState!=ConnectionState.done) const LinearProgressIndicator(),
          if(snapshot.hasError) Text('Gagal memuat akun: '+snapshot.error.toString()),
          Card(child: Column(children: [
            ...snapshot.data?.map((a)=>SwitchListTile(
              secondary: CircleAvatar(child: Icon(a.type=='bank'?Icons.account_balance_outlined:a.type=='ewallet'?Icons.wallet_outlined:Icons.payments_outlined)),
              title: Text(a.name), subtitle: Text(a.type+' • saldo awal '+a.openingBalance.toStringAsFixed(0)),
              value:a.isActive,onChanged:(v)=>_moneyRepository.toggle(id:a.id,businessId:widget.businessContext!.businessId,active:v).then((_)=>_refreshMoneyAccounts()),
            )) ?? const [Padding(padding:EdgeInsets.all(16),child:Text('Belum ada akun uang.'))],
          ])),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed:_addMoneyAccount,icon:const Icon(Icons.add),label:const Text('Tambah akun uang')),
        ],
      ));

  Widget _usersTab() => ListView(padding:const EdgeInsets.all(16),children:[
    _section('User & permission', Icons.admin_panel_settings_outlined),const SizedBox(height:10),
    const Card(child:Column(children:[
      ListTile(leading:CircleAvatar(child:Icon(Icons.admin_panel_settings_outlined)),title:Text('Owner / Admin'),subtitle:Text('Akses penuh seluruh modul'),trailing:Chip(label:Text('Aktif'))),
      Divider(height:1),
      ListTile(leading:CircleAvatar(child:Icon(Icons.point_of_sale_outlined)),title:Text('Kasir'),subtitle:Text('Akses kasir dan transaksi dapat diatur dari manajemen pengguna server.'),trailing:Icon(Icons.lock_outline)),
    ])),
    const SizedBox(height:12),
    const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('Manajemen akun karyawan memerlukan endpoint admin Supabase agar aplikasi klien tidak pernah menyimpan service key.'))),
  ]);

  Widget _auditTab() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Log aktivitas', Icons.history_outlined),
          const SizedBox(height: 12),
          const Card(
            child: Column(
              children: [
                _AuditTile('Admin', 'Mengubah pengaturan bisnis', 'Hari ini • 14:21'),
                Divider(height: 1),
                _AuditTile('Kasir', 'Menyelesaikan transaksi', 'Hari ini • 13:50'),
                Divider(height: 1),
                _AuditTile('Admin', 'Memperbarui produk', 'Hari ini • 11:05'),
                Divider(height: 1),
                _AuditTile('Sistem', 'Sinkronisasi database', 'Hari ini • 09:12'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.filter_alt_outlined),
            label: const Text('Filter log'),
          ),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: () => AuthRepository().signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Keluar dari akun'),
          ),
        ],
      );

  Widget _section(String title, IconData icon) => Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      );
}

class _MoneyTile extends StatelessWidget {
  const _MoneyTile({
    required this.icon,
    required this.name,
    required this.type,
    required this.active,
  });
  final IconData icon;
  final String name;
  final String type;
  final bool active;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(name),
        subtitle: Text(type),
        trailing: Text(
          active ? 'Aktif' : 'Nonaktif',
          style: TextStyle(
            color: active ? Colors.green : Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _AuditTile extends StatelessWidget {
  const _AuditTile(this.user, this.action, this.time);
  final String user;
  final String action;
  final String time;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(action, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('$user • $time'),
        trailing: const Icon(Icons.chevron_right),
      );
}
