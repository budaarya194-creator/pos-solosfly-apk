# POS Kasir Solosfly (Receipt Maker, PDF Exporter & Financial Analytics)

Aplikasi Android POS Kasir lengkap yang dibangun menggunakan **Flutter** dan **Dart**, didukung oleh penyimpanan lokal SQLite (`sqflite`), ekspor dokumen struk thermal 80mm standar (`pdf` & `printing`), serta visualisasi grafik analitik finansial interaktif (`fl_chart`).

---

## Fitur Utama (4 Menu Navigasi)

### 1. Tab Kasir & Edit Struk
- **Input Item Dinamis:** Nama barang, kuantitas (Qty), Harga Modal (HPP), dan Harga Jual per unit.
- **Pemisahan HPP & Harga Jual:** Harga Modal (HPP) digunakan khusus untuk kalkulasi laba/rugi di grafik & laporan analitik, **TIDAK PERNAH** ditampilkan atau dicetak pada struk fisik.
- **Katalog Terintegrasi:** Pilih barang dari katalog master tersimpan atau ketik langsung produk baru.
- **Full Editable Struk:** Logo toko, header toko, kontak, nomor transaksi, nama kasir, nama pelanggan, daftar item, metode pembayaran, hingga footer struk dapat disesuaikan bebas.
- **Auto-Save Template Toko:** Logo toko, nama toko, alamat, nomor HP, dan footer struk otomatis tersimpan permanen di HP tanpa perlu mengetik ulang pada transaksi berikutnya.
- **Kalkulasi Otomatis & Override:** Subtotal per item, total item(s), total kuantitas, diskon, total nominal, dan kembalian dihitung secara instan.
- **Tombol Cepat:** "Set Waktu Sekarang" & "Auto-Generate No. Transaksi" (`TRX-yyMMddHHmmss`).

### 2. Tab Preview Struk & PDF
- **Pratinjau Real-Time:** Tampilan struk thermal roll 80mm persis dengan hasil cetak fisik (latar putih bersih, teks hitam kontras, garis putus-putus horizontal).
- **Generator PDF 80mm Roll:** Dokumen PDF ukuran roll 80mm dengan tinggi dinamis mengikuti konten.
- **Opsi Ekspor:**
  - Simpan / Download file `.pdf` langsung ke penyimpanan HP.
  - Share PDF via WhatsApp / Email.
  - Cetak langsung ke Thermal Printer Bluetooth / USB via Android Print Service.

### 3. Tab Laporan & Grafik Keuangan
- **Filter Rentang Waktu:** 1 Hari (Hari Ini), 1 Minggu, 1 Bulan, 1 Tahun, dan Custom Rentang Tanggal (`DateRangePicker`).
- **Kartu Metrik Finansial:**
  - Total Penjualan (Omzet): $\sum (\text{Harga Jual} \times \text{Qty})$
  - Total Modal (HPP): $\sum (\text{Harga Modal} \times \text{Qty})$
  - Laba Kotor (Gross Profit): $\text{Omzet} - \text{HPP}$
  - Biaya Operasional / Pengeluaran Lain: Input nominal manual per periode.
  - Laba Bersih (Net Profit): $\text{Laba Kotor} - \text{Biaya Operasional}$
  - Total Transaksi & Total Unit Barang Terjual.
- **Grafik Interaktif (`fl_chart`):**
  - Mode Bar Chart (Grouped Bars) dan Line Chart.
  - Komparasi visual Omzet vs Laba Kotor vs Laba Bersih.
  - Legenda warna & tooltip interaktif saat titik grafik disentuh.

### 4. Tab Riwayat & Katalog Produk
- **Master Data Produk:** Tambah, edit, dan hapus data master produk (Nama, HPP Default, Harga Jual Default, Stok). Fitur 1-klik tambah ke kasir.
- **Riwayat Transaksi:** Daftar seluruh transaksi yang tersimpan. Pengguna dapat membuka kembali transaksi untuk diedit ulang di kasir, mencetak ulang struk PDF, atau menghapus transaksi.

---

## Struktur Folder Project

```
pos-solosfly-apk/
├── .github/
│   └── workflows/
│       └── build-apk.yml       # GitHub Actions automated APK build & Release
├── android/                    # Android native configuration & launcher icons
├── assets/
│   └── images/
│       └── solosfly_logo.png   # Solosfly Brand Logo
├── lib/
│   ├── database/
│   │   └── database_helper.dart # SQLite local database manager
│   ├── models/
│   │   ├── expense_record.dart
│   │   ├── product_item.dart
│   │   ├── receipt_item.dart
│   │   ├── store_profile.dart
│   │   └── transaction_record.dart
│   ├── providers/
│   │   └── pos_provider.dart    # State management & calculations
│   ├── services/
│   │   ├── currency_format.dart # Indonesian currency formatting
│   │   └── pdf_receipt_service.dart # PDF 80mm roll generator
│   ├── views/
│   │   ├── home_screen.dart     # Bottom navigation with 4 tabs
│   │   ├── kasir/
│   │   │   └── kasir_screen.dart
│   │   ├── preview/
│   │   │   └── preview_screen.dart
│   │   ├── laporan/
│   │   │   └── laporan_screen.dart
│   │   └── katalog/
│   │       └── katalog_screen.dart
│   └── main.dart
└── pubspec.yaml
```

---

## Build & CI/CD Otomatis

Aplikasi ini menggunakan GitHub Actions (`.github/workflows/build-apk.yml`) untuk membangun file APK release secara otomatis pada setiap push ke branch `main` / `master`.
File APK hasil build dapat diunduh langsung melalui tab **Releases** atau **Artifacts** di repositori GitHub ini.
