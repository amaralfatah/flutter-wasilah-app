import 'dart:async';

import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/allocation_target.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/holding.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_summary.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/asset_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/portfolio_repository.dart';

/// Implementasi in-memory untuk master aset sekaligus porto, dengan state
/// bersama supaya satu instance bisa dipasang ke kedua provider repository.
class MockPortfolioRepository implements AssetRepository, PortfolioRepository {
  MockPortfolioRepository({
    this.simulatedDelay = const Duration(milliseconds: 250),
  });

  final Duration simulatedDelay;

  final List<Asset> _assets = [
    const Asset(
      id: 'btc',
      name: 'Bitcoin',
      code: 'BTC',
      category: AssetCategory.crypto,
    ),
    const Asset(
      id: 'bmri',
      name: 'Bank Mandiri',
      code: 'BMRI',
      category: AssetCategory.stock,
    ),
    const Asset(
      id: 'bbri',
      name: 'Bank Rakyat Indonesia',
      code: 'BBRI',
      category: AssetCategory.stock,
    ),
    const Asset(
      id: 'rd',
      name: 'Reksa Dana',
      code: 'RDPT',
      category: AssetCategory.mutualFund,
    ),
    const Asset(
      id: 'cash',
      name: 'Kas',
      code: 'CASH',
      category: AssetCategory.cash,
    ),
  ];

  final Map<String, Holding> _holdings = {
    'btc': Holding(
      assetId: 'btc',
      currentValue: 18200000,
      lastUpdatedAt: DateTime(2026, 7, 15),
    ),
    'bmri': Holding(
      assetId: 'bmri',
      currentValue: 10700000,
      lastUpdatedAt: DateTime(2026, 7, 15),
    ),
    'bbri': Holding(
      assetId: 'bbri',
      currentValue: 10200000,
      lastUpdatedAt: DateTime(2026, 7, 15),
    ),
    'rd': Holding(
      assetId: 'rd',
      currentValue: 9300000,
      lastUpdatedAt: DateTime(2026, 7, 14),
    ),
    'cash': Holding(
      assetId: 'cash',
      currentValue: 6600000,
      lastUpdatedAt: DateTime(2026, 7, 12),
    ),
  };

  final Map<String, List<AssetSnapshot>> _assetHistories = {
    'btc': [
      AssetSnapshot(
        id: 'btc-20260715',
        assetId: 'btc',
        totalValue: 18200000,
        recordedAt: DateTime(2026, 7, 15),
        note: 'Rekap nilai Juli',
      ),
      AssetSnapshot(
        id: 'btc-20260615',
        assetId: 'btc',
        totalValue: 17400000,
        recordedAt: DateTime(2026, 6, 15),
      ),
    ],
    'bmri': [
      AssetSnapshot(
        id: 'bmri-20260715',
        assetId: 'bmri',
        totalValue: 10700000,
        recordedAt: DateTime(2026, 7, 15),
      ),
      AssetSnapshot(
        id: 'bmri-20260615',
        assetId: 'bmri',
        totalValue: 10200000,
        recordedAt: DateTime(2026, 6, 15),
      ),
    ],
    'bbri': [
      AssetSnapshot(
        id: 'bbri-20260715',
        assetId: 'bbri',
        totalValue: 10200000,
        recordedAt: DateTime(2026, 7, 15),
      ),
      AssetSnapshot(
        id: 'bbri-20260615',
        assetId: 'bbri',
        totalValue: 9900000,
        recordedAt: DateTime(2026, 6, 15),
      ),
    ],
    'rd': [
      AssetSnapshot(
        id: 'rd-20260714',
        assetId: 'rd',
        totalValue: 9300000,
        recordedAt: DateTime(2026, 7, 14),
      ),
      AssetSnapshot(
        id: 'rd-20260614',
        assetId: 'rd',
        totalValue: 9100000,
        recordedAt: DateTime(2026, 6, 14),
      ),
    ],
    'cash': [
      AssetSnapshot(
        id: 'cash-20260712',
        assetId: 'cash',
        totalValue: 6600000,
        recordedAt: DateTime(2026, 7, 12),
      ),
      AssetSnapshot(
        id: 'cash-20260612',
        assetId: 'cash',
        totalValue: 6600000,
        recordedAt: DateTime(2026, 6, 12),
      ),
    ],
  };

  final List<PortfolioSnapshot> _portfolioHistory = [
    PortfolioSnapshot(
      id: 'portfolio-20260715',
      totalValue: 55000000,
      recordedAt: DateTime(2026, 7, 15),
    ),
    PortfolioSnapshot(
      id: 'portfolio-20260615',
      totalValue: 53200000,
      recordedAt: DateTime(2026, 6, 15),
    ),
    PortfolioSnapshot(
      id: 'portfolio-20260515',
      totalValue: 51500000,
      recordedAt: DateTime(2026, 5, 15),
    ),
    PortfolioSnapshot(
      id: 'portfolio-20260415',
      totalValue: 49800000,
      recordedAt: DateTime(2026, 4, 15),
    ),
  ];

  final List<AllocationTarget> _targets = [
    const AllocationTarget(
      id: 'target-crypto',
      category: AssetCategory.crypto,
      targetPercentage: 35,
    ),
    const AllocationTarget(
      id: 'target-stock',
      category: AssetCategory.stock,
      targetPercentage: 40,
    ),
    const AllocationTarget(
      id: 'target-mutual-fund',
      category: AssetCategory.mutualFund,
      targetPercentage: 15,
    ),
    const AllocationTarget(
      id: 'target-cash',
      category: AssetCategory.cash,
      targetPercentage: 10,
    ),
  ];

  double _monthlyChangePercentage = 3.4;
  double _targetProgressPercentage = 88.3;

  // ---------------------------------------------------------------- master

  @override
  Future<List<Asset>> getAssets() async {
    await _wait();
    return _assets.toList(growable: false);
  }

  @override
  Future<Asset?> getAssetById(String assetId) async {
    await _wait();
    return _assets.where((asset) => asset.id == assetId).firstOrNull;
  }

  @override
  Future<void> createAsset(Asset asset) async {
    await _beginWrite();

    if (_assets.any((item) => item.id == asset.id)) {
      throw StateError('Asset sudah ada.');
    }
    _assets.add(asset);
  }

  @override
  Future<void> updateAsset(Asset asset) async {
    await _beginWrite();

    final assetIndex = _assets.indexWhere((item) => item.id == asset.id);
    if (assetIndex == -1) {
      throw StateError('Asset tidak ditemukan.');
    }
    _assets[assetIndex] = asset;
  }

  @override
  Future<void> deleteAsset(String assetId) async {
    await _beginWrite();

    if (_holdings.containsKey(assetId) ||
        (_assetHistories[assetId]?.isNotEmpty ?? false)) {
      throw const AssetHasHoldingException();
    }
    _assets.removeWhere((asset) => asset.id == assetId);
  }

  // ----------------------------------------------------------------- porto

  @override
  Future<List<PortfolioPosition>> getPositions() async {
    await _wait();
    return _positions();
  }

  @override
  Future<PortfolioPosition?> getPositionByAssetId(String assetId) async {
    await _wait();
    return _positions().where((position) => position.id == assetId).firstOrNull;
  }

  @override
  Future<List<AssetSnapshot>> getAssetHistory(String assetId) async {
    await _wait();
    return (_assetHistories[assetId] ?? <AssetSnapshot>[]).toList(
      growable: false,
    );
  }

  @override
  Future<List<PortfolioSnapshot>> getPortfolioHistory() async {
    await _wait();
    return _portfolioHistory.toList(growable: false);
  }

  @override
  Future<void> deleteAssetSnapshot(String snapshotId) async {
    await _beginWrite();
    for (final history in _assetHistories.values) {
      history.removeWhere((snapshot) => snapshot.id == snapshotId);
    }
  }

  @override
  Future<void> deletePortfolioSnapshot(String snapshotId) async {
    await _beginWrite();
    _portfolioHistory.removeWhere((snapshot) => snapshot.id == snapshotId);
  }

  @override
  Future<void> removeFromPortfolio(String assetId) async {
    await _beginWrite();
    _holdings.remove(assetId);
    _assetHistories.remove(assetId);
  }

  @override
  Future<PortfolioSummary> getPortfolioSummary() async {
    await _wait();
    final positions = _positions();
    return PortfolioSummary(
      totalValue: _currentTotalValue,
      monthlyChangePercentage: _monthlyChangePercentage,
      targetProgressPercentage: _targetProgressPercentage,
      positions: positions,
      lastUpdatedAt: positions.isEmpty
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : positions
                .map((position) => position.lastUpdatedAt)
                .reduce((latest, next) => latest.isAfter(next) ? latest : next),
    );
  }

  @override
  Future<void> updateAssetValue({
    required String assetId,
    required double totalValue,
    required DateTime recordedAt,
    String? note,
    double? totalCost,
    double? quantity,
    double? avgBuyPrice,
    String? priceCurrency,
    String? fxCurrency,
    double? fxRate,
  }) async {
    await _beginWrite();

    if (!_assets.any((asset) => asset.id == assetId)) {
      throw StateError('Asset tidak ditemukan.');
    }

    final existing = _holdings[assetId];
    final cost = totalCost ?? existing?.totalCost;
    _holdings[assetId] = Holding(
      assetId: assetId,
      currentValue: totalValue,
      lastUpdatedAt: recordedAt,
      totalCost: cost,
      quantity: quantity ?? existing?.quantity,
      avgBuyPrice: avgBuyPrice ?? existing?.avgBuyPrice,
      priceCurrency: priceCurrency ?? existing?.priceCurrency,
    );

    final history = _assetHistories.putIfAbsent(
      assetId,
      () => <AssetSnapshot>[],
    );
    history
      ..removeWhere((item) => _sameMonth(item.recordedAt, recordedAt))
      ..add(
        AssetSnapshot(
          id: '$assetId-${_monthKey(recordedAt)}',
          assetId: assetId,
          totalValue: totalValue,
          recordedAt: recordedAt,
          note: note,
          totalCost: cost,
          fxCurrency: fxCurrency,
          fxRate: fxRate,
        ),
      )
      ..sort((left, right) => right.recordedAt.compareTo(left.recordedAt));

    _portfolioHistory
      ..removeWhere((item) => _sameMonth(item.recordedAt, recordedAt))
      ..add(
        PortfolioSnapshot(
          id: 'portfolio-${_monthKey(recordedAt)}',
          totalValue: _historicalPortfolioTotal(recordedAt),
          recordedAt: recordedAt,
          note: note,
        ),
      )
      ..sort((left, right) => right.recordedAt.compareTo(left.recordedAt));

    _monthlyChangePercentage = _calculateMonthlyChange();
    _targetProgressPercentage = _estimateTargetProgress();
  }

  @override
  Future<List<AllocationTarget>> getAllocationTargets() async {
    await _wait();
    return _targets.toList(growable: false);
  }

  @override
  Future<void> saveAllocationTarget(AllocationTarget target) async {
    await _beginWrite();

    _targets
      ..removeWhere(
        (item) => item.id == target.id || item.category == target.category,
      )
      ..add(target)
      ..sort(
        (left, right) => left.category.index.compareTo(right.category.index),
      );
    _targetProgressPercentage = _estimateTargetProgress();
  }

  @override
  Future<void> deleteAllocationTarget(String targetId) async {
    await _beginWrite();

    _targets.removeWhere((target) => target.id == targetId);
    _targetProgressPercentage = _estimateTargetProgress();
  }

  double get _currentTotalValue =>
      _holdings.values.fold(0, (sum, holding) => sum + holding.currentValue);

  List<PortfolioPosition> _positions() {
    final total = _currentTotalValue;
    return [
      for (final asset in _assets)
        if (_holdings[asset.id] case final holding?)
          PortfolioPosition(
            asset: asset,
            holding: holding,
            allocationPercentage: total == 0
                ? 0
                : holding.currentValue / total * 100,
          ),
    ]..sort((left, right) => right.currentValue.compareTo(left.currentValue));
  }

  double _estimateTargetProgress() {
    final actualByCategory = <AssetCategory, double>{};
    for (final position in _positions()) {
      actualByCategory.update(
        position.category,
        (value) => value + position.allocationPercentage,
        ifAbsent: () => position.allocationPercentage,
      );
    }

    var totalDifference = 0.0;
    for (final target in _targets) {
      totalDifference +=
          ((actualByCategory[target.category] ?? 0) - target.targetPercentage)
              .abs();
    }

    return (100 - (totalDifference / 2)).clamp(0, 100).toDouble();
  }

  /// Sums each held asset's most recent recorded value at or before [asOf],
  /// falling back to its current value when no snapshot exists yet.
  double _historicalPortfolioTotal(DateTime asOf) {
    var total = 0.0;

    for (final holding in _holdings.values) {
      final history =
          _assetHistories[holding.assetId] ?? const <AssetSnapshot>[];
      final atOrBefore = history.where(
        (snapshot) => !snapshot.recordedAt.isAfter(asOf),
      );
      final latest = atOrBefore.isEmpty
          ? null
          : atOrBefore.reduce(
              (a, b) => a.recordedAt.isAfter(b.recordedAt) ? a : b,
            );

      total += latest?.totalValue ?? holding.currentValue;
    }

    return total;
  }

  double _calculateMonthlyChange() {
    if (_portfolioHistory.length < 2) {
      return 0;
    }

    final latest = _portfolioHistory.first.totalValue;
    final previous = _portfolioHistory[1].totalValue;
    if (previous == 0) {
      return 0;
    }

    return ((latest - previous) / previous) * 100;
  }

  Future<void> _wait() => Future<void>.delayed(simulatedDelay);

  final _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  /// Kabari pembaca setelah mutasi sinkron di method tulis selesai.
  Future<void> _beginWrite() async {
    await _wait();
    scheduleMicrotask(() => _changes.add(null));
  }
}

bool _sameMonth(DateTime left, DateTime right) =>
    left.year == right.year && left.month == right.month;

String _monthKey(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}';
