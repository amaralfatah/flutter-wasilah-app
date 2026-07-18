import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/allocation_target.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_summary.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/drift_portfolio_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/portfolio_repository.dart';

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

final FutureProviderFamily<Asset?, String> assetDetailProvider =
    FutureProvider.family<Asset?, String>((
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

final FutureProviderFamily<List<AssetSnapshot>, String> assetHistoryProvider =
    FutureProvider.family<List<AssetSnapshot>, String>(
      (ref, assetId) async {
        final repository = ref.watch(portfolioRepositoryProvider);
        return repository.getAssetHistory(assetId);
      },
    );

final allocationTargetProvider = FutureProvider<List<AllocationTarget>>((
  ref,
) async {
  final repository = ref.watch(portfolioRepositoryProvider);
  return repository.getAllocationTargets();
});
