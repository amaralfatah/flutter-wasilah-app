import 'package:drift/drift.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/allocation_target.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/portfolio_summary.dart';
import 'package:flutter_wasilah_app/features/portfolio/repository/portfolio_repository.dart';

class DriftPortfolioRepository implements PortfolioRepository {
  DriftPortfolioRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<AllocationTarget>> getAllocationTargets() async {
    await _ensureInitialized();
    final rows = await _database.customSelect('''
      SELECT id, category, target_percentage
      FROM allocation_targets
      ORDER BY category ASC
      ''').get();

    return rows
        .map(
          (row) => AllocationTarget(
            id: row.read<String>('id'),
            category: AssetCategory.values.byName(row.read<String>('category')),
            targetPercentage: row.read<double>('target_percentage'),
          ),
        )
        .toList(growable: false)
      ..sort(
        (left, right) => left.category.index.compareTo(right.category.index),
      );
  }

  @override
  Future<Asset?> getAssetById(String assetId) async {
    await _ensureInitialized();
    final row = await _database
        .customSelect(
          '''
      SELECT id, name, code, category, current_value, allocation_percentage, last_updated_at
      FROM assets
      WHERE id = ?
      LIMIT 1
      ''',
          variables: [Variable.withString(assetId)],
        )
        .getSingleOrNull();

    return row == null ? null : _mapAsset(row);
  }

  @override
  Future<List<Asset>> getAssets() async {
    await _ensureInitialized();
    final rows = await _database.customSelect('''
      SELECT id, name, code, category, current_value, allocation_percentage, last_updated_at
      FROM assets
      ORDER BY current_value DESC, name ASC
      ''').get();

    return rows.map(_mapAsset).toList(growable: false);
  }

  @override
  Future<void> createAsset(Asset asset) async {
    await _ensureInitialized();

    await _database.transaction(() async {
      await _database.customStatement(
        '''
        INSERT INTO assets (
          id, name, code, category, current_value, allocation_percentage, last_updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          asset.id,
          asset.name,
          asset.code,
          asset.category.name,
          asset.currentValue,
          asset.allocationPercentage,
          _dateToSql(asset.lastUpdatedAt),
        ],
      );

      await _saveSnapshot(
        assetId: asset.id,
        totalValue: asset.currentValue,
        recordedAt: asset.lastUpdatedAt,
      );
      await _recalculateAllocations();
      await _savePortfolioSnapshot(asset.lastUpdatedAt);
    });
  }

  @override
  Future<void> updateAsset(Asset asset) async {
    await _ensureInitialized();

    await _database.customUpdate(
      '''
      UPDATE assets
      SET name = ?, code = ?, category = ?
      WHERE id = ?
      ''',
      variables: [
        Variable.withString(asset.name),
        Variable.withString(asset.code),
        Variable.withString(asset.category.name),
        Variable.withString(asset.id),
      ],
    );
  }

  @override
  Future<void> deleteAsset(String assetId) async {
    await _ensureInitialized();

    await _database.transaction(() async {
      await _database.customStatement(
        'DELETE FROM asset_snapshots WHERE asset_id = ?',
        [assetId],
      );
      await _database.customStatement('DELETE FROM assets WHERE id = ?', [
        assetId,
      ]);
      await _recalculateAllocations();
    });
  }

  @override
  Future<List<AssetSnapshot>> getAssetHistory(String assetId) async {
    await _ensureInitialized();
    final rows = await _database
        .customSelect(
          '''
      SELECT rowid AS row_id, id, asset_id, total_value, recorded_at, note
      FROM asset_snapshots
      WHERE asset_id = ?
      ORDER BY recorded_at DESC, row_id DESC
      ''',
          variables: [Variable.withString(assetId)],
        )
        .get();

    return rows.map(_mapSnapshot).toList(growable: false);
  }

  @override
  Future<List<AssetSnapshot>> getPortfolioHistory() async {
    return getAssetHistory(_portfolioAssetId);
  }

  @override
  Future<PortfolioSummary> getPortfolioSummary() async {
    await _ensureInitialized();
    final assets = await getAssets();
    final history = await getPortfolioHistory();
    final targets = await getAllocationTargets();
    final totalValue = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.currentValue,
    );
    final lastUpdatedAt = assets.isEmpty
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : assets
              .map((asset) => asset.lastUpdatedAt)
              .reduce((latest, next) => latest.isAfter(next) ? latest : next);

    return PortfolioSummary(
      totalValue: totalValue,
      monthlyChangePercentage: _calculateMonthlyChange(history),
      targetProgressPercentage: _calculateTargetProgress(assets, targets),
      assets: assets,
      lastUpdatedAt: lastUpdatedAt,
    );
  }

  @override
  Future<void> updateAssetValue({
    required String assetId,
    required double totalValue,
    required DateTime recordedAt,
    String? note,
  }) async {
    await _ensureInitialized();

    await _database.transaction(() async {
      final existingAsset = await getAssetById(assetId);
      if (existingAsset == null) {
        throw StateError('Asset tidak ditemukan.');
      }

      await _database.customUpdate(
        '''
        UPDATE assets
        SET current_value = ?, last_updated_at = ?
        WHERE id = ?
        ''',
        variables: [
          Variable.withReal(totalValue),
          Variable.withDateTime(recordedAt),
          Variable.withString(assetId),
        ],
      );

      await _saveSnapshot(
        assetId: assetId,
        totalValue: totalValue,
        recordedAt: recordedAt,
        note: note,
      );

      final assets = await getAssets();
      final portfolioTotal = assets.fold<double>(
        0,
        (sum, asset) => sum + asset.currentValue,
      );

      await _recalculateAllocations();

      await _saveSnapshot(
        assetId: _portfolioAssetId,
        totalValue: portfolioTotal,
        recordedAt: recordedAt,
        note: note,
      );
    });
  }

  @override
  Future<void> saveAllocationTarget(AllocationTarget target) async {
    await _ensureInitialized();

    await _database.transaction(() async {
      await _database.customStatement(
        'DELETE FROM allocation_targets WHERE id = ? OR category = ?',
        [target.id, target.category.name],
      );
      await _database.customStatement(
        '''
        INSERT INTO allocation_targets (id, category, target_percentage)
        VALUES (?, ?, ?)
        ''',
        [target.id, target.category.name, target.targetPercentage],
      );
    });
  }

  @override
  Future<void> deleteAllocationTarget(String targetId) async {
    await _ensureInitialized();

    await _database.customStatement(
      'DELETE FROM allocation_targets WHERE id = ?',
      [targetId],
    );
  }

  Future<void> _ensureInitialized() async {}

  Future<void> _recalculateAllocations() async {
    final assets = await getAssets();
    final portfolioTotal = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.currentValue,
    );

    for (final asset in assets) {
      final allocationPercentage = portfolioTotal == 0
          ? 0.0
          : (asset.currentValue / portfolioTotal) * 100;
      await _database.customStatement(
        'UPDATE assets SET allocation_percentage = ? WHERE id = ?',
        [allocationPercentage, asset.id],
      );
    }
  }

  Future<void> _savePortfolioSnapshot(DateTime recordedAt) async {
    final assets = await getAssets();
    final portfolioTotal = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.currentValue,
    );

    await _saveSnapshot(
      assetId: _portfolioAssetId,
      totalValue: portfolioTotal,
      recordedAt: recordedAt,
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

  double _calculateTargetProgress(
    List<Asset> assets,
    List<AllocationTarget> targets,
  ) {
    if (assets.isEmpty || targets.isEmpty) {
      return 0;
    }

    final actualByCategory = <AssetCategory, double>{};
    for (final asset in assets) {
      actualByCategory.update(
        asset.category,
        (value) => value + asset.allocationPercentage,
        ifAbsent: () => asset.allocationPercentage,
      );
    }

    var totalDifference = 0.0;
    for (final target in targets) {
      totalDifference +=
          ((actualByCategory[target.category] ?? 0) - target.targetPercentage)
              .abs();
    }

    return (100 - (totalDifference / 2)).clamp(0, 100).toDouble();
  }

  Asset _mapAsset(QueryRow row) {
    return Asset(
      id: row.read<String>('id'),
      name: row.read<String>('name'),
      code: row.read<String>('code'),
      category: AssetCategory.values.byName(row.read<String>('category')),
      currentValue: row.read<double>('current_value'),
      allocationPercentage: row.read<double>('allocation_percentage'),
      lastUpdatedAt: row.read<DateTime>('last_updated_at'),
    );
  }

  AssetSnapshot _mapSnapshot(QueryRow row) {
    return AssetSnapshot(
      id: row.read<String>('id'),
      assetId: row.read<String>('asset_id'),
      totalValue: row.read<double>('total_value'),
      recordedAt: row.read<DateTime>('recorded_at'),
      note: row.readNullable<String>('note'),
    );
  }

  Future<void> _saveSnapshot({
    required String assetId,
    required double totalValue,
    required DateTime recordedAt,
    String? note,
  }) async {
    final recordedAtSql = _dateToSql(recordedAt);

    await _database.customStatement(
      '''
      DELETE FROM asset_snapshots
      WHERE asset_id = ? AND recorded_at = ?
      ''',
      [assetId, recordedAtSql],
    );

    await _database.customStatement(
      '''
      INSERT INTO asset_snapshots (id, asset_id, total_value, recorded_at, note)
      VALUES (?, ?, ?, ?, ?)
      ''',
      [
        _buildSnapshotId(assetId, recordedAt),
        assetId,
        totalValue,
        recordedAtSql,
        note,
      ],
    );
  }
}

String _buildSnapshotId(String assetId, DateTime recordedAt) {
  return '$assetId-${recordedAt.microsecondsSinceEpoch}';
}

int _dateToSql(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;

const _portfolioAssetId = 'portfolio';
