import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/allocation_target.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_summary.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/asset_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/drift_asset_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/drift_portfolio_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/portfolio_repository.dart';

/// Naik setiap kali data aset/portofolio ditulis. Semua provider baca
/// menonton ini, jadi layar ikut segar tanpa `invalidate` manual. Nilainya
/// angka yang terus naik karena `AsyncData(null)` berulang dianggap sama dan
/// tidak memicu rebuild.
final portfolioChangesProvider = StreamProvider<int>((ref) {
  var revision = 0;
  return ref
      .watch(portfolioRepositoryProvider)
      .changes
      .map((_) => ++revision);
});

// ======================= MASTER ASET =======================

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return DriftAssetRepository(ref.watch(appDatabaseProvider));
});

final assetListProvider = FutureProvider<List<Asset>>((ref) async {
  ref.watch(portfolioChangesProvider);
  final repository = ref.watch(assetRepositoryProvider);
  return repository.getAssets();
});

final FutureProviderFamily<Asset?, String> assetDetailProvider =
    FutureProvider.family<Asset?, String>((
      ref,
      assetId,
    ) async {
      ref.watch(portfolioChangesProvider);
      final repository = ref.watch(assetRepositoryProvider);
      return repository.getAssetById(assetId);
    });

// ======================= PORTOFOLIO ========================

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return DriftPortfolioRepository(ref.watch(appDatabaseProvider));
});

final portfolioSummaryProvider = FutureProvider<PortfolioSummary>((ref) async {
  ref.watch(portfolioChangesProvider);
  final repository = ref.watch(portfolioRepositoryProvider);
  return repository.getPortfolioSummary();
});

final positionListProvider = FutureProvider<List<PortfolioPosition>>((
  ref,
) async {
  ref.watch(portfolioChangesProvider);
  final repository = ref.watch(portfolioRepositoryProvider);
  return repository.getPositions();
});

final FutureProviderFamily<PortfolioPosition?, String> positionDetailProvider =
    FutureProvider.family<PortfolioPosition?, String>((
      ref,
      assetId,
    ) async {
      ref.watch(portfolioChangesProvider);
  final repository = ref.watch(portfolioRepositoryProvider);
      return repository.getPositionByAssetId(assetId);
    });

/// Semua master aset beserta holding-nya; aset yang belum di porto muncul
/// sebagai [PortfolioPosition.empty]. Urutan: yang dipegang (nilai terbesar
/// dulu), lalu sisanya menurut nama.
final assetOverviewProvider = FutureProvider<List<PortfolioPosition>>((
  ref,
) async {
  final assets = await ref.watch(assetListProvider.future);
  final positions = await ref.watch(positionListProvider.future);
  final heldIds = {for (final position in positions) position.id};
  return [
    ...positions,
    for (final asset in assets)
      if (!heldIds.contains(asset.id)) PortfolioPosition.empty(asset),
  ];
});

final portfolioHistoryProvider = FutureProvider<List<PortfolioSnapshot>>((
  ref,
) async {
  ref.watch(portfolioChangesProvider);
  final repository = ref.watch(portfolioRepositoryProvider);
  return repository.getPortfolioHistory();
});

final FutureProviderFamily<List<AssetSnapshot>, String> assetHistoryProvider =
    FutureProvider.family<List<AssetSnapshot>, String>(
      (ref, assetId) async {
        ref.watch(portfolioChangesProvider);
  final repository = ref.watch(portfolioRepositoryProvider);
        return repository.getAssetHistory(assetId);
      },
    );

final allocationTargetProvider = FutureProvider<List<AllocationTarget>>((
  ref,
) async {
  ref.watch(portfolioChangesProvider);
  final repository = ref.watch(portfolioRepositoryProvider);
  return repository.getAllocationTargets();
});
