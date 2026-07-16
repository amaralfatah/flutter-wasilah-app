import 'dart:async';

import 'package:flutter_wasilah_app/features/portfolio/models/allocation_target.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/portfolio_summary.dart';
import 'package:flutter_wasilah_app/features/portfolio/repository/portfolio_repository.dart';

class MockPortfolioRepository implements PortfolioRepository {
  MockPortfolioRepository({
    this.simulatedDelay = const Duration(milliseconds: 250),
  });

  final Duration simulatedDelay;

  final List<Asset> _assets = [
    Asset(
      id: 'btc',
      name: 'Bitcoin',
      code: 'BTC',
      category: AssetCategory.crypto,
      currentValue: 18200000,
      allocationPercentage: 33.1,
      lastUpdatedAt: DateTime(2026, 7, 15),
    ),
    Asset(
      id: 'bmri',
      name: 'Bank Mandiri',
      code: 'BMRI',
      category: AssetCategory.stock,
      currentValue: 10700000,
      allocationPercentage: 19.5,
      lastUpdatedAt: DateTime(2026, 7, 15),
    ),
    Asset(
      id: 'bbri',
      name: 'Bank Rakyat Indonesia',
      code: 'BBRI',
      category: AssetCategory.stock,
      currentValue: 10200000,
      allocationPercentage: 18.6,
      lastUpdatedAt: DateTime(2026, 7, 15),
    ),
    Asset(
      id: 'rd',
      name: 'Reksa Dana',
      code: 'RDPT',
      category: AssetCategory.mutualFund,
      currentValue: 9300000,
      allocationPercentage: 16.9,
      lastUpdatedAt: DateTime(2026, 7, 14),
    ),
    Asset(
      id: 'cash',
      name: 'Kas',
      code: 'CASH',
      category: AssetCategory.cash,
      currentValue: 6600000,
      allocationPercentage: 12,
      lastUpdatedAt: DateTime(2026, 7, 12),
    ),
  ];

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

  final List<AssetSnapshot> _portfolioHistory = [
    AssetSnapshot(
      id: 'portfolio-20260715',
      assetId: 'portfolio',
      totalValue: 55000000,
      recordedAt: DateTime(2026, 7, 15),
    ),
    AssetSnapshot(
      id: 'portfolio-20260615',
      assetId: 'portfolio',
      totalValue: 53200000,
      recordedAt: DateTime(2026, 6, 15),
    ),
    AssetSnapshot(
      id: 'portfolio-20260515',
      assetId: 'portfolio',
      totalValue: 51500000,
      recordedAt: DateTime(2026, 5, 15),
    ),
    AssetSnapshot(
      id: 'portfolio-20260415',
      assetId: 'portfolio',
      totalValue: 49800000,
      recordedAt: DateTime(2026, 4, 15),
    ),
  ];

  final List<AllocationTarget> _targets = [
    AllocationTarget(
      id: 'target-crypto',
      category: AssetCategory.crypto,
      targetPercentage: 35,
    ),
    AllocationTarget(
      id: 'target-stock',
      category: AssetCategory.stock,
      targetPercentage: 40,
    ),
    AllocationTarget(
      id: 'target-mutual-fund',
      category: AssetCategory.mutualFund,
      targetPercentage: 15,
    ),
    AllocationTarget(
      id: 'target-cash',
      category: AssetCategory.cash,
      targetPercentage: 10,
    ),
  ];

  double _monthlyChangePercentage = 3.4;
  double _targetProgressPercentage = 88.3;

  @override
  Future<List<AllocationTarget>> getAllocationTargets() async {
    await _wait();
    return _targets.toList(growable: false);
  }

  @override
  Future<Asset?> getAssetById(String assetId) async {
    await _wait();
    return _assets.where((asset) => asset.id == assetId).firstOrNull;
  }

  @override
  Future<List<Asset>> getAssets() async {
    await _wait();
    return _assets.toList(growable: false);
  }

  @override
  Future<void> createAsset(Asset asset) async {
    await _wait();

    if (_assets.any((item) => item.id == asset.id)) {
      throw StateError('Asset sudah ada.');
    }

    _assets.add(asset);
    final history = _assetHistories.putIfAbsent(
      asset.id,
      () => <AssetSnapshot>[],
    );
    _replaceSnapshot(
      history,
      AssetSnapshot(
        id: '${asset.id}-${asset.lastUpdatedAt.microsecondsSinceEpoch}',
        assetId: asset.id,
        totalValue: asset.currentValue,
        recordedAt: asset.lastUpdatedAt,
      ),
    );
    _recalculateAllocations();
    _replacePortfolioSnapshot(asset.lastUpdatedAt);
  }

  @override
  Future<void> updateAsset(Asset asset) async {
    await _wait();

    final assetIndex = _assets.indexWhere((item) => item.id == asset.id);
    if (assetIndex == -1) {
      throw StateError('Asset tidak ditemukan.');
    }

    final existing = _assets[assetIndex];
    _assets[assetIndex] = existing.copyWith(
      name: asset.name,
      code: asset.code,
      category: asset.category,
    );
  }

  @override
  Future<void> deleteAsset(String assetId) async {
    await _wait();

    _assets.removeWhere((asset) => asset.id == assetId);
    _assetHistories.remove(assetId);
    _recalculateAllocations();
  }

  @override
  Future<List<AssetSnapshot>> getAssetHistory(String assetId) async {
    await _wait();
    return (_assetHistories[assetId] ?? <AssetSnapshot>[]).toList(
      growable: false,
    );
  }

  @override
  Future<List<AssetSnapshot>> getPortfolioHistory() async {
    await _wait();
    return _portfolioHistory.toList(growable: false);
  }

  @override
  Future<PortfolioSummary> getPortfolioSummary() async {
    await _wait();
    return PortfolioSummary(
      totalValue: _currentTotalValue,
      monthlyChangePercentage: _monthlyChangePercentage,
      targetProgressPercentage: _targetProgressPercentage,
      assets: _assets.toList(growable: false),
      lastUpdatedAt: _assets
          .map((asset) => asset.lastUpdatedAt)
          .reduce((latest, next) => latest.isAfter(next) ? latest : next),
    );
  }

  @override
  Future<void> updateAssetValue({
    required String assetId,
    required double totalValue,
    required DateTime recordedAt,
    String? note,
  }) async {
    await _wait();

    final assetIndex = _assets.indexWhere((asset) => asset.id == assetId);
    if (assetIndex == -1) {
      throw StateError('Asset tidak ditemukan.');
    }

    _assets[assetIndex] = _assets[assetIndex].copyWith(
      currentValue: totalValue,
      lastUpdatedAt: recordedAt,
    );

    final history = _assetHistories.putIfAbsent(
      assetId,
      () => <AssetSnapshot>[],
    );
    _replaceSnapshot(
      history,
      AssetSnapshot(
        id: '$assetId-${recordedAt.microsecondsSinceEpoch}',
        assetId: assetId,
        totalValue: totalValue,
        recordedAt: recordedAt,
        note: note,
      ),
    );

    _recalculateAllocations();

    _replacePortfolioSnapshot(recordedAt, note: note);

    _monthlyChangePercentage = _calculateMonthlyChange(_portfolioHistory);
    _targetProgressPercentage = _estimateTargetProgress();
  }

  @override
  Future<void> saveAllocationTarget(AllocationTarget target) async {
    await _wait();

    _targets.removeWhere(
      (item) => item.id == target.id || item.category == target.category,
    );
    _targets.add(target);
    _targets.sort(
      (left, right) => left.category.index.compareTo(right.category.index),
    );
    _targetProgressPercentage = _estimateTargetProgress();
  }

  @override
  Future<void> deleteAllocationTarget(String targetId) async {
    await _wait();

    _targets.removeWhere((target) => target.id == targetId);
    _targetProgressPercentage = _estimateTargetProgress();
  }

  double get _currentTotalValue =>
      _assets.fold(0, (sum, asset) => sum + asset.currentValue);

  double _estimateTargetProgress() {
    final actualByCategory = <AssetCategory, double>{};
    for (final asset in _assets) {
      actualByCategory.update(
        asset.category,
        (value) => value + asset.allocationPercentage,
        ifAbsent: () => asset.allocationPercentage,
      );
    }

    var totalDifference = 0.0;
    for (final target in _targets) {
      totalDifference +=
          (actualByCategory[target.category] ?? 0 - target.targetPercentage)
              .abs();
    }

    return (100 - (totalDifference / 2)).clamp(0, 100).toDouble();
  }

  void _recalculateAllocations() {
    final total = _currentTotalValue;
    if (total == 0) {
      for (var index = 0; index < _assets.length; index++) {
        _assets[index] = _assets[index].copyWith(allocationPercentage: 0);
      }
      return;
    }

    for (var index = 0; index < _assets.length; index++) {
      final asset = _assets[index];
      _assets[index] = asset.copyWith(
        allocationPercentage: (asset.currentValue / total) * 100,
      );
    }
  }

  void _replaceSnapshot(List<AssetSnapshot> snapshots, AssetSnapshot snapshot) {
    snapshots.removeWhere(
      (item) =>
          item.assetId == snapshot.assetId &&
          item.recordedAt == snapshot.recordedAt,
    );
    snapshots.add(snapshot);
    snapshots.sort(
      (left, right) => right.recordedAt.compareTo(left.recordedAt),
    );
  }

  void _replacePortfolioSnapshot(DateTime recordedAt, {String? note}) {
    _replaceSnapshot(
      _portfolioHistory,
      AssetSnapshot(
        id: 'portfolio-${recordedAt.microsecondsSinceEpoch}',
        assetId: 'portfolio',
        totalValue: _currentTotalValue,
        recordedAt: recordedAt,
        note: note,
      ),
    );
  }

  double _calculateMonthlyChange(List<AssetSnapshot> history) {
    if (history.length < 2) {
      return 0;
    }

    final latest = history.first.totalValue;
    final previous = history[1].totalValue;
    if (previous == 0) {
      return 0;
    }

    return ((latest - previous) / previous) * 100;
  }

  Future<void> _wait() => Future<void>.delayed(simulatedDelay);
}
