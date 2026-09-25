// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get navDashboardLabel => 'Beranda';

  @override
  String get settingsTitle => 'Setelan';

  @override
  String get settingsDisplaySection => 'Tampilan';

  @override
  String get settingsLanguageSection => 'Bahasa';

  @override
  String get settingsBackupSection => 'Backup';

  @override
  String get settingsAppSection => 'Aplikasi';

  @override
  String get settingsAboutApp => 'Tentang aplikasi';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get settingsDarkMode => 'Mode Gelap';

  @override
  String get settingsLanguageLabel => 'Bahasa';

  @override
  String get languageIndonesian => 'Indonesia';

  @override
  String get languageEnglish => 'English';

  @override
  String get dialogCancel => 'Batal';

  @override
  String get commonSave => 'Simpan';

  @override
  String get commonSaveChanges => 'Simpan perubahan';

  @override
  String get commonDelete => 'Hapus';

  @override
  String get commonClose => 'Tutup';

  @override
  String get commonAsset => 'Aset';

  @override
  String get commonCategoryLabel => 'Kategori';

  @override
  String get commonRecordedAtLabel => 'Tanggal pencatatan';

  @override
  String get commonSelectDatePlaceholder => 'Pilih tanggal';

  @override
  String get commonCurrentValueLabel => 'Nilai saat ini';

  @override
  String get commonTotalCostOptionalLabel => 'Total modal (opsional)';

  @override
  String get commonReturnLabel => 'Return';

  @override
  String get profitLossGainLabel => 'Untung';

  @override
  String get profitLossLossLabel => 'Rugi';

  @override
  String get commonEmptyAssetsTitle => 'Belum ada aset';

  @override
  String get commonAddAssetLabel => 'Tambah aset';

  @override
  String get commonAddTargetLabel => 'Tambah target';

  @override
  String get commonEmptyTargetsTitle => 'Belum ada target alokasi';

  @override
  String get commonDeleteHistoryTitle => 'Hapus histori?';

  @override
  String get commonDeleteHistoryMessage =>
      'Entri histori bulan ini akan dihapus.';

  @override
  String get commonHistoryDeletedMessage => 'Histori dihapus.';

  @override
  String get commonDeleteHistoryFailedMessage => 'Gagal menghapus histori.';

  @override
  String get commonEmptyHistoryTitle => 'Belum ada histori';

  @override
  String get updateAssetValueTitle => 'Update nilai aset';

  @override
  String get assetDropdownLabel => 'Aset';

  @override
  String get updateTypeLabel => 'Tipe pembaruan';

  @override
  String get updateTypeOverride => 'Ubah';

  @override
  String get updateTypeIncrement => 'Tambah';

  @override
  String get totalValueFieldLabel => 'Total nilai aset';

  @override
  String get incrementValueFieldLabel => 'Penambahan nilai';

  @override
  String get totalValueFieldHelper =>
      'Nilai aset akan disesuaikan menjadi nominal ini.';

  @override
  String get incrementValueFieldHelper =>
      'Nominal ini akan ditambahkan ke nilai aset saat ini.';

  @override
  String get totalCostFieldHelper =>
      'Total dana yang sudah disetor. Kosongkan bila modal tidak berubah.';

  @override
  String get incrementCostFieldLabel => 'Penambahan modal (opsional)';

  @override
  String get incrementCostFieldHelper =>
      'Dana yang baru disetor. Kosongkan bila penambahan berasal dari hasil investasi.';

  @override
  String get noteFieldLabel => 'Catatan (opsional)';

  @override
  String get previewLabel => 'Preview';

  @override
  String get addedValueLabel => 'Tambahan nilai';

  @override
  String get latestValueLabel => 'Nilai terbaru';

  @override
  String get currentCostLabel => 'Modal saat ini';

  @override
  String get addedCostLabel => 'Tambahan modal';

  @override
  String get latestCostLabel => 'Modal terbaru';

  @override
  String assetValueUpdatedMessage(String assetName) {
    return 'Nilai $assetName berhasil diperbarui.';
  }

  @override
  String get updateAssetValueFailedMessage =>
      'Pembaruan nilai aset belum berhasil. Coba lagi.';

  @override
  String get historyTitle => 'Histori';

  @override
  String get historyTwrSinceStartLabel => 'Return sejak awal';

  @override
  String historyTwrYearLabel(String year) {
    return 'Return $year';
  }

  @override
  String get historyTwrAnnualizedLabel => 'Per tahun';

  @override
  String get historyTwrCaption =>
      'Time-weighted return: tidak terpengaruh setoran, mengukur hasil strategi';

  @override
  String get emptyHistoryMessage =>
      'Histori muncul setelah nilai aset dicatat.';

  @override
  String get allFilterLabel => 'Semua';

  @override
  String get noFilteredDataTitle => 'Tidak ada data pada filter ini';

  @override
  String get noFilteredDataMessage => 'Pilih tahun lain.';

  @override
  String get initialDataLabel => 'Data awal';

  @override
  String get assetNotFoundTitle => 'Aset tidak ditemukan';

  @override
  String get assetNotFoundMessage => 'Data aset yang Anda buka tidak tersedia.';

  @override
  String get totalCostLabel => 'Total modal';

  @override
  String get allocationLabel => 'Alokasi portofolio';

  @override
  String get lastUpdatedLabel => 'Terakhir diperbarui';

  @override
  String get updateValueButton => 'Update nilai';

  @override
  String get historySectionTitle => 'Histori nilai';

  @override
  String get emptyAssetHistoryMessage =>
      'Histori muncul setelah nilai diperbarui.';

  @override
  String get defaultAssetDetailTitle => 'Detail aset';

  @override
  String get editAssetTooltip => 'Edit aset';

  @override
  String get targetNotFoundMessage => 'Target tidak ditemukan.';

  @override
  String get editTargetTitle => 'Edit target';

  @override
  String get addTargetTitle => 'Tambah target';

  @override
  String get targetAllocationLabel => 'Target alokasi';

  @override
  String get deleteTargetButton => 'Hapus target';

  @override
  String get targetPercentageRequired => 'Target alokasi wajib diisi.';

  @override
  String get targetPercentageInvalid => 'Target alokasi tidak valid.';

  @override
  String get targetPercentageRange =>
      'Target alokasi harus di antara 0 sampai 100%.';

  @override
  String get targetSaveFailedMessage =>
      'Target belum berhasil disimpan. Coba lagi.';

  @override
  String get deleteTargetTitle => 'Hapus target?';

  @override
  String deleteTargetMessage(String category) {
    return 'Target $category akan dihapus.';
  }

  @override
  String get targetDeleteFailedMessage =>
      'Target belum berhasil dihapus. Coba lagi.';

  @override
  String get targetPercentageExceededMessage =>
      'Total target alokasi tidak boleh lebih dari 100%.';

  @override
  String get restoreTitle => 'Pulihkan dari backup';

  @override
  String get backupListLoadFailedTitle => 'Daftar backup gagal dimuat';

  @override
  String get emptyBackupTitle => 'Belum ada backup';

  @override
  String get emptyBackupMessage => 'Backup pertama Anda akan muncul di sini.';

  @override
  String get restoreDataTitle => 'Pulihkan data ini?';

  @override
  String restoreDataMessage(String date) {
    return 'Data portofolio saat ini akan diganti dengan backup $date. Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get restoreLabel => 'Pulihkan';

  @override
  String get restoreSuccessMessage => 'Data berhasil dipulihkan.';

  @override
  String get restoreFailedMessage => 'Pemulihan gagal. Coba lagi.';

  @override
  String get assetNotFoundFormMessage => 'Aset tidak ditemukan.';

  @override
  String get editAssetTitle => 'Edit aset';

  @override
  String get addAssetTitle => 'Tambah aset';

  @override
  String get assetNameLabel => 'Nama aset';

  @override
  String get assetNameRequired => 'Nama aset wajib diisi.';

  @override
  String get assetCodeLabel => 'Kode aset';

  @override
  String get assetCodeRequired => 'Kode aset wajib diisi.';

  @override
  String get initialValueLabel => 'Nilai awal';

  @override
  String get totalCostOptionalHelper =>
      'Total dana yang disetor, untuk menghitung untung/rugi.';

  @override
  String get deleteAssetButton => 'Hapus aset';

  @override
  String get deleteAssetTitle => 'Hapus aset?';

  @override
  String deleteAssetMessage(String assetName) {
    return 'Aset $assetName dan histori nilainya akan dihapus.';
  }

  @override
  String get assetSaveFailedMessage =>
      'Aset belum berhasil disimpan. Coba lagi.';

  @override
  String get targetDetailTitle => 'Detail target';

  @override
  String get editTargetTooltip => 'Edit target';

  @override
  String get targetNotFoundTitle => 'Target tidak ditemukan';

  @override
  String get targetNotFoundDetailMessage =>
      'Data target yang Anda buka tidak tersedia.';

  @override
  String get actualValueLabel => 'Nilai aktual';

  @override
  String get targetValueLabel => 'Nilai target';

  @override
  String assetsInCategoryTitle(String category) {
    return 'Aset $category';
  }

  @override
  String get emptyAssetsInCategoryMessage =>
      'Belum ada aset pada kategori ini.';

  @override
  String get reasonableRangeTitle => 'Batas wajar';

  @override
  String toleranceInfoText(String lower, String upper, String tolerance) {
    return '$lower - $upper (toleransi ±$tolerance)';
  }

  @override
  String get toleranceRuleExplanation =>
      'Mengikuti aturan 5/25: penyesuaian baru diperlukan saat alokasi melewati 5 poin persen atau 25% dari target, mana yang lebih kecil.';

  @override
  String get assetsTitle => 'Aset';

  @override
  String get addAssetTooltip => 'Tambah aset';

  @override
  String get emptyAssetsListMessage =>
      'Tambahkan aset pertama untuk mulai mencatat nilai.';

  @override
  String get inactiveAssetsLabel => 'Aset nonaktif';

  @override
  String get targetTitle => 'Target';

  @override
  String get addTargetTooltip => 'Tambah target';

  @override
  String get emptyTargetsMessage =>
      'Tentukan porsi ideal tiap kategori aset supaya progres portofolio bisa dihitung.';

  @override
  String get connectGoogleMessage =>
      'Hubungkan akun Google untuk mem-backup data portofolio Anda.';

  @override
  String get connectGoogleButton => 'Hubungkan akun Google';

  @override
  String get connectedAccountFallback => 'Akun Google terhubung';

  @override
  String get disconnectButton => 'Putuskan';

  @override
  String get autoBackupLabel => 'Backup otomatis';

  @override
  String get restoringMessage => 'Sedang memulihkan data...';

  @override
  String get neverBackedUpMessage => 'Belum pernah backup.';

  @override
  String lastBackupMessage(String date) {
    return 'Backup terakhir: $date';
  }

  @override
  String get backupNowButton => 'Backup sekarang';

  @override
  String get restoreFromBackupButton => 'Pulihkan dari backup';

  @override
  String get confirmBackupTitle => 'Backup sekarang?';

  @override
  String get confirmBackupMessage =>
      'Salinan data portofolio saat ini akan diunggah ke Google Drive dan menghitung ulang jadwal backup otomatis berikutnya.';

  @override
  String get backupLabel => 'Backup';

  @override
  String get confirmDisconnectTitle => 'Putuskan akun Google?';

  @override
  String get confirmDisconnectMessage =>
      'Backup otomatis akan berhenti dan aplikasi tidak lagi punya akses ke Google Drive. Data di perangkat dan backup yang sudah ada tidak dihapus.';

  @override
  String get connectFailedMessage => 'Gagal menghubungkan akun Google.';

  @override
  String get backupFailedMessage => 'Backup gagal. Coba lagi nanti.';

  @override
  String get googleNotConnectedMessage => 'Akun Google belum terhubung.';

  @override
  String get googleAuthorizationRequiredMessage =>
      'Otorisasi Google Drive dibutuhkan.';

  @override
  String get invalidBackupFileMessage => 'File backup tidak valid.';

  @override
  String get emptyAssetsDashboardMessage =>
      'Catat aset pertama untuk melihat ringkasan.';

  @override
  String get noTargetsCardMessage =>
      'Buat target alokasi dulu agar progres portofolio bisa dihitung dengan benar.';

  @override
  String get mainAssetsTitle => 'Aset utama';

  @override
  String get viewAllLabel => 'Lihat semua';

  @override
  String get invalidCurrentValueMessage =>
      'Nilai aset tidak boleh kurang dari nol.';

  @override
  String get invalidTotalCostMessage =>
      'Total modal tidak boleh kurang dari nol.';

  @override
  String get dashboardPortfolioValueLabel => 'Total Ekuitas';

  @override
  String get dashboardCashLabel => 'Kas';

  @override
  String get dashboardCapitalLabel => 'Investasi';

  @override
  String get dashboardAssetCountLabel => 'Jumlah Aset';

  @override
  String get dashboardProfitLossLabel => 'P&L';

  @override
  String get dashboardViewHistoryLabel => 'Lihat histori';

  @override
  String dashboardTotalPortfolioSemantic(String totalValue, String cash) {
    return 'Total portofolio $totalValue. Kas $cash';
  }

  @override
  String dashboardProfitLossSemantic(
    String cost,
    String profitLossLabel,
    String amount,
  ) {
    return 'Modal $cost. $profitLossLabel $amount';
  }

  @override
  String get assetTableCodeHeader => 'Kode';

  @override
  String get assetTableNameHeader => 'Nama';

  @override
  String get assetTableAllocationHeader => 'Alokasi';

  @override
  String get assetTableValueHeader => 'Nilai';

  @override
  String get assetTableUpdatedHeader => 'Diperbarui';

  @override
  String get assetTableCurrentPriceHeader => 'Harga Kini';

  @override
  String get assetTableProfitLossHeader => 'U/R';

  @override
  String assetSemanticValueAllocation(String value, String allocation) {
    return 'Nilai $value, alokasi $allocation';
  }

  @override
  String assetSemanticCostProfitLoss(
    String cost,
    String profitLossWord,
    String amount,
  ) {
    return 'Modal $cost, $profitLossWord $amount';
  }

  @override
  String historyChartSemanticLabelWithCost(
    String startMonth,
    String endMonth,
    String minValue,
    String maxValue,
  ) {
    return 'Grafik nilai dan modal $startMonth sampai $endMonth, terendah $minValue, tertinggi $maxValue';
  }

  @override
  String historyChartSemanticLabelValueOnly(
    String startMonth,
    String endMonth,
    String minValue,
    String maxValue,
  ) {
    return 'Grafik nilai $startMonth sampai $endMonth, terendah $minValue, tertinggi $maxValue';
  }

  @override
  String get historyChartPlaceholderMessage =>
      'Grafik muncul setelah ada minimal dua pencatatan nilai.';

  @override
  String allocationBadgeSemanticLabel(String percentage) {
    return 'Alokasi $percentage dari portofolio';
  }

  @override
  String get targetProgressDefaultLabel => 'Target Alokasi';

  @override
  String get targetProgressDefaultSubtitle => 'Alokasi portofolio ideal';

  @override
  String targetProgressSemanticLabel(
    String label,
    String percentage,
    String subtitle,
  ) {
    return '$label $percentage persen. $subtitle';
  }

  @override
  String categoryDonutSemanticItem(String category, String percentage) {
    return '$category $percentage persen';
  }

  @override
  String categoryDonutSemanticLabel(String summary) {
    return 'Grafik alokasi aktual per kategori: $summary';
  }

  @override
  String categoryDonutCategoryCount(int count) {
    return '$count Kategori';
  }

  @override
  String targetAllocationActualOfTarget(String actual, String target) {
    return 'Aktual $actual dari target $target';
  }

  @override
  String targetAllocationProgressSemanticLabel(String category) {
    return 'Progres alokasi $category';
  }

  @override
  String get sectionHeaderInfoTooltip => 'Info';

  @override
  String get appErrorDefaultTitle => 'Data belum dapat dimuat.';

  @override
  String get appErrorDefaultMessage =>
      'Terjadi kesalahan saat membaca data. Coba lagi.';

  @override
  String get appErrorRetryButtonLabel => 'Coba lagi';

  @override
  String get marketPriceTitle => 'Harga Pasar';

  @override
  String get marketSymbolLabel => 'Simbol Yahoo Finance (opsional)';

  @override
  String get marketSymbolHelper => 'Contoh: BMRI.JK · BTC-USD · SPY';

  @override
  String marketAsOf(String dateTime) {
    return 'per $dateTime';
  }

  @override
  String get marketOfflineChip => 'Offline';

  @override
  String get marketLoading => 'Memuat harga…';

  @override
  String get marketUnavailableShort => 'Harga tidak tersedia';

  @override
  String marketSymbolNotFound(String symbol) {
    return 'Simbol $symbol tidak ditemukan di Yahoo Finance.';
  }

  @override
  String get marketUnavailable =>
      'Harga belum bisa dimuat. Tarik untuk coba lagi.';

  @override
  String get marketChartEmpty => 'Data chart belum tersedia.';

  @override
  String get marketStatsTitle => 'Data Perdagangan';

  @override
  String get statPrevClose => 'Penutupan Sebelumnya';

  @override
  String get statDayHigh => 'Tertinggi Hari Ini';

  @override
  String get statDayLow => 'Terendah Hari Ini';

  @override
  String get statVolume => 'Volume';

  @override
  String get statFiftyTwoWeekHigh => 'Tertinggi 52 Minggu';

  @override
  String get statFiftyTwoWeekLow => 'Terendah 52 Minggu';

  @override
  String get editAssetButton => 'Edit Aset';

  @override
  String get chartRange1D => '1D';

  @override
  String get chartRange1W => '1W';

  @override
  String get chartRange1M => '1B';

  @override
  String get chartRange3M => '3B';

  @override
  String get chartRangeYTD => 'YTD';

  @override
  String get chartRange1Y => '1T';

  @override
  String get chartRange3Y => '3T';

  @override
  String get chartRange5Y => '5T';

  @override
  String get chartPeriodToday => 'Hari Ini';

  @override
  String get chartPeriodPastWeek => '1 Minggu Terakhir';

  @override
  String get chartPeriodPastMonth => '1 Bulan Terakhir';

  @override
  String get chartPeriodPastThreeMonths => '3 Bulan Terakhir';

  @override
  String get chartPeriodYearToDate => 'Sejak Awal Tahun';

  @override
  String get chartPeriodPastYear => '1 Tahun Terakhir';

  @override
  String get chartPeriodPastThreeYears => '3 Tahun Terakhir';

  @override
  String get chartPeriodPastFiveYears => '5 Tahun Terakhir';

  @override
  String get avgBuyPriceLabel => 'Harga rata-rata beli';

  @override
  String get avgBuyPriceOptionalLabel => 'Harga rata-rata beli (opsional)';

  @override
  String get avgBuyPriceHelper =>
      'Harga per unit di mata uang aslinya. Contoh: BMRI dalam IDR, SPY dalam USD.';

  @override
  String get quantityOptionalLabel => 'Jumlah unit (opsional)';

  @override
  String get quantityLabel => 'Jumlah unit';

  @override
  String get quantityHelper =>
      'Jumlah lot, lembar, koin, atau gram yang dimiliki.';

  @override
  String get priceCurrencyLabel => 'Mata uang harga beli';

  @override
  String valueSuggestionChip(String value) {
    return 'Pakai saran: $value';
  }

  @override
  String valueSuggestionDetail(String quantity, String price) {
    return '$quantity unit × $price (harga terkini)';
  }

  @override
  String valueSuggestionFxDetail(String currency, String rate) {
    return 'Kurs: 1 $currency = $rate';
  }
}
