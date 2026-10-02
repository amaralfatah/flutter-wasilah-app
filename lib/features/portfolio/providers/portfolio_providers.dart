import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/features/market/data/models/market_quote.dart';
import 'package:flutter_wasilah_app/features/market/providers/market_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/market_valuation.dart';
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
  return ref.watch(portfolioRepositoryProvider).changes.map((_) => ++revision);
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

/// Ringkasan portofolio dengan nilai holding mengikuti harga pasar (lihat
/// [positionListProvider]). Perubahan bulanan tetap dari histori tercatat.
final portfolioSummaryProvider = FutureProvider<PortfolioSummary>((ref) async {
  ref.watch(portfolioChangesProvider);
  final repository = ref.watch(portfolioRepositoryProvider);
  final positionsFuture = ref.watch(positionListProvider.future);
  final targetsFuture = ref.watch(allocationTargetProvider.future);
  final summary = await repository.getPortfolioSummary();
  final positions = await positionsFuture;
  return summary.copyWith(
    positions: positions,
    totalValue: positions.fold<double>(
      0,
      (sum, position) => sum + position.currentValue,
    ),
    targetProgressPercentage: calculateTargetProgress(
      positions,
      await targetsFuture,
    ),
  );
});

/// Posisi persis seperti tercatat di database (nilai = snapshot terakhir).
/// Dipakai form update nilai, yang butuh nilai tercatat, bukan nilai pasar.
final storedPositionListProvider = FutureProvider<List<PortfolioPosition>>((
  ref,
) async {
  ref.watch(portfolioChangesProvider);
  final repository = ref.watch(portfolioRepositoryProvider);
  return repository.getPositions();
});

/// Quote harga pasar holding yang dinilai pasar, plus kurs forex ke IDR
/// yang dibutuhkannya, per simbol. Memancarkan cache dulu supaya layar
/// langsung terisi (juga saat offline), lalu hasil fetch baru. Simbol yang
/// gagal di-fetch memakai cache-nya, atau dilewati bila tak ada cache.
/// `ref.invalidate` provider ini untuk mengambil ulang harga.
final holdingQuotesProvider = StreamProvider<Map<String, MarketQuote>>((
  ref,
) async* {
  // Kunci berupa string supaya provider hanya dibangun ulang saat daftar
  // simbol berubah, bukan setiap kali nilai holding ditulis.
  final symbolsKey = await ref.watch(
    storedPositionListProvider.selectAsync(
      (positions) =>
          (positions.map(marketValuationSymbolOf).nonNulls.toSet().toList()
                ..sort())
              .join(' '),
    ),
  );
  if (symbolsKey.isEmpty) {
    yield const {};
    return;
  }
  final symbols = symbolsKey.split(' ');
  final repository = ref.read(marketRepositoryProvider);

  Set<String> fxSymbolsOf(Map<String, MarketQuote> quotes) => {
    for (final symbol in symbols)
      if (quotes[symbol]?.currency.toUpperCase() case final currency?
          when currency != 'IDR')
        fxSymbolOf(currency),
  };

  Future<void> addCached(
    Map<String, MarketQuote> quotes,
    Iterable<String> symbols,
  ) async {
    for (final symbol in symbols) {
      if (await repository.getCachedQuote(symbol) case final quote?) {
        quotes[symbol] = quote;
      }
    }
  }

  Future<void> addFresh(
    Map<String, MarketQuote> quotes,
    Iterable<String> symbols,
  ) async {
    await Future.wait([
      for (final symbol in symbols)
        repository
            .getQuote(symbol)
            .then<void>((result) => quotes[symbol] = result.quote)
            .catchError((Object _) {}),
    ]);
  }

  final cached = <String, MarketQuote>{};
  await addCached(cached, symbols);
  await addCached(cached, fxSymbolsOf(cached));
  yield Map.unmodifiable(cached);

  final fresh = {...cached};
  await addFresh(fresh, symbols);
  await addFresh(fresh, fxSymbolsOf(fresh));
  yield Map.unmodifiable(fresh);
});

/// Posisi portofolio; nilai holding saham, kripto, dan ETF yang punya simbol
/// pasar serta jumlah unit mengikuti harga pasar terkini (lihat
/// `applyMarketPrices`). Tidak menunggu harga: sebelum quote ada, nilai
/// tercatat yang dipakai.
final positionListProvider = FutureProvider<List<PortfolioPosition>>((
  ref,
) async {
  final quotes = ref.watch(holdingQuotesProvider).valueOrNull;
  final positions = await ref.watch(storedPositionListProvider.future);
  return applyMarketPrices(positions, quotes ?? const {});
});

final FutureProviderFamily<PortfolioPosition?, String> positionDetailProvider =
    FutureProvider.family<PortfolioPosition?, String>((
      ref,
      assetId,
    ) async {
      final positions = await ref.watch(positionListProvider.future);
      return positions.where((position) => position.id == assetId).firstOrNull;
    });

/// Semua master aset beserta holding-nya; aset yang belum di porto muncul
/// sebagai [PortfolioPosition.empty]. Urutan: yang dipegang (nilai terbesar
/// dulu), lalu sisanya menurut nama. Nilainya nilai tercatat, bukan harga
/// pasar: dipakai form update nilai.
final assetOverviewProvider = FutureProvider<List<PortfolioPosition>>((
  ref,
) async {
  final assets = await ref.watch(assetListProvider.future);
  final positions = await ref.watch(storedPositionListProvider.future);
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
