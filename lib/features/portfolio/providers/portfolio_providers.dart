import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/allocation_target.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/portfolio_summary.dart';
import 'package:flutter_wasilah_app/features/portfolio/repository/drift_portfolio_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/repository/portfolio_repository.dart';

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return DriftPortfolioRepository(ref.watch(appDatabaseProvider));
});

final portfolioSummaryProvider = FutureProvider<PortfolioSummary>((ref) async {
  final repository = ref.watch(portfolioRepositoryProvider);
  return repository.getPortfolioSummary();
});

final assetListProvider = FutureProvider<List<Asset>>((ref) async {
  final repository = ref.watch(portfolioRepositoryProvider);
  return repository.getAssets();
});

final assetDetailProvider = FutureProvider.family<Asset?, String>((
  ref,
  assetId,
) async {
  final repository = ref.watch(portfolioRepositoryProvider);
  return repository.getAssetById(assetId);
});

final portfolioHistoryProvider = FutureProvider<List<AssetSnapshot>>((
  ref,
) async {
  final repository = ref.watch(portfolioRepositoryProvider);
  return repository.getPortfolioHistory();
});

final assetHistoryProvider = FutureProvider.family<List<AssetSnapshot>, String>((
  ref,
  assetId,
) async {
  final repository = ref.watch(portfolioRepositoryProvider);
  return repository.getAssetHistory(assetId);
});

final allocationTargetProvider = FutureProvider<List<AllocationTarget>>((
  ref,
) async {
  final repository = ref.watch(portfolioRepositoryProvider);
  return repository.getAllocationTargets();
});
