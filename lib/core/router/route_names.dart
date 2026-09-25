abstract final class RouteNames {
  static const String dashboard = '/dashboard';
  static const String history = '/history';

  // Portofolio (holding): nilai, modal, histori per aset.
  static const String portfolio = '/portfolio';
  static const String portfolioUpdate = '/portfolio/update';
  static const String portfolioMarketSegment = 'market';

  // Master aset: identitas aset, dikelola dari Pengaturan.
  static const String masterAssets = '/settings/assets';
  static const String masterAssetCreate = '/settings/assets/new';

  static const String target = '/target';
  static const String targetCreate = '/target/new';
  static const String settings = '/settings';
  static const String backupRestore = '/settings/backup/restore';
}
