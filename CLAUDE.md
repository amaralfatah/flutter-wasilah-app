# Wasilah App

App portofolio pribadi, offline-first. Drift (SQLite) adalah satu-satunya penyimpanan; backup via Google Drive (appdata) + ekspor manual via share_plus.

## Stack & dependencies

Rujukan kanonik: `C:\Users\AmarAlFatah\OneDrive - PT Perkebunan Nusantara III (Persero)\My Flutter Stack\STACK_PERSONAL.md`

## Perintah

- Codegen: `dart run build_runner build --force-jit` (tanpa `--force-jit` gagal: konflik build hooks di Dart 3.10)
- Lint: `flutter analyze` — memakai `very_good_analysis`; `public_member_api_docs` dan `sort_pub_dependencies` sengaja dimatikan
- Test: `flutter test`

## Arsitektur

- `lib/features/<feature>/{data,providers,presentation}` — feature baru = copy pola feature yang ada
- UI baca drift via stream/future provider; repository langsung tulis-baca drift tanpa DTO/mapper
- Database memakai raw SQL (`customStatement`), bukan drift Table codegen — konsisten dengan itu sampai diputuskan migrasi
