# Wasilah Material Completion And Offline-First Design

## Goal

Menuntaskan penyelarasan layar utama terhadap pola Material 3 yang relevan dan mengganti sumber data aplikasi dari mock in-memory menjadi penyimpanan lokal permanen berbasis Drift + SQLite.

## Scope

In scope:

- penyempurnaan pola Material 3 yang masih tersisa pada modul Beranda, Histori, Aset, Target, dan Setelan
- pengenalan database lokal Drift + SQLite
- seed data awal untuk first launch
- migrasi repository aplikasi ke data source lokal
- pengujian persistence dan perilaku update data

Out of scope:

- sinkronisasi server
- autentikasi
- konflik multi-device
- perubahan besar pada domain model atau struktur halaman

## Approach Options

### Option 1: Replace mock repository with local JSON file storage

Kelebihan:

- implementasi cepat
- tanpa code generation

Kekurangan:

- query agregasi dan histori lebih rapuh
- tidak mengikuti requirement Drift + SQLite
- kurang baik untuk evolusi schema

### Option 2: Replace mock repository with Drift as the primary local source

Kelebihan:

- sesuai requirement
- data tersimpan permanen dan bisa diquery secara relasional
- mudah mengelola histori, alokasi, dan seed awal
- tetap cocok dengan struktur provider sekarang

Kekurangan:

- perlu setup dependency dan code generation

### Option 3: Hybrid remote-first with local cache

Kelebihan:

- cocok untuk produk online

Kekurangan:

- menambah kompleksitas yang belum dibutuhkan
- tidak ada backend aktif di project ini

## Recommendation

Pilih Option 2. App ini saat ini belum punya backend aktif, jadi implementasi offline-first yang paling jujur adalah menjadikan database lokal sebagai source of truth. UI dan provider tetap dipertahankan agar perubahan tetap fokus dan aman.

## Architecture

### Data Layer

Tambahkan `AppDatabase` berbasis Drift dengan tiga tabel:

- `assets`
- `asset_snapshots`
- `allocation_targets`

Database dibuka dari file SQLite lokal menggunakan `LazyDatabase` dan `NativeDatabase.createInBackground`.

### Repository

Tambahkan `DriftPortfolioRepository` yang mengimplementasikan `PortfolioRepository`.

Repository akan:

- memastikan seed data hanya dijalankan sekali saat tabel masih kosong
- membaca aset, histori, target, dan ringkasan langsung dari SQLite
- menulis update nilai aset ke tabel aset dan histori
- menghitung ulang alokasi setelah setiap perubahan

### App Wiring

`portfolioRepositoryProvider` tidak lagi membuat `MockPortfolioRepository` sebagai default. Provider akan membaca `AppDatabase` dan membuat `DriftPortfolioRepository`.

Mock repository tetap boleh ada untuk test tertentu, tetapi aplikasi runtime memakai database lokal.

### Material 3 Completion

Penyelarasan Material yang tersisa difokuskan pada pola yang paling jelas:

- top-level content dapat di-refresh secara native dengan pull-to-refresh
- status alokasi target memakai komponen Material `Chip`
- halaman Setelan memakai alur `AboutListTile`

## Error Handling

- jika database gagal dibuka, exception dibiarkan naik sehingga error state provider tetap bekerja
- update nilai aset tetap melempar error validasi yang sudah ada

## Testing Strategy

- widget tests untuk standar Material yang disentuh
- repository tests untuk update nilai aset
- repository tests untuk persistence lintas reopen database
- verifikasi akhir dengan `flutter analyze` dan `flutter test`

## Acceptance Criteria

1. Lima modul utama memakai pola Material 3 yang lebih konsisten pada area yang disentuh.
2. Data portofolio tidak hilang saat app restart karena tersimpan di SQLite.
3. Seed data awal hanya dibuat saat database kosong.
4. Update nilai aset memperbarui aset, histori aset, histori portofolio, dan alokasi secara permanen.
5. Aplikasi runtime tidak lagi bergantung pada mock repository sebagai sumber data default.
