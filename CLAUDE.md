# Sararia Portfolio (codename Pakaya, paket `flutter_wasilah_app`)

App portofolio pribadi, offline-first. Drift (SQLite) adalah satu-satunya penyimpanan; backup via Google Drive (appdata).

## Stack & dependencies

Rujukan kanonik: `C:\Users\AmarAlFatah\OneDrive - PT Perkebunan Nusantara III (Persero)\My Flutter Stack\STACK_PERSONAL.md`

## Perintah

- Codegen: `dart run build_runner build --force-jit` (tanpa `--force-jit` gagal: konflik build hooks di Dart 3.10)
- Lint: `flutter analyze` — memakai `very_good_analysis`; `public_member_api_docs` dan `sort_pub_dependencies` sengaja dimatikan
- Test: `flutter test`
- Ikon launcher: diturunkan dari ikon keluarga Sararia (`next-sararia`, warna di `scripts/app-icons.mjs` lalu `npm run icons`) ke `assets/icon/icon*.png`, lalu `dart run flutter_launcher_icons`
- Splash (setelah `assets/icon/logo-pakaya-light.png` berubah): `dart run tool/prepare_icons.dart` →
  `dart run flutter_native_splash:create --path=flutter_native_splash.yaml`

## Arsitektur

- `lib/features/<feature>/{data,providers,presentation}` — feature baru = copy pola feature yang ada
- UI baca drift via stream/future provider; repository langsung tulis-baca drift tanpa DTO/mapper
- Database memakai raw SQL (`customStatement`), bukan drift Table codegen — konsisten dengan itu sampai diputuskan migrasi
