# IRKOP Konter — Project TODO & Handover

> **Dokumen utama untuk developer/team berikutnya.**
>
> Jangan menganggap modul selesai hanya karena halaman sudah tampil. Status dibagi menjadi:
>
> - **[x] SELESAI KODE** = modul/file sudah dibuat dan terhubung.
> - **[~] PERLU QA** = perlu diuji langsung pada Web/Android/Supabase.
> - **[ ] BELUM** = belum selesai atau belum ada implementasi penuh.

## 1. Mulai dari sini

Urutan kerja untuk team baru:

1. Baca file ini sampai bagian **Prioritas Berikutnya**.
2. Baca `README.md`.
3. Periksa `flutter_app/lib/src/shared/app_page_index.dart` sebelum mengubah navigasi.
4. Semua perubahan database masuk ke **migration baru** di `supabase/migrations/`; jangan mengedit migration lama yang sudah pernah diterapkan.
5. Jalankan validasi proyek melalui **satu entry point**: `fix/finalize.sh`.
6. Push ke `master`; GitHub Actions akan menjalankan preflight, analyze, test bila tersedia, build Web, lalu deploy GitHub Pages.
7. Setelah deploy, cek **BUILD_COMMIT.txt** di hasil build bila perlu memastikan commit terbaru sudah terpublikasi.

## 2. Arsitektur singkat

```
IRKOP Konter
├── flutter_app/                  # Satu codebase Flutter untuk Android + Web
│   └── lib/src/
│       ├── core/                 # auth, env, repository, model
│       ├── features/             # halaman/modul bisnis
│       └── shared/               # UI dan indeks navigasi
├── supabase/
│   ├── migrations/               # seluruh perubahan schema
│   └── seed/                     # data demo
├── fix/finalize.sh               # final project run
└── .github/workflows/pages.yml   # CI + GitHub Pages
```

## 3. Status modul

| Modul | Status | Catatan |
|---|---|---|
| Auth / Login | [x] | AuthGate, LoginPage, AuthRepository tersedia |
| Bootstrap bisnis | [x] | BusinessContextRepository + retry/error state |
| Dashboard / Beranda | [x] | HomePage tersedia |
| Kasir / POS | [x] | CashierPage tersedia |
| Transaksi | [x] | TransactionsPage tersedia |
| Produk | [x] | ProductsPage tersedia |
| Pelanggan | [x] | CustomersPage tersedia |
| Kasbon / Piutang | [x] | CreditsPage + repository tersedia |
| Pengeluaran | [x] | ExpensesPage + migration/repository tersedia |
| Gaji Karyawan | [x] | PayrollPage + repository + migration tersedia |
| Service HP | [x] | ServicePage + repository + migration tersedia |
| Outlet | [x] | OutletsPage + repository tersedia |
| Perangkat | [x] | DevicesPage + repository tersedia |
| Laporan | [x] | ReportsPage tersedia |
| Pengaturan | [x] | SettingsPage + business settings repository tersedia |
| Navigasi Menu/Lainnya | [x] | Menggunakan `AppPageIndex` sebagai sumber indeks |
| Demo mode | [x] | DemoStore tersedia |
| Web deployment | [x] | GitHub Actions + GitHub Pages artifact |
| Android native | [~] | Codebase Flutter sama, perlu QA build/install perangkat |
| Offline-first/sinkronisasi penuh | [ ] | Belum ada status implementasi penuh yang terdokumentasi |
| Lisensi/subscription penuh | [ ] | Masih arah/scope, belum ditutup sebagai fitur final |
| Test otomatis modul | [ ] | Belum ada test Flutter yang terlihat di repository |

## 4. Database & migration

Migration saat ini mencakup:

- tenant/demo/RLS awal
- perbaikan owner/outlet RLS
- penyelarasan schema fitur Web
- `outlets.is_active`
- penyelarasan schema lengkap
- perbaikan schema outlet aktif
- perbaikan foreign key hapus pelanggan
- pengeluaran
- business settings
- schema IRKOP Cell awal
- modul Service HP, Gaji, dan akun uang

**Aturan penting:**

- Jangan membuat kode Flutter memakai kolom baru tanpa migration yang sama-sama ditambahkan.
- Jangan mengandalkan schema cache Supabase lama setelah perubahan kolom.
- Setelah migration baru ditambahkan, pastikan urutan migration valid dari database kosong maupun database existing.
- Sebelum menyatakan bug database selesai, verifikasi migration benar-benar sudah diterapkan ke project Supabase target.

## 5. Navigasi

Sumber indeks tunggal:

`flutter_app/lib/src/shared/app_page_index.dart`

Saat menambah halaman:

1. Tambah konstanta indeks di file tersebut.
2. Tambah halaman ke daftar halaman utama.
3. Tambah item menu bila diperlukan.
4. Jangan memakai angka indeks hardcode di menu.
5. Pastikan route/menu membuka halaman yang benar di Web dan mobile.

## 6. Validasi sebelum commit

Gunakan:

```bash
cd flutter_app
bash ../fix/finalize.sh
```

Script ini menjalankan:

- preflight
- dependency install
- static analysis
- test jika test tersedia
- release web build
- cache bust deployment
- pengecekan output akhir

**Target akhir:** jangan hanya commit. Periksa juga GitHub Actions sampai status hijau dan cek hasil deploy.

## 7. Checklist QA manual

Setiap perubahan besar wajib cek:

- [ ] Login/logout
- [ ] Bootstrap bisnis baru
- [ ] Tambah/pilih outlet
- [ ] Toggle status outlet
- [ ] Dashboard
- [ ] Kasir: cari produk, tambah keranjang, ubah jumlah, bayar
- [ ] Transaksi
- [ ] Produk CRUD
- [ ] Pelanggan CRUD dan data yang masih direferensikan transaksi
- [ ] Kasbon: buat, bayar, status
- [ ] Pengeluaran CRUD
- [ ] Gaji Karyawan
- [ ] Service HP
- [ ] Perangkat
- [ ] Laporan
- [ ] Pengaturan
- [ ] Refresh Web setelah deploy
- [ ] Mobile viewport tidak blank/overflow
- [ ] GitHub Actions hijau
- [ ] Supabase migration berhasil diterapkan

## 8. Prioritas berikutnya

### P0 — Wajib sebelum disebut final

- [~] QA semua modul terhadap Supabase production/staging.
- [~] Pastikan seluruh migration benar-benar diterapkan pada database target.
- [ ] Tambahkan automated test minimal untuk repository dan navigasi utama.
- [ ] Tambahkan smoke test untuk semua menu agar halaman blank/routing salah cepat terdeteksi.
- [~] QA Web GitHub Pages setelah setiap perubahan besar.
- [~] QA Android build/install native.

### P1 — Parity fitur

Bandingkan satu per satu dengan referensi IRKOP Cell:

- [ ] Dashboard
- [ ] Kasir/POS
- [ ] Keranjang & pembayaran
- [ ] Riwayat transaksi
- [ ] Produk/kategori/stok
- [ ] Pelanggan
- [ ] Kasbon/piutang
- [ ] Pengeluaran
- [ ] Gaji
- [ ] Service HP
- [ ] Laporan
- [ ] Pengaturan

Tandai item hanya setelah perilaku, bukan sekadar tampilan, sudah setara.

### P2 — Kualitas

- [ ] Empty state yang konsisten
- [ ] Error state yang ramah pengguna
- [ ] Loading state yang konsisten
- [ ] Validasi form
- [ ] Konfirmasi hapus untuk data berelasi
- [ ] Dokumentasi offline/sinkronisasi
- [ ] Dokumentasi lisensi/perangkat bila scope dilanjutkan

## 9. Catatan masalah historis

Masalah yang pernah muncul:

- Kolom `irkop_cell_outlets.is_active` belum tersedia di database.
- Schema cache Supabase masih membaca kolom lama.
- Routing menu pernah memakai indeks halaman yang salah sehingga Pengeluaran blank.
- Penghapusan pelanggan pernah tertahan foreign key transaksi.

Jangan menghapus catatan ini sampai ada automated regression test yang menutup kasus tersebut.

## 10. Definisi selesai

Sebuah task baru boleh dipindah ke **SELESAI** bila:

- kode selesai
- migration tersedia bila ada perubahan database
- `fix/finalize.sh` lolos
- GitHub Actions hijau
- deploy terbaru sudah terlihat
- QA manual fitur terkait lolos
- tidak ada error database/runtime yang diketahui

---

**Update dokumen ini pada setiap perubahan scope besar.**
Jika ada developer baru, mulai dari bagian **1 → 3 → 8**.