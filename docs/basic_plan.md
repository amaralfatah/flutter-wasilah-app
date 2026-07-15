Saya sedang membangun aplikasi Flutter bernama **Wasilah**, yaitu aplikasi personal portfolio tracker untuk mencatat dan memantau total nilai aset secara berkala.

Aplikasi ini bukan aplikasi trading dan tidak mencatat transaksi pembelian atau penjualan. Pengguna hanya memperbarui total nilai setiap aset pada tanggal tertentu.

Contoh:

```text
Aset: Bitcoin
Total nilai aset: Rp1.000.000
Tanggal pencatatan: 15 Juli 2026
```

Data tersebut berarti:

```text
Pada tanggal 15 Juli 2026, seluruh kepemilikan Bitcoin pengguna memiliki nilai total Rp1.000.000.
```

Bangun pondasi awal aplikasi Flutter yang:

- Menggunakan Material Design 3.
- Memiliki tampilan modern ala aplikasi Google.
- Menggunakan arsitektur feature-first yang sederhana.
- Tidak menggunakan Clean Architecture berlapis secara berlebihan.
- Mudah dipahami oleh satu developer atau tim kecil.
- Mudah diuji dan dikembangkan.
- Siap terhubung ke REST API pada tahap berikutnya.
- Tidak membuat abstraksi yang belum diperlukan.
- Tidak menambahkan dependency baru kecuali benar-benar dibutuhkan.

## Dependency yang tersedia

Gunakan dependency yang sudah tersedia pada `pubspec.yaml` berikut:

```yaml
dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.6.1
  go_router: ^17.3.0
  dio: ^5.10.0
  retrofit: ^4.9.2
  freezed_annotation: ^3.1.0
  json_annotation: ^4.12.0
  flutter_secure_storage: ^10.3.1
  shared_preferences: ^2.5.5
  firebase_core: ^4.11.0
  firebase_crashlytics: ^5.2.4

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^6.0.0
  build_runner: ^2.15.1
  freezed: ^3.2.5
  json_serializable: ^6.14.0
  retrofit_generator: ^10.2.7
```

Gunakan Dart SDK:

```yaml
environment:
  sdk: ^3.10.3
```

Jangan mengubah versi dependency yang sudah ada.

---

# Prinsip Arsitektur

Gunakan pendekatan:

```text
Feature-first pragmatic architecture
```

Jangan langsung menggunakan struktur lengkap seperti:

```text
data/
domain/
presentation/
usecases/
entities/
repositories/
```

pada setiap fitur.

Struktur tersebut baru diperlukan apabila aplikasi sudah memiliki business logic kompleks, banyak sumber data, kebutuhan offline-first, atau tim yang besar.

Untuk tahap awal, cukup pisahkan:

- halaman,
- widget fitur,
- model,
- provider,
- repository,
- service global.

Gunakan repository hanya pada area yang benar-benar berhubungan dengan data.

Gunakan satu repository utama untuk seluruh fitur portofolio karena dashboard, aset, histori, dan update nilai aset menggunakan data yang saling berkaitan.

---

# Struktur Folder

Gunakan struktur berikut:

```text
lib/
├── app/
│   ├── app.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   └── route_names.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── app_colors.dart
│       ├── app_spacing.dart
│       └── app_radius.dart
│
├── core/
│   ├── network/
│   │   ├── dio_provider.dart
│   │   ├── api_constants.dart
│   │   ├── api_exception.dart
│   │   └── api_interceptor.dart
│   ├── storage/
│   │   ├── secure_storage_service.dart
│   │   └── preferences_service.dart
│   ├── utils/
│   │   ├── currency_formatter.dart
│   │   ├── date_formatter.dart
│   │   └── validators.dart
│   └── widgets/
│       ├── app_card.dart
│       ├── app_primary_button.dart
│       ├── app_text_field.dart
│       ├── app_loading.dart
│       ├── app_error_view.dart
│       ├── app_empty_state.dart
│       ├── async_value_view.dart
│       └── section_header.dart
│
├── features/
│   ├── portfolio/
│   │   ├── models/
│   │   │   ├── asset.dart
│   │   │   ├── asset_snapshot.dart
│   │   │   ├── portfolio_summary.dart
│   │   │   └── allocation_target.dart
│   │   ├── repository/
│   │   │   ├── portfolio_repository.dart
│   │   │   └── mock_portfolio_repository.dart
│   │   ├── providers/
│   │   │   ├── portfolio_providers.dart
│   │   │   └── update_asset_value_controller.dart
│   │   ├── pages/
│   │   │   ├── dashboard_page.dart
│   │   │   ├── asset_list_page.dart
│   │   │   ├── asset_detail_page.dart
│   │   │   ├── update_asset_value_page.dart
│   │   │   └── portfolio_history_page.dart
│   │   └── widgets/
│   │       ├── portfolio_summary_card.dart
│   │       ├── target_progress_card.dart
│   │       ├── asset_list_item.dart
│   │       ├── asset_category_icon.dart
│   │       ├── allocation_badge.dart
│   │       └── portfolio_insight_card.dart
│   │
│   ├── target/
│   │   ├── pages/
│   │   │   └── target_page.dart
│   │   ├── providers/
│   │   │   └── target_providers.dart
│   │   └── widgets/
│   │       └── target_allocation_item.dart
│   │
│   └── settings/
│       ├── pages/
│       │   └── settings_page.dart
│       └── providers/
│           └── theme_mode_provider.dart
│
├── bootstrap.dart
└── main.dart
```

Aturan struktur:

1. Jangan membuat file kosong hanya untuk mengikuti struktur.
2. Buat file hanya jika memang digunakan.
3. Jangan membuat interface repository untuk setiap halaman.
4. Jangan membuat use case class yang hanya meneruskan pemanggilan repository.
5. Jangan membuat mapper terpisah apabila model API dan model UI masih sama.
6. Jangan memecah widget terlalu kecil tanpa manfaat yang jelas.
7. Pisahkan widget ketika digunakan ulang atau ketika halaman sudah sulit dibaca.

---

# Material Design 3

Gunakan:

```dart
useMaterial3: true
```

Buat warna dari seed berikut:

```dart
const seedColor = Color(0xFF0B57D0);
```

Gunakan:

```dart
ColorScheme.fromSeed(
  seedColor: seedColor,
  brightness: Brightness.light,
)
```

dan dark color scheme:

```dart
ColorScheme.fromSeed(
  seedColor: seedColor,
  brightness: Brightness.dark,
)
```

Jangan menggunakan warna hardcoded langsung di halaman, kecuali warna tersebut didefinisikan sebagai semantic color pada `AppColors`.

Semua halaman harus mengambil warna utama dari:

```dart
Theme.of(context).colorScheme
```

Gaya desain:

- Bersih dan ringan seperti aplikasi Google.
- Menggunakan banyak whitespace.
- Border seminimal mungkin.
- Tidak menggunakan border hitam tebal.
- Menggunakan tonal card.
- Menggunakan elevation ringan.
- Menggunakan radius yang konsisten.
- Menggunakan `NavigationBar`, bukan `BottomNavigationBar`.
- Menggunakan `FilledButton`, `FilledButton.tonal`, atau reusable button berbasis Material 3.
- Menggunakan `Card`, `Container`, dan `ListTile` secara proporsional.
- Tidak menambahkan package font eksternal.
- Gunakan typography bawaan Material 3.

---

# Design Tokens

## Spacing

Buat konstanta pada `app_spacing.dart`:

```dart
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}
```

## Radius

Buat konstanta pada `app_radius.dart`:

```dart
abstract final class AppRadius {
  static const double small = 12;
  static const double medium = 16;
  static const double large = 24;
  static const double extraLarge = 32;
}
```

## Semantic Colors

Buat warna tambahan pada `app_colors.dart` hanya untuk kebutuhan semantic:

```dart
abstract final class AppColors {
  static const Color seed = Color(0xFF0B57D0);
  static const Color positive = Color(0xFF137333);
  static const Color negative = Color(0xFFC5221F);
  static const Color warning = Color(0xFFB06000);
}
```

Gunakan semantic color tersebut hanya untuk:

- pertumbuhan positif,
- penurunan,
- warning,
- insight khusus.

Untuk background, surface, text, border, dan primary action tetap gunakan `ColorScheme`.

---

# Typography

Gunakan typography Material 3.

Panduan:

- `headlineSmall`: judul halaman.
- `titleLarge`: nilai utama atau judul hero card.
- `titleMedium`: judul section.
- `bodyLarge`: informasi penting.
- `bodyMedium`: isi utama.
- `bodySmall`: helper text.
- `labelLarge`: tombol.
- `labelMedium`: chip atau badge.

Jangan menggunakan ukuran font hardcoded secara berlebihan.

---

# Navigasi

Gunakan `go_router`.

Gunakan `StatefulShellRoute.indexedStack` agar state pada setiap tab tetap dipertahankan.

Bottom navigation memiliki lima menu:

1. Beranda
2. Histori
3. Aset
4. Target
5. Setelan

Gunakan route berikut:

```text
/dashboard
/history
/assets
/assets/:id
/assets/:id/update
/target
/settings
```

Gunakan `NavigationBar` Material 3.

Ikon:

```dart
Icons.home_outlined
Icons.history_outlined
Icons.account_balance_wallet_outlined
Icons.flag_outlined
Icons.settings_outlined
```

Ikon aktif:

```dart
Icons.home
Icons.history
Icons.account_balance_wallet
Icons.flag
Icons.settings
```

Halaman update nilai aset dapat dibuka dari:

- tombol pada dashboard,
- item pada halaman aset,
- halaman detail aset.

---

# Model Data

Gunakan Freezed hanya untuk model yang:

- berasal dari JSON,
- memerlukan `copyWith`,
- membutuhkan equality,
- kemungkinan digunakan oleh API.

Jangan menggunakan Freezed untuk class UI kecil, konstanta, atau helper sederhana.

## AssetCategory

Gunakan enum biasa:

```dart
enum AssetCategory {
  crypto,
  stock,
  mutualFund,
  cash,
  other,
}
```

Tambahkan extension untuk label:

```dart
extension AssetCategoryX on AssetCategory {
  String get label {
    switch (this) {
      case AssetCategory.crypto:
        return 'Kripto';
      case AssetCategory.stock:
        return 'Saham';
      case AssetCategory.mutualFund:
        return 'Reksa Dana';
      case AssetCategory.cash:
        return 'Kas';
      case AssetCategory.other:
        return 'Lainnya';
    }
  }
}
```

## Asset

Gunakan Freezed:

```dart
@freezed
class Asset with _$Asset {
  const factory Asset({
    required String id,
    required String name,
    required String code,
    required AssetCategory category,
    required double currentValue,
    required double allocationPercentage,
    required DateTime lastUpdatedAt,
  }) = _Asset;

  factory Asset.fromJson(Map<String, dynamic> json) =>
      _$AssetFromJson(json);
}
```

## AssetSnapshot

```dart
@freezed
class AssetSnapshot with _$AssetSnapshot {
  const factory AssetSnapshot({
    required String id,
    required String assetId,
    required double totalValue,
    required DateTime recordedAt,
    String? note,
  }) = _AssetSnapshot;

  factory AssetSnapshot.fromJson(Map<String, dynamic> json) =>
      _$AssetSnapshotFromJson(json);
}
```

## PortfolioSummary

```dart
@freezed
class PortfolioSummary with _$PortfolioSummary {
  const factory PortfolioSummary({
    required double totalValue,
    required double monthlyChangePercentage,
    required double targetProgressPercentage,
    required List<Asset> assets,
    required DateTime lastUpdatedAt,
  }) = _PortfolioSummary;

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) =>
      _$PortfolioSummaryFromJson(json);
}
```

## AllocationTarget

```dart
@freezed
class AllocationTarget with _$AllocationTarget {
  const factory AllocationTarget({
    required String id,
    required AssetCategory category,
    required double targetPercentage,
    required int targetYear,
  }) = _AllocationTarget;

  factory AllocationTarget.fromJson(Map<String, dynamic> json) =>
      _$AllocationTargetFromJson(json);
}
```

---

# Repository

Gunakan satu repository utama untuk fitur portofolio.

Buat interface berikut:

```dart
abstract interface class PortfolioRepository {
  Future<PortfolioSummary> getPortfolioSummary();

  Future<List<Asset>> getAssets();

  Future<Asset?> getAssetById(String assetId);

  Future<List<AssetSnapshot>> getPortfolioHistory();

  Future<List<AssetSnapshot>> getAssetHistory(String assetId);

  Future<void> updateAssetValue({
    required String assetId,
    required double totalValue,
    required DateTime recordedAt,
    String? note,
  });

  Future<List<AllocationTarget>> getAllocationTargets();
}
```

Buat implementasi awal:

```text
MockPortfolioRepository
```

Ketentuan mock repository:

- Data disimpan dalam memory.
- Tidak membutuhkan database lokal.
- Memiliki delay kecil agar loading state dapat terlihat.
- Saat `updateAssetValue` dipanggil:
  - nilai aset terbaru diperbarui,
  - `lastUpdatedAt` diperbarui,
  - snapshot baru ditambahkan,
  - persentase alokasi seluruh aset dihitung ulang,
  - total portofolio dihitung ulang.

- Jangan membuat repository terpisah untuk dashboard, histori, aset, dan target.
- Struktur repository harus mudah diganti dengan implementasi API di masa depan.

---

# Riverpod

Gunakan Riverpod secara sederhana dan sesuai kebutuhan.

## Provider Repository

```dart
final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return MockPortfolioRepository();
});
```

Pastikan repository mock tidak dibuat ulang setiap rebuild.

## Provider Data Read-Only

Gunakan `FutureProvider` untuk data yang hanya dibaca:

```dart
final portfolioSummaryProvider =
    FutureProvider<PortfolioSummary>((ref) async {
  final repository = ref.watch(portfolioRepositoryProvider);
  return repository.getPortfolioSummary();
});
```

Buat provider:

```text
portfolioSummaryProvider
assetListProvider
assetDetailProvider
portfolioHistoryProvider
assetHistoryProvider
allocationTargetProvider
```

Gunakan `.family` hanya jika membutuhkan parameter, misalnya `assetId`.

Contoh:

```dart
final assetDetailProvider =
    FutureProvider.family<Asset?, String>((ref, assetId) async {
  final repository = ref.watch(portfolioRepositoryProvider);
  return repository.getAssetById(assetId);
});
```

## Controller Update Nilai Aset

Gunakan `AsyncNotifier` atau `AutoDisposeAsyncNotifier` hanya untuk proses submit form update nilai aset.

Controller harus:

- menerima input aset,
- total nilai,
- tanggal,
- catatan,
- melakukan validasi,
- memanggil repository,
- mengelola loading dan error,
- melakukan invalidate provider yang relevan setelah berhasil.

Invalidate:

```dart
ref.invalidate(portfolioSummaryProvider);
ref.invalidate(assetListProvider);
ref.invalidate(portfolioHistoryProvider);
ref.invalidate(assetDetailProvider(assetId));
ref.invalidate(assetHistoryProvider(assetId));
```

Jangan membuat provider untuk state UI sederhana seperti:

- index tab lokal,
- controller text field,
- toggle sementara,
- selected chip yang hanya dipakai satu widget.

Gunakan `StatefulWidget`, `ValueNotifier`, atau state lokal untuk kondisi sederhana tersebut.

---

# Main dan Bootstrap

Buat `main.dart` sesederhana mungkin:

```dart
Future<void> main() async {
  await bootstrap();
}
```

Buat `bootstrap.dart` untuk:

1. Memanggil `WidgetsFlutterBinding.ensureInitialized()`.
2. Mencoba menginisialisasi Firebase.
3. Mengaktifkan Crashlytics apabila Firebase tersedia.
4. Mengatur handler error Flutter.
5. Menjalankan aplikasi dalam `ProviderScope`.
6. Tetap menjalankan aplikasi apabila Firebase belum dikonfigurasi.

Ketentuan:

- Jangan biarkan aplikasi gagal startup hanya karena `google-services.json` atau konfigurasi Firebase belum tersedia.
- Pada mode development, tampilkan log dengan `debugPrint`.
- Jangan menambahkan sistem dependency injection tambahan.

---

# Network Layer

Walaupun tahap awal menggunakan mock repository, siapkan pondasi network secara ringan.

## ApiConstants

```dart
abstract final class ApiConstants {
  static const String baseUrl = 'https://example.com/api';
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
```

## Dio Provider

Buat provider Dio:

```dart
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(
    ApiInterceptor(
      secureStorageService: ref.read(secureStorageServiceProvider),
    ),
  );

  return dio;
});
```

Interceptor memiliki tanggung jawab:

- menambahkan token jika tersedia,
- logging sederhana pada debug mode,
- tidak melakukan business logic,
- tidak menampilkan UI.

Buat `ApiException` sederhana untuk:

- connection timeout,
- no internet,
- unauthorized,
- forbidden,
- not found,
- server error,
- unknown error.

Jangan membuat failure hierarchy yang terlalu kompleks.

Retrofit belum perlu digunakan pada mock repository. Namun struktur harus memungkinkan penambahan API service nanti.

---

# Storage

## Secure Storage

Gunakan `flutter_secure_storage` untuk:

- access token,
- refresh token,
- data autentikasi sensitif.

Buat service sederhana:

```dart
abstract interface class SecureStorageService {
  Future<void> writeToken(String token);
  Future<String?> readToken();
  Future<void> deleteToken();
}
```

## Shared Preferences

Gunakan `shared_preferences` untuk:

- theme mode,
- preferensi sederhana,
- flag onboarding.

Buat service sederhana dan provider-nya.

Jangan menyimpan snapshot portofolio ke SharedPreferences.

---

# Reusable Widgets

Buat widget reusable yang benar-benar digunakan.

## AppCard

Parameter:

```dart
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
}
```

Gunakan default:

- radius `AppRadius.large`,
- padding `AppSpacing.lg`,
- background `colorScheme.surfaceContainerLow`,
- elevation rendah atau tanpa elevation.

## AppPrimaryButton

Parameter:

```dart
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
}
```

Gunakan `FilledButton.icon` apabila terdapat ikon.

Saat loading:

- tombol disabled,
- tampilkan `CircularProgressIndicator` kecil,
- ukuran tombol tidak berubah.

## AppTextField

Parameter:

```dart
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int maxLines;
}
```

Gunakan `TextFormField`.

## AsyncValueView

Buat helper generic:

```dart
class AsyncValueView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
}
```

Menangani:

- loading,
- error,
- success.

Jangan menyembunyikan semua error. Tampilkan pesan yang mudah dipahami pengguna.

## SectionHeader

Parameter:

```dart
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
}
```

## State Widgets

Buat:

```text
AppLoading
AppErrorView
AppEmptyState
```

Gunakan komponen tersebut hanya jika digunakan oleh lebih dari satu halaman.

---

# Halaman Utama

## 1. Dashboard

Buat halaman dashboard dengan desain Material 3 ala Google.

### App Bar

Tampilkan:

```text
Wasilah
Selamat datang kembali
```

Tambahkan tombol profil berbentuk lingkaran di kanan.

### Hero Card

Tampilkan:

```text
Total Portofolio
Rp128.400.000
Naik 3,2% bulan ini
```

Gunakan:

- `primaryContainer`,
- text dari `onPrimaryContainer`,
- radius besar,
- tanpa gradient berlebihan,
- tanpa shadow berat.

### Target Progress

Tampilkan:

```text
Target 2028–2029
62%
Alokasi portofolio ideal
```

Gunakan `LinearProgressIndicator`.

### Komposisi Aset

Contoh data:

```text
Bitcoin
Rp42.400.000
33%

BMRI / BBRI
Rp48.800.000
38%

Reksa Dana
Rp21.800.000
17%

Kas
Rp15.400.000
12%
```

Setiap item menampilkan:

- ikon kategori,
- nama aset,
- nilai rupiah,
- persentase alokasi,
- area tap menuju detail aset.

Tambahkan tombol:

```text
Update Nilai Aset
```

Tombol membuka halaman daftar aset atau langsung halaman update dengan pemilihan aset.

### State

Dashboard harus mendukung:

- loading,
- error,
- empty,
- data.

Gunakan `portfolioSummaryProvider`.

---

## 2. Halaman Aset

Tampilkan daftar aset.

Informasi setiap item:

```text
Bitcoin
Kripto
Rp42.400.000
33%
Diperbarui 15 Juli 2026
```

Gunakan `ListView.separated`.

Saat item ditekan, buka:

```text
/assets/:id
```

Tambahkan tombol update pada setiap item atau melalui halaman detail.

Jika tidak ada aset, tampilkan `AppEmptyState`.

---

## 3. Halaman Detail Aset

Tampilkan:

- nama aset,
- kode,
- kategori,
- nilai terkini,
- persentase alokasi,
- tanggal update terakhir,
- histori beberapa snapshot terakhir,
- tombol update nilai aset.

Contoh:

```text
Bitcoin
BTC
Kripto

Nilai saat ini
Rp42.400.000

Alokasi portofolio
33%

Terakhir diperbarui
15 Juli 2026
```

Tombol:

```text
Update Nilai Bitcoin
```

Membuka:

```text
/assets/:id/update
```

---

## 4. Halaman Update Nilai Aset

Halaman ini bukan form transaksi jual-beli.

Tujuan halaman:

```text
Mencatat total nilai seluruh kepemilikan suatu aset pada tanggal tertentu.
```

Field:

1. Pilih aset.
2. Total nilai aset saat ini.
3. Tanggal pencatatan.
4. Catatan opsional.
5. Preview nilai sebelumnya dan nilai terbaru.
6. Tombol simpan.

Contoh:

```text
Jenis aset
Bitcoin

Total nilai aset saat ini
Rp1.000.000

Tanggal pencatatan
15 Juli 2026

Catatan
Nilai Bitcoin bulan Juli
```

Tampilkan helper text:

```text
Masukkan total nilai seluruh kepemilikan aset saat ini, bukan jumlah pembelian atau nilai penambahan aset.
```

Preview:

```text
Nilai sebelumnya
Rp850.000

Nilai terbaru
Rp1.000.000
```

Validasi:

- aset wajib dipilih,
- nilai wajib diisi,
- nilai harus lebih besar atau sama dengan nol,
- tanggal wajib diisi,
- catatan maksimal 200 karakter.

Input nominal:

- gunakan numeric keyboard,
- tampilkan prefix `Rp`,
- format nilai dengan separator ribuan,
- simpan sebagai `double`,
- jangan menyimpan string yang sudah terformat.

Setelah berhasil:

1. Tampilkan `SnackBar`.
2. Invalidate provider terkait.
3. Kembali ke halaman sebelumnya.
4. Pastikan data dashboard dan detail aset ikut diperbarui.

Contoh pesan:

```text
Nilai Bitcoin berhasil diperbarui.
```

---

## 5. Halaman Histori

Tampilkan histori snapshot portofolio secara bulanan.

Contoh:

```text
Juli 2026
Rp128.400.000
Naik 3,5%

Juni 2026
Rp124.100.000
Naik 3,6%

Mei 2026
Rp119.800.000
Naik 4,2%

April 2026
Rp115.000.000
Naik 2,8%
```

Tambahkan filter:

```text
Semua
2026
2025
```

Gunakan `FilterChip` atau `ChoiceChip`.

Filter tahun cukup menggunakan state lokal pada halaman.

Tambahkan insight card:

```text
Alokasi Bitcoin berada 3% di atas target. Pertimbangkan penambahan pada kategori aset lain agar komposisi kembali seimbang.
```

Jangan membuat provider baru hanya untuk selected filter chip.

---

## 6. Halaman Target

Tampilkan target alokasi kategori.

Contoh:

```text
Kripto
Target 35%
Aktual 33%

Saham
Target 40%
Aktual 38%

Reksa Dana
Target 15%
Aktual 17%

Kas
Target 10%
Aktual 12%
```

Gunakan progress indicator atau perbandingan angka.

Tampilkan status:

```text
Sesuai target
Di bawah target
Di atas target
```

Gunakan warna semantic secara lembut.

Tahap awal hanya read-only. Jangan membuat form edit target kecuali memang diperlukan.

---

## 7. Halaman Setelan

Tampilkan:

- Theme mode.
- Tentang aplikasi.
- Versi aplikasi.
- Placeholder backup Google Drive.
- Placeholder logout apabila autentikasi belum dibuat.

Theme mode:

```text
Ikuti sistem
Terang
Gelap
```

Gunakan Riverpod untuk `themeModeProvider`.

Simpan theme mode ke SharedPreferences.

---

# Format Data

Buat formatter:

## Currency Formatter

Contoh hasil:

```text
Rp1.000.000
Rp42.400.000
Rp128,4 juta
```

Buat dua fungsi:

```dart
String formatCurrency(double value);
String formatCompactCurrency(double value);
```

Prioritaskan implementasi sederhana tanpa dependency tambahan.

## Date Formatter

Contoh:

```text
15 Juli 2026
Juli 2026
```

Buat:

```dart
String formatFullDate(DateTime date);
String formatMonthYear(DateTime date);
```

Gunakan daftar nama bulan Indonesia secara manual agar tidak perlu menambah package `intl`.

---

# Error Handling

Gunakan pendekatan sederhana.

Repository melempar:

```dart
ApiException
```

UI menampilkan pesan melalui `AsyncValue`.

Contoh pesan pengguna:

```text
Data belum dapat dimuat.
Periksa koneksi Anda dan coba kembali.
```

Jangan menampilkan stack trace atau pesan Dio mentah.

Saat submit gagal, tampilkan `SnackBar`.

---

# Testing

Buat minimal test berikut:

1. Unit test formatter mata uang.
2. Unit test mock repository update nilai aset.
3. Widget test dashboard menampilkan total portofolio.
4. Widget test validasi form update nilai aset.

Jangan membuat test berlebihan pada tahap awal.

Gunakan mock repository langsung melalui Riverpod override.

---

# Kualitas Kode

Ikuti aturan berikut:

- Gunakan `const` jika memungkinkan.
- Jangan menaruh business logic di widget.
- Jangan membuat file lebih dari sekitar 300–400 baris jika dapat dipisahkan secara logis.
- Jangan memecah setiap widget kecil menjadi file sendiri.
- Jangan menggunakan global mutable state.
- Jangan menggunakan singleton manual jika Riverpod sudah cukup.
- Jangan menambahkan service locator.
- Jangan menambahkan dependency injection package.
- Jangan menggunakan BLoC karena Riverpod sudah tersedia.
- Jangan membuat use case class yang hanya memanggil repository.
- Jangan membuat DTO dan entity terpisah selama bentuk datanya sama.
- Jangan membuat mapper tanpa kebutuhan nyata.
- Hindari `dynamic`.
- Hindari `late` jika tidak diperlukan.
- Gunakan null safety secara konsisten.
- Gunakan `context.mounted` setelah operasi async sebelum navigasi.
- Semua kode harus lolos `flutter analyze`.
- Jangan menggunakan API Flutter yang deprecated.
- Jangan meninggalkan import yang tidak digunakan.

---

# Tahapan Implementasi

Berikan implementasi secara bertahap dengan urutan berikut:

1. Struktur folder final.
2. `main.dart`.
3. `bootstrap.dart`.
4. Theme Material 3.
5. Design tokens.
6. Router dan navigation shell.
7. Model Freezed.
8. Formatter dan validator.
9. Mock repository.
10. Riverpod provider.
11. Reusable widgets.
12. Dashboard.
13. Halaman aset.
14. Detail aset.
15. Update nilai aset.
16. Histori.
17. Target.
18. Setelan.
19. Test dasar.
20. Perintah menjalankan code generation dan aplikasi.

Untuk setiap tahap:

- Tampilkan nama file.
- Tampilkan path lengkap.
- Tampilkan kode lengkap.
- Jangan menampilkan potongan kode yang tidak dapat dipakai.
- Jangan melewatkan import.
- Pastikan nama class dan import konsisten antarfile.
- Jangan membuat file yang tidak digunakan.

---

# Perintah Akhir

Setelah semua file selesai, berikan perintah:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

---

# Hasil Akhir yang Diharapkan

Hasil akhirnya harus menjadi pondasi aplikasi Flutter yang:

- dapat dijalankan,
- menggunakan Material Design 3,
- memiliki desain ala aplikasi Google,
- menggunakan Riverpod secara proporsional,
- menggunakan GoRouter dengan navigation shell,
- menggunakan repository tunggal untuk data portofolio,
- menggunakan mock data,
- mendukung light dan dark mode,
- memiliki dashboard, histori, aset, target, setelan, dan update nilai aset,
- tidak terlalu banyak boilerplate,
- tidak menggunakan Clean Architecture secara berlebihan,
- mudah dimigrasikan ke REST API,
- mudah dipahami dan dirawat oleh developer lain.

Prioritaskan kode yang sederhana, jelas, dan benar dibandingkan abstraksi yang terlalu kompleks.
