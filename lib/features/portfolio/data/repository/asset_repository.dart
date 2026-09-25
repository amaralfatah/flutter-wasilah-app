import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';

/// CRUD master data aset (`assets`). Nilai porto (current value, modal,
/// dst) hidup di `PortfolioRepository`, bukan di sini.
abstract interface class AssetRepository {
  Future<List<Asset>> getAssets();

  Future<Asset?> getAssetById(String assetId);

  Future<void> createAsset(Asset asset);

  Future<void> updateAsset(Asset asset);

  /// Menghapus master aset. Melempar `AssetHasHoldingException` (lihat
  /// `core/errors/app_exceptions.dart`) bila aset masih punya holding porto
  /// dan/atau histori snapshot -- keluarkan dari portofolio dulu.
  Future<void> deleteAsset(String assetId);
}
