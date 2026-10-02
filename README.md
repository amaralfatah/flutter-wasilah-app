# Wasilah

Aplikasi pelacak portofolio investasi pribadi, offline-first.

## Fitur

- Dashboard ringkasan nilai, modal, dan alokasi portofolio
- Master aset dan holding per kategori (saham, reksa dana, kripto, kas, dll.)
- Catat nilai aset per bulan, termasuk nilai pasar otomatis dari Yahoo Finance
- Histori nilai portofolio bulanan beserta grafiknya
- Target alokasi per kategori
- Backup dan restore database ke Google Drive (folder appdata)
- Bahasa Indonesia dan Inggris

## Arsitektur singkat

- Penyimpanan tunggal: SQLite via drift (raw SQL)
- State: Riverpod; navigasi: go_router
- Struktur per fitur: `lib/features/<feature>/{data,providers,presentation}`

## Pengembangan

```bash
flutter pub get
dart run build_runner build --force-jit
flutter analyze
flutter test
flutter run
```

Lihat `CLAUDE.md` untuk konvensi proyek dan perintah regenerasi ikon/splash.
