import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// Label navigasi bawah untuk beranda
  ///
  /// In id, this message translates to:
  /// **'Beranda'**
  String get navDashboardLabel;

  /// Judul halaman setelan
  ///
  /// In id, this message translates to:
  /// **'Setelan'**
  String get settingsTitle;

  /// Judul seksi tema tampilan
  ///
  /// In id, this message translates to:
  /// **'Tampilan'**
  String get settingsDisplaySection;

  /// Judul seksi pilihan bahasa
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get settingsLanguageSection;

  /// Judul seksi backup
  ///
  /// In id, this message translates to:
  /// **'Backup'**
  String get settingsBackupSection;

  /// Judul seksi informasi aplikasi
  ///
  /// In id, this message translates to:
  /// **'Aplikasi'**
  String get settingsAppSection;

  /// Label tentang aplikasi
  ///
  /// In id, this message translates to:
  /// **'Tentang aplikasi'**
  String get settingsAboutApp;

  /// Pilihan tema mengikuti sistem
  ///
  /// In id, this message translates to:
  /// **'Sistem'**
  String get themeSystem;

  /// Pilihan tema terang
  ///
  /// In id, this message translates to:
  /// **'Terang'**
  String get themeLight;

  /// Pilihan tema gelap
  ///
  /// In id, this message translates to:
  /// **'Gelap'**
  String get themeDark;

  /// Label toggle mode gelap
  ///
  /// In id, this message translates to:
  /// **'Mode Gelap'**
  String get settingsDarkMode;

  /// Label baris pemilih bahasa
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get settingsLanguageLabel;

  /// Pilihan bahasa Indonesia
  ///
  /// In id, this message translates to:
  /// **'Indonesia'**
  String get languageIndonesian;

  /// Pilihan bahasa Inggris
  ///
  /// In id, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Label default tombol batal pada dialog konfirmasi
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get dialogCancel;

  /// Label tombol simpan generik
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get commonSave;

  /// Label tombol simpan perubahan generik
  ///
  /// In id, this message translates to:
  /// **'Simpan perubahan'**
  String get commonSaveChanges;

  /// Label tombol hapus generik
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get commonDelete;

  /// Label tombol tutup generik
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get commonClose;

  /// Kata 'Aset' generik, dipakai sebagai label field/fallback nama
  ///
  /// In id, this message translates to:
  /// **'Aset'**
  String get commonAsset;

  /// Label field kategori
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get commonCategoryLabel;

  /// Label field tanggal pencatatan
  ///
  /// In id, this message translates to:
  /// **'Tanggal pencatatan'**
  String get commonRecordedAtLabel;

  /// Placeholder saat tanggal belum dipilih
  ///
  /// In id, this message translates to:
  /// **'Pilih tanggal'**
  String get commonSelectDatePlaceholder;

  /// Label nilai aset saat ini
  ///
  /// In id, this message translates to:
  /// **'Nilai saat ini'**
  String get commonCurrentValueLabel;

  /// Label field total modal opsional
  ///
  /// In id, this message translates to:
  /// **'Total modal (opsional)'**
  String get commonTotalCostOptionalLabel;

  /// Label generik 'Return' (persentase imbal hasil)
  ///
  /// In id, this message translates to:
  /// **'Return'**
  String get commonReturnLabel;

  /// Kata 'Untung' untuk label/status untung
  ///
  /// In id, this message translates to:
  /// **'Untung'**
  String get profitLossGainLabel;

  /// Kata 'Rugi' untuk label/status rugi
  ///
  /// In id, this message translates to:
  /// **'Rugi'**
  String get profitLossLossLabel;

  /// Judul state kosong daftar aset
  ///
  /// In id, this message translates to:
  /// **'Belum ada aset'**
  String get commonEmptyAssetsTitle;

  /// Label tombol tambah aset
  ///
  /// In id, this message translates to:
  /// **'Tambah aset'**
  String get commonAddAssetLabel;

  /// Label tombol tambah target
  ///
  /// In id, this message translates to:
  /// **'Tambah target'**
  String get commonAddTargetLabel;

  /// Judul state kosong target alokasi
  ///
  /// In id, this message translates to:
  /// **'Belum ada target alokasi'**
  String get commonEmptyTargetsTitle;

  /// Judul dialog konfirmasi hapus histori
  ///
  /// In id, this message translates to:
  /// **'Hapus histori?'**
  String get commonDeleteHistoryTitle;

  /// Pesan dialog konfirmasi hapus histori
  ///
  /// In id, this message translates to:
  /// **'Entri histori bulan ini akan dihapus.'**
  String get commonDeleteHistoryMessage;

  /// Snackbar sukses hapus histori
  ///
  /// In id, this message translates to:
  /// **'Histori dihapus.'**
  String get commonHistoryDeletedMessage;

  /// Snackbar gagal hapus histori
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus histori.'**
  String get commonDeleteHistoryFailedMessage;

  /// Judul state kosong histori
  ///
  /// In id, this message translates to:
  /// **'Belum ada histori'**
  String get commonEmptyHistoryTitle;

  /// Judul halaman update nilai aset
  ///
  /// In id, this message translates to:
  /// **'Update nilai aset'**
  String get updateAssetValueTitle;

  /// Label dropdown pemilihan aset
  ///
  /// In id, this message translates to:
  /// **'Aset'**
  String get assetDropdownLabel;

  /// Label segmented button tipe pembaruan nilai
  ///
  /// In id, this message translates to:
  /// **'Tipe pembaruan'**
  String get updateTypeLabel;

  /// Opsi tipe pembaruan: menimpa nilai
  ///
  /// In id, this message translates to:
  /// **'Ubah'**
  String get updateTypeOverride;

  /// Opsi tipe pembaruan: menambah nilai
  ///
  /// In id, this message translates to:
  /// **'Tambah'**
  String get updateTypeIncrement;

  /// Label field total nilai aset (mode ubah)
  ///
  /// In id, this message translates to:
  /// **'Total nilai aset'**
  String get totalValueFieldLabel;

  /// Label field penambahan nilai (mode tambah)
  ///
  /// In id, this message translates to:
  /// **'Penambahan nilai'**
  String get incrementValueFieldLabel;

  /// Helper text field total nilai aset
  ///
  /// In id, this message translates to:
  /// **'Nilai aset akan disesuaikan menjadi nominal ini.'**
  String get totalValueFieldHelper;

  /// Helper text field penambahan nilai
  ///
  /// In id, this message translates to:
  /// **'Nominal ini akan ditambahkan ke nilai aset saat ini.'**
  String get incrementValueFieldHelper;

  /// Helper text field total modal (mode ubah)
  ///
  /// In id, this message translates to:
  /// **'Total dana yang sudah disetor. Kosongkan bila modal tidak berubah.'**
  String get totalCostFieldHelper;

  /// Label field penambahan modal (mode tambah)
  ///
  /// In id, this message translates to:
  /// **'Penambahan modal (opsional)'**
  String get incrementCostFieldLabel;

  /// Helper text field penambahan modal
  ///
  /// In id, this message translates to:
  /// **'Dana yang baru disetor. Kosongkan bila penambahan berasal dari hasil investasi.'**
  String get incrementCostFieldHelper;

  /// Label field catatan opsional
  ///
  /// In id, this message translates to:
  /// **'Catatan (opsional)'**
  String get noteFieldLabel;

  /// Judul kartu preview
  ///
  /// In id, this message translates to:
  /// **'Preview'**
  String get previewLabel;

  /// Label baris preview tambahan nilai
  ///
  /// In id, this message translates to:
  /// **'Tambahan nilai'**
  String get addedValueLabel;

  /// Label baris preview nilai terbaru
  ///
  /// In id, this message translates to:
  /// **'Nilai terbaru'**
  String get latestValueLabel;

  /// Label baris preview modal saat ini
  ///
  /// In id, this message translates to:
  /// **'Modal saat ini'**
  String get currentCostLabel;

  /// Label baris preview tambahan modal
  ///
  /// In id, this message translates to:
  /// **'Tambahan modal'**
  String get addedCostLabel;

  /// Label baris preview modal terbaru
  ///
  /// In id, this message translates to:
  /// **'Modal terbaru'**
  String get latestCostLabel;

  /// Snackbar sukses update nilai aset
  ///
  /// In id, this message translates to:
  /// **'Nilai {assetName} berhasil diperbarui.'**
  String assetValueUpdatedMessage(String assetName);

  /// Snackbar gagal update nilai aset
  ///
  /// In id, this message translates to:
  /// **'Pembaruan nilai aset belum berhasil. Coba lagi.'**
  String get updateAssetValueFailedMessage;

  /// Judul halaman histori portofolio
  ///
  /// In id, this message translates to:
  /// **'Histori'**
  String get historyTitle;

  /// Label time-weighted return kumulatif seluruh histori
  ///
  /// In id, this message translates to:
  /// **'Return sejak awal'**
  String get historyTwrSinceStartLabel;

  /// Label time-weighted return untuk satu tahun
  ///
  /// In id, this message translates to:
  /// **'Return {year}'**
  String historyTwrYearLabel(String year);

  /// Label time-weighted return yang disetahunkan
  ///
  /// In id, this message translates to:
  /// **'Per tahun'**
  String get historyTwrAnnualizedLabel;

  /// Keterangan singkat arti TWR di halaman histori
  ///
  /// In id, this message translates to:
  /// **'Time-weighted return: tidak terpengaruh setoran, mengukur hasil strategi'**
  String get historyTwrCaption;

  /// Pesan state kosong histori portofolio
  ///
  /// In id, this message translates to:
  /// **'Histori muncul setelah nilai aset dicatat.'**
  String get emptyHistoryMessage;

  /// Label chip filter semua tahun
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get allFilterLabel;

  /// Judul state kosong hasil filter
  ///
  /// In id, this message translates to:
  /// **'Tidak ada data pada filter ini'**
  String get noFilteredDataTitle;

  /// Pesan state kosong hasil filter
  ///
  /// In id, this message translates to:
  /// **'Pilih tahun lain.'**
  String get noFilteredDataMessage;

  /// Label perubahan untuk snapshot pertama
  ///
  /// In id, this message translates to:
  /// **'Data awal'**
  String get initialDataLabel;

  /// Judul state aset tidak ditemukan
  ///
  /// In id, this message translates to:
  /// **'Aset tidak ditemukan'**
  String get assetNotFoundTitle;

  /// Pesan state aset tidak ditemukan
  ///
  /// In id, this message translates to:
  /// **'Data aset yang Anda buka tidak tersedia.'**
  String get assetNotFoundMessage;

  /// Label metrik total modal
  ///
  /// In id, this message translates to:
  /// **'Total modal'**
  String get totalCostLabel;

  /// Label metrik alokasi portofolio
  ///
  /// In id, this message translates to:
  /// **'Alokasi portofolio'**
  String get allocationLabel;

  /// Label metrik terakhir diperbarui
  ///
  /// In id, this message translates to:
  /// **'Terakhir diperbarui'**
  String get lastUpdatedLabel;

  /// Tombol menuju halaman update nilai
  ///
  /// In id, this message translates to:
  /// **'Update nilai'**
  String get updateValueButton;

  /// Judul seksi histori nilai aset
  ///
  /// In id, this message translates to:
  /// **'Histori nilai'**
  String get historySectionTitle;

  /// Pesan state kosong histori aset
  ///
  /// In id, this message translates to:
  /// **'Histori muncul setelah nilai diperbarui.'**
  String get emptyAssetHistoryMessage;

  /// Judul default halaman detail aset
  ///
  /// In id, this message translates to:
  /// **'Detail aset'**
  String get defaultAssetDetailTitle;

  /// Tooltip tombol edit aset
  ///
  /// In id, this message translates to:
  /// **'Edit aset'**
  String get editAssetTooltip;

  /// Pesan target tidak ditemukan (form)
  ///
  /// In id, this message translates to:
  /// **'Target tidak ditemukan.'**
  String get targetNotFoundMessage;

  /// Judul halaman edit target
  ///
  /// In id, this message translates to:
  /// **'Edit target'**
  String get editTargetTitle;

  /// Judul halaman tambah target
  ///
  /// In id, this message translates to:
  /// **'Tambah target'**
  String get addTargetTitle;

  /// Label field target alokasi
  ///
  /// In id, this message translates to:
  /// **'Target alokasi'**
  String get targetAllocationLabel;

  /// Tombol hapus target
  ///
  /// In id, this message translates to:
  /// **'Hapus target'**
  String get deleteTargetButton;

  /// Validasi target alokasi wajib diisi
  ///
  /// In id, this message translates to:
  /// **'Target alokasi wajib diisi.'**
  String get targetPercentageRequired;

  /// Validasi target alokasi tidak valid
  ///
  /// In id, this message translates to:
  /// **'Target alokasi tidak valid.'**
  String get targetPercentageInvalid;

  /// Validasi rentang target alokasi
  ///
  /// In id, this message translates to:
  /// **'Target alokasi harus di antara 0 sampai 100%.'**
  String get targetPercentageRange;

  /// Snackbar gagal simpan target
  ///
  /// In id, this message translates to:
  /// **'Target belum berhasil disimpan. Coba lagi.'**
  String get targetSaveFailedMessage;

  /// Judul dialog konfirmasi hapus target
  ///
  /// In id, this message translates to:
  /// **'Hapus target?'**
  String get deleteTargetTitle;

  /// Pesan dialog konfirmasi hapus target
  ///
  /// In id, this message translates to:
  /// **'Target {category} akan dihapus.'**
  String deleteTargetMessage(String category);

  /// Snackbar gagal hapus target
  ///
  /// In id, this message translates to:
  /// **'Target belum berhasil dihapus. Coba lagi.'**
  String get targetDeleteFailedMessage;

  /// Validasi total target alokasi melebihi 100%
  ///
  /// In id, this message translates to:
  /// **'Total target alokasi tidak boleh lebih dari 100%.'**
  String get targetPercentageExceededMessage;

  /// Judul halaman restore backup
  ///
  /// In id, this message translates to:
  /// **'Pulihkan dari backup'**
  String get restoreTitle;

  /// Judul error saat daftar backup gagal dimuat
  ///
  /// In id, this message translates to:
  /// **'Daftar backup gagal dimuat'**
  String get backupListLoadFailedTitle;

  /// Judul state kosong daftar backup
  ///
  /// In id, this message translates to:
  /// **'Belum ada backup'**
  String get emptyBackupTitle;

  /// Pesan state kosong daftar backup
  ///
  /// In id, this message translates to:
  /// **'Backup pertama Anda akan muncul di sini.'**
  String get emptyBackupMessage;

  /// Judul dialog konfirmasi restore
  ///
  /// In id, this message translates to:
  /// **'Pulihkan data ini?'**
  String get restoreDataTitle;

  /// Pesan dialog konfirmasi restore
  ///
  /// In id, this message translates to:
  /// **'Data portofolio saat ini akan diganti dengan backup {date}. Tindakan ini tidak dapat dibatalkan.'**
  String restoreDataMessage(String date);

  /// Label tombol pulihkan
  ///
  /// In id, this message translates to:
  /// **'Pulihkan'**
  String get restoreLabel;

  /// Snackbar sukses restore
  ///
  /// In id, this message translates to:
  /// **'Data berhasil dipulihkan.'**
  String get restoreSuccessMessage;

  /// Snackbar gagal restore
  ///
  /// In id, this message translates to:
  /// **'Pemulihan gagal. Coba lagi.'**
  String get restoreFailedMessage;

  /// Pesan aset tidak ditemukan (form)
  ///
  /// In id, this message translates to:
  /// **'Aset tidak ditemukan.'**
  String get assetNotFoundFormMessage;

  /// Judul halaman edit aset
  ///
  /// In id, this message translates to:
  /// **'Edit aset'**
  String get editAssetTitle;

  /// Judul halaman tambah aset
  ///
  /// In id, this message translates to:
  /// **'Tambah aset'**
  String get addAssetTitle;

  /// Label field nama aset
  ///
  /// In id, this message translates to:
  /// **'Nama aset'**
  String get assetNameLabel;

  /// Validasi nama aset wajib diisi
  ///
  /// In id, this message translates to:
  /// **'Nama aset wajib diisi.'**
  String get assetNameRequired;

  /// Label field kode aset
  ///
  /// In id, this message translates to:
  /// **'Kode aset'**
  String get assetCodeLabel;

  /// Validasi kode aset wajib diisi
  ///
  /// In id, this message translates to:
  /// **'Kode aset wajib diisi.'**
  String get assetCodeRequired;

  /// Label field nilai awal aset
  ///
  /// In id, this message translates to:
  /// **'Nilai awal'**
  String get initialValueLabel;

  /// Helper text total modal opsional
  ///
  /// In id, this message translates to:
  /// **'Total dana yang disetor, untuk menghitung untung/rugi.'**
  String get totalCostOptionalHelper;

  /// Tombol hapus aset
  ///
  /// In id, this message translates to:
  /// **'Hapus aset'**
  String get deleteAssetButton;

  /// Judul dialog konfirmasi hapus aset
  ///
  /// In id, this message translates to:
  /// **'Hapus aset?'**
  String get deleteAssetTitle;

  /// Pesan dialog konfirmasi hapus aset
  ///
  /// In id, this message translates to:
  /// **'Aset {assetName} dan histori nilainya akan dihapus.'**
  String deleteAssetMessage(String assetName);

  /// Snackbar gagal simpan aset
  ///
  /// In id, this message translates to:
  /// **'Aset belum berhasil disimpan. Coba lagi.'**
  String get assetSaveFailedMessage;

  /// Judul halaman detail target
  ///
  /// In id, this message translates to:
  /// **'Detail target'**
  String get targetDetailTitle;

  /// Tooltip tombol edit target
  ///
  /// In id, this message translates to:
  /// **'Edit target'**
  String get editTargetTooltip;

  /// Judul state target tidak ditemukan
  ///
  /// In id, this message translates to:
  /// **'Target tidak ditemukan'**
  String get targetNotFoundTitle;

  /// Pesan state target tidak ditemukan
  ///
  /// In id, this message translates to:
  /// **'Data target yang Anda buka tidak tersedia.'**
  String get targetNotFoundDetailMessage;

  /// Label metrik nilai aktual
  ///
  /// In id, this message translates to:
  /// **'Nilai aktual'**
  String get actualValueLabel;

  /// Label metrik nilai target
  ///
  /// In id, this message translates to:
  /// **'Nilai target'**
  String get targetValueLabel;

  /// Judul seksi aset dalam kategori tertentu
  ///
  /// In id, this message translates to:
  /// **'Aset {category}'**
  String assetsInCategoryTitle(String category);

  /// Pesan state kosong aset dalam kategori
  ///
  /// In id, this message translates to:
  /// **'Belum ada aset pada kategori ini.'**
  String get emptyAssetsInCategoryMessage;

  /// Judul dialog info toleransi alokasi
  ///
  /// In id, this message translates to:
  /// **'Batas wajar'**
  String get reasonableRangeTitle;

  /// Teks rentang toleransi alokasi
  ///
  /// In id, this message translates to:
  /// **'{lower} - {upper} (toleransi ±{tolerance})'**
  String toleranceInfoText(String lower, String upper, String tolerance);

  /// Penjelasan aturan 5/25 toleransi alokasi
  ///
  /// In id, this message translates to:
  /// **'Mengikuti aturan 5/25: penyesuaian baru diperlukan saat alokasi melewati 5 poin persen atau 25% dari target, mana yang lebih kecil.'**
  String get toleranceRuleExplanation;

  /// Judul halaman daftar aset
  ///
  /// In id, this message translates to:
  /// **'Aset'**
  String get assetsTitle;

  /// Tooltip FAB tambah aset
  ///
  /// In id, this message translates to:
  /// **'Tambah aset'**
  String get addAssetTooltip;

  /// Pesan state kosong daftar aset
  ///
  /// In id, this message translates to:
  /// **'Tambahkan aset pertama untuk mulai mencatat nilai.'**
  String get emptyAssetsListMessage;

  /// Label seksi aset nonaktif/arsip
  ///
  /// In id, this message translates to:
  /// **'Aset nonaktif'**
  String get inactiveAssetsLabel;

  /// Judul halaman daftar target
  ///
  /// In id, this message translates to:
  /// **'Target'**
  String get targetTitle;

  /// Tooltip FAB tambah target
  ///
  /// In id, this message translates to:
  /// **'Tambah target'**
  String get addTargetTooltip;

  /// Pesan state kosong daftar target
  ///
  /// In id, this message translates to:
  /// **'Tentukan porsi ideal tiap kategori aset supaya progres portofolio bisa dihitung.'**
  String get emptyTargetsMessage;

  /// Pesan ajakan hubungkan akun Google
  ///
  /// In id, this message translates to:
  /// **'Hubungkan akun Google untuk mem-backup data portofolio Anda.'**
  String get connectGoogleMessage;

  /// Tombol hubungkan akun Google
  ///
  /// In id, this message translates to:
  /// **'Hubungkan akun Google'**
  String get connectGoogleButton;

  /// Fallback teks saat email akun tidak tersedia
  ///
  /// In id, this message translates to:
  /// **'Akun Google terhubung'**
  String get connectedAccountFallback;

  /// Tombol putuskan akun Google
  ///
  /// In id, this message translates to:
  /// **'Putuskan'**
  String get disconnectButton;

  /// Label switch backup otomatis
  ///
  /// In id, this message translates to:
  /// **'Backup otomatis'**
  String get autoBackupLabel;

  /// Status sedang memulihkan data
  ///
  /// In id, this message translates to:
  /// **'Sedang memulihkan data...'**
  String get restoringMessage;

  /// Status belum pernah backup
  ///
  /// In id, this message translates to:
  /// **'Belum pernah backup.'**
  String get neverBackedUpMessage;

  /// Status waktu backup terakhir
  ///
  /// In id, this message translates to:
  /// **'Backup terakhir: {date}'**
  String lastBackupMessage(String date);

  /// Tombol backup sekarang
  ///
  /// In id, this message translates to:
  /// **'Backup sekarang'**
  String get backupNowButton;

  /// Tombol menuju halaman restore
  ///
  /// In id, this message translates to:
  /// **'Pulihkan dari backup'**
  String get restoreFromBackupButton;

  /// Judul dialog konfirmasi backup
  ///
  /// In id, this message translates to:
  /// **'Backup sekarang?'**
  String get confirmBackupTitle;

  /// Pesan dialog konfirmasi backup
  ///
  /// In id, this message translates to:
  /// **'Salinan data portofolio saat ini akan diunggah ke Google Drive dan menghitung ulang jadwal backup otomatis berikutnya.'**
  String get confirmBackupMessage;

  /// Label tombol konfirmasi backup
  ///
  /// In id, this message translates to:
  /// **'Backup'**
  String get backupLabel;

  /// Judul dialog konfirmasi putuskan akun
  ///
  /// In id, this message translates to:
  /// **'Putuskan akun Google?'**
  String get confirmDisconnectTitle;

  /// Pesan dialog konfirmasi putuskan akun
  ///
  /// In id, this message translates to:
  /// **'Backup otomatis akan berhenti dan aplikasi tidak lagi punya akses ke Google Drive. Data di perangkat dan backup yang sudah ada tidak dihapus.'**
  String get confirmDisconnectMessage;

  /// Pesan error gagal menghubungkan akun Google
  ///
  /// In id, this message translates to:
  /// **'Gagal menghubungkan akun Google.'**
  String get connectFailedMessage;

  /// Pesan error backup gagal
  ///
  /// In id, this message translates to:
  /// **'Backup gagal. Coba lagi nanti.'**
  String get backupFailedMessage;

  /// Pesan error akun Google belum terhubung
  ///
  /// In id, this message translates to:
  /// **'Akun Google belum terhubung.'**
  String get googleNotConnectedMessage;

  /// Pesan error otorisasi Google Drive dibutuhkan
  ///
  /// In id, this message translates to:
  /// **'Otorisasi Google Drive dibutuhkan.'**
  String get googleAuthorizationRequiredMessage;

  /// Pesan error file backup tidak valid
  ///
  /// In id, this message translates to:
  /// **'File backup tidak valid.'**
  String get invalidBackupFileMessage;

  /// Pesan state kosong dashboard
  ///
  /// In id, this message translates to:
  /// **'Catat aset pertama untuk melihat ringkasan.'**
  String get emptyAssetsDashboardMessage;

  /// Pesan kartu belum ada target di dashboard
  ///
  /// In id, this message translates to:
  /// **'Buat target alokasi dulu agar progres portofolio bisa dihitung dengan benar.'**
  String get noTargetsCardMessage;

  /// Judul seksi aset utama dashboard
  ///
  /// In id, this message translates to:
  /// **'Aset utama'**
  String get mainAssetsTitle;

  /// Label aksi lihat semua aset
  ///
  /// In id, this message translates to:
  /// **'Lihat semua'**
  String get viewAllLabel;

  /// Validasi nilai aset tidak boleh negatif
  ///
  /// In id, this message translates to:
  /// **'Nilai aset tidak boleh kurang dari nol.'**
  String get invalidCurrentValueMessage;

  /// Validasi total modal tidak boleh negatif
  ///
  /// In id, this message translates to:
  /// **'Total modal tidak boleh kurang dari nol.'**
  String get invalidTotalCostMessage;

  /// Label metrik total nilai portofolio (kas + investasi) di kartu ringkasan dashboard
  ///
  /// In id, this message translates to:
  /// **'Total Nilai'**
  String get dashboardPortfolioValueLabel;

  /// Label metrik total aset kategori kas di kartu ringkasan dashboard
  ///
  /// In id, this message translates to:
  /// **'Kas'**
  String get dashboardCashLabel;

  /// Label singkat 'Modal', dipakai di kartu ringkasan dan header tabel aset
  ///
  /// In id, this message translates to:
  /// **'Modal'**
  String get dashboardCapitalLabel;

  /// Label metrik jumlah aset di kartu ringkasan dashboard
  ///
  /// In id, this message translates to:
  /// **'Jumlah Aset'**
  String get dashboardAssetCountLabel;

  /// Label metrik untung/rugi di kartu ringkasan dashboard, meniru istilah aplikasi sekuritas
  ///
  /// In id, this message translates to:
  /// **'P&L'**
  String get dashboardProfitLossLabel;

  /// Label baris pintasan ke halaman histori dari kartu ringkasan
  ///
  /// In id, this message translates to:
  /// **'Lihat histori'**
  String get dashboardViewHistoryLabel;

  /// Bagian awal label screen-reader kartu ringkasan portofolio
  ///
  /// In id, this message translates to:
  /// **'Total portofolio {totalValue}. Kas {cash}'**
  String dashboardTotalPortfolioSemantic(String totalValue, String cash);

  /// Bagian untung/rugi label screen-reader kartu ringkasan portofolio
  ///
  /// In id, this message translates to:
  /// **'Modal {cost}. {profitLossLabel} {amount}'**
  String dashboardProfitLossSemantic(
    String cost,
    String profitLossLabel,
    String amount,
  );

  /// Header kolom kode aset pada tabel daftar aset
  ///
  /// In id, this message translates to:
  /// **'Kode'**
  String get assetTableCodeHeader;

  /// Header kolom nama aset pada tabel daftar aset
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get assetTableNameHeader;

  /// Header kolom alokasi pada tabel daftar aset
  ///
  /// In id, this message translates to:
  /// **'Alokasi'**
  String get assetTableAllocationHeader;

  /// Header kolom nilai pada tabel daftar aset, juga dipakai sebagai label legenda grafik histori
  ///
  /// In id, this message translates to:
  /// **'Nilai'**
  String get assetTableValueHeader;

  /// Header kolom tanggal diperbarui pada tabel daftar aset
  ///
  /// In id, this message translates to:
  /// **'Diperbarui'**
  String get assetTableUpdatedHeader;

  /// Header kolom harga pasar terkini pada tabel daftar aset
  ///
  /// In id, this message translates to:
  /// **'Harga Kini'**
  String get assetTableCurrentPriceHeader;

  /// Header kolom untung/rugi (disingkat) pada tabel daftar aset
  ///
  /// In id, this message translates to:
  /// **'U/R'**
  String get assetTableProfitLossHeader;

  /// Bagian nilai dan alokasi pada label screen-reader baris aset
  ///
  /// In id, this message translates to:
  /// **'Nilai {value}, alokasi {allocation}'**
  String assetSemanticValueAllocation(String value, String allocation);

  /// Bagian modal dan untung/rugi pada label screen-reader baris aset
  ///
  /// In id, this message translates to:
  /// **'Modal {cost}, {profitLossWord} {amount}'**
  String assetSemanticCostProfitLoss(
    String cost,
    String profitLossWord,
    String amount,
  );

  /// Label screen-reader grafik histori saat ada garis modal
  ///
  /// In id, this message translates to:
  /// **'Grafik nilai dan modal {startMonth} sampai {endMonth}, terendah {minValue}, tertinggi {maxValue}'**
  String historyChartSemanticLabelWithCost(
    String startMonth,
    String endMonth,
    String minValue,
    String maxValue,
  );

  /// Label screen-reader grafik histori saat hanya ada garis nilai
  ///
  /// In id, this message translates to:
  /// **'Grafik nilai {startMonth} sampai {endMonth}, terendah {minValue}, tertinggi {maxValue}'**
  String historyChartSemanticLabelValueOnly(
    String startMonth,
    String endMonth,
    String minValue,
    String maxValue,
  );

  /// Pesan placeholder grafik histori saat data kurang dari dua titik
  ///
  /// In id, this message translates to:
  /// **'Grafik muncul setelah ada minimal dua pencatatan nilai.'**
  String get historyChartPlaceholderMessage;

  /// Label screen-reader badge alokasi aset
  ///
  /// In id, this message translates to:
  /// **'Alokasi {percentage} dari portofolio'**
  String allocationBadgeSemanticLabel(String percentage);

  /// Label default kartu progres target alokasi
  ///
  /// In id, this message translates to:
  /// **'Target Alokasi'**
  String get targetProgressDefaultLabel;

  /// Subjudul default kartu progres target alokasi
  ///
  /// In id, this message translates to:
  /// **'Alokasi portofolio ideal'**
  String get targetProgressDefaultSubtitle;

  /// Label screen-reader kartu progres target alokasi
  ///
  /// In id, this message translates to:
  /// **'{label} {percentage} persen. {subtitle}'**
  String targetProgressSemanticLabel(
    String label,
    String percentage,
    String subtitle,
  );

  /// Satu item ringkasan screen-reader grafik donat kategori
  ///
  /// In id, this message translates to:
  /// **'{category} {percentage} persen'**
  String categoryDonutSemanticItem(String category, String percentage);

  /// Label screen-reader grafik donat alokasi per kategori
  ///
  /// In id, this message translates to:
  /// **'Grafik alokasi aktual per kategori: {summary}'**
  String categoryDonutSemanticLabel(String summary);

  /// Jumlah kategori di tengah grafik donat alokasi
  ///
  /// In id, this message translates to:
  /// **'{count} Kategori'**
  String categoryDonutCategoryCount(int count);

  /// Teks aktual vs target pada item alokasi target
  ///
  /// In id, this message translates to:
  /// **'Aktual {actual} dari target {target}'**
  String targetAllocationActualOfTarget(String actual, String target);

  /// Label screen-reader progres alokasi per kategori
  ///
  /// In id, this message translates to:
  /// **'Progres alokasi {category}'**
  String targetAllocationProgressSemanticLabel(String category);

  /// Tooltip tombol info pada header seksi
  ///
  /// In id, this message translates to:
  /// **'Info'**
  String get sectionHeaderInfoTooltip;

  /// Judul default tampilan error generik
  ///
  /// In id, this message translates to:
  /// **'Data belum dapat dimuat.'**
  String get appErrorDefaultTitle;

  /// Pesan default tampilan error generik
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan saat membaca data. Coba lagi.'**
  String get appErrorDefaultMessage;

  /// Label tombol coba lagi pada tampilan error generik
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get appErrorRetryButtonLabel;

  /// Judul kartu/section harga pasar Yahoo Finance
  ///
  /// In id, this message translates to:
  /// **'Harga Pasar'**
  String get marketPriceTitle;

  /// Label field simbol Yahoo Finance pada form aset
  ///
  /// In id, this message translates to:
  /// **'Simbol Yahoo Finance (opsional)'**
  String get marketSymbolLabel;

  /// Helper text field simbol Yahoo Finance
  ///
  /// In id, this message translates to:
  /// **'Contoh: BMRI.JK · BTC-USD · SPY'**
  String get marketSymbolHelper;

  /// Waktu harga pasar terakhir diperbarui
  ///
  /// In id, this message translates to:
  /// **'per {dateTime}'**
  String marketAsOf(String dateTime);

  /// Chip penanda harga pasar dari cache (offline)
  ///
  /// In id, this message translates to:
  /// **'Offline'**
  String get marketOfflineChip;

  /// Status memuat harga pasar
  ///
  /// In id, this message translates to:
  /// **'Memuat harga…'**
  String get marketLoading;

  /// Pesan singkat harga pasar gagal dimuat (tile ringkas)
  ///
  /// In id, this message translates to:
  /// **'Harga tidak tersedia'**
  String get marketUnavailableShort;

  /// Pesan simbol pasar tidak ditemukan
  ///
  /// In id, this message translates to:
  /// **'Simbol {symbol} tidak ditemukan di Yahoo Finance.'**
  String marketSymbolNotFound(String symbol);

  /// Pesan harga pasar gagal dimuat, tanpa cache
  ///
  /// In id, this message translates to:
  /// **'Harga belum bisa dimuat. Tarik untuk coba lagi.'**
  String get marketUnavailable;

  /// Placeholder chart harga pasar tanpa data cukup
  ///
  /// In id, this message translates to:
  /// **'Data chart belum tersedia.'**
  String get marketChartEmpty;

  /// Tombol menuju halaman edit aset
  ///
  /// In id, this message translates to:
  /// **'Edit Aset'**
  String get editAssetButton;

  /// Label tab rentang chart 1 hari
  ///
  /// In id, this message translates to:
  /// **'1D'**
  String get chartRange1D;

  /// Label tab rentang chart 1 minggu
  ///
  /// In id, this message translates to:
  /// **'1W'**
  String get chartRange1W;

  /// Label tab rentang chart 1 bulan
  ///
  /// In id, this message translates to:
  /// **'1B'**
  String get chartRange1M;

  /// Label tab rentang chart 3 bulan
  ///
  /// In id, this message translates to:
  /// **'3B'**
  String get chartRange3M;

  /// Label tab rentang chart sejak awal tahun
  ///
  /// In id, this message translates to:
  /// **'YTD'**
  String get chartRangeYTD;

  /// Label tab rentang chart 1 tahun
  ///
  /// In id, this message translates to:
  /// **'1T'**
  String get chartRange1Y;

  /// Label tab rentang chart 3 tahun
  ///
  /// In id, this message translates to:
  /// **'3T'**
  String get chartRange3Y;

  /// Label tab rentang chart 5 tahun
  ///
  /// In id, this message translates to:
  /// **'5T'**
  String get chartRange5Y;

  /// Label periode perubahan harga rentang 1 hari
  ///
  /// In id, this message translates to:
  /// **'Hari Ini'**
  String get chartPeriodToday;

  /// Label periode perubahan harga rentang 1 minggu
  ///
  /// In id, this message translates to:
  /// **'1 Minggu Terakhir'**
  String get chartPeriodPastWeek;

  /// Label periode perubahan harga rentang 1 bulan
  ///
  /// In id, this message translates to:
  /// **'1 Bulan Terakhir'**
  String get chartPeriodPastMonth;

  /// Label periode perubahan harga rentang 3 bulan
  ///
  /// In id, this message translates to:
  /// **'3 Bulan Terakhir'**
  String get chartPeriodPastThreeMonths;

  /// Label periode perubahan harga sejak awal tahun
  ///
  /// In id, this message translates to:
  /// **'Sejak Awal Tahun'**
  String get chartPeriodYearToDate;

  /// Label periode perubahan harga rentang 1 tahun
  ///
  /// In id, this message translates to:
  /// **'1 Tahun Terakhir'**
  String get chartPeriodPastYear;

  /// Label periode perubahan harga rentang 3 tahun
  ///
  /// In id, this message translates to:
  /// **'3 Tahun Terakhir'**
  String get chartPeriodPastThreeYears;

  /// Label periode perubahan harga rentang 5 tahun
  ///
  /// In id, this message translates to:
  /// **'5 Tahun Terakhir'**
  String get chartPeriodPastFiveYears;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
