import 'package:flutter_wasilah_app/features/portfolio/models/allocation_target.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/portfolio_summary.dart';

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
