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
  Future<void>? _initialization;

  @override
  Future<List<AllocationTarget>> getAllocationTargets() async {
    await _ensureInitialized();
    final rows = await _database.customSelect(
      '''
      SELECT id, category, target_percentage
      FROM allocation_targets
      ORDER BY category ASC
      ''',
    ).get();

    return rows
        .map(
          (row) => AllocationTarget(
            id: row.read<String>('id'),
            category: AssetCategory.values.byName(row.read<String>('category')),
            targetPercentage: row.read<double>('target_percentage'),
          ),
        )
        .toList(growable: false)
      ..sort((left, right) => left.category.index.compareTo(right.category.index));
  }

  @override
  Future<Asset?> getAssetById(String assetId) async {
    await _ensureInitialized();
    final row = await _database.customSelect(
      '''
      SELECT id, name, code, category, current_value, allocation_percentage, last_updated_at
      FROM assets
      WHERE id = ?
      LIMIT 1
      ''',
      variables: [Variable.withString(assetId)],
    ).getSingleOrNull();

    return row == null ? null : _mapAsset(row);
  }

  @override
  Future<List<Asset>> getAssets() async {
    await _ensureInitialized();
    final rows = await _database.customSelect(
      '''
      SELECT id, name, code, category, current_value, allocation_percentage, last_updated_at
      FROM assets
      ORDER BY current_value DESC, name ASC
      ''',
    ).get();

    return rows.map(_mapAsset).toList(growable: false);
  }

  @override
  Future<List<AssetSnapshot>> getAssetHistory(String assetId) async {
    await _ensureInitialized();
    final rows = await _database.customSelect(
      '''
      SELECT rowid AS row_id, id, asset_id, total_value, recorded_at, note
      FROM asset_snapshots
      WHERE asset_id = ?
      ORDER BY recorded_at DESC, row_id DESC
      ''',
      variables: [Variable.withString(assetId)],
    ).get();

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
    final lastUpdatedAt = assets
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

      await _database.customStatement(
        '''
        INSERT INTO asset_snapshots (id, asset_id, total_value, recorded_at, note)
        VALUES (?, ?, ?, ?, ?)
        ''',
        [
          _buildSnapshotId(assetId, recordedAt),
          assetId,
          totalValue,
          _dateToSql(recordedAt),
          note,
        ],
      );

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

      await _database.customStatement(
        '''
        INSERT INTO asset_snapshots (id, asset_id, total_value, recorded_at, note)
        VALUES (?, ?, ?, ?, ?)
        ''',
        [
          _buildSnapshotId(_portfolioAssetId, recordedAt),
          _portfolioAssetId,
          portfolioTotal,
          _dateToSql(recordedAt),
          note,
        ],
      );
    });
  }

  Future<void> _ensureInitialized() {
    return _initialization ??= _seedIfNeeded();
  }

  Future<void> _seedIfNeeded() async {
    final existing = await _database.customSelect(
      'SELECT id FROM assets LIMIT 1',
    ).getSingleOrNull();
    if (existing != null) {
      return;
    }

    await _database.transaction(() async {
      for (final asset in _seedAssets) {
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
      }

      for (final snapshot in _seedSnapshots) {
        await _database.customStatement(
          '''
          INSERT INTO asset_snapshots (id, asset_id, total_value, recorded_at, note)
          VALUES (?, ?, ?, ?, ?)
          ''',
          [
            snapshot.id,
            snapshot.assetId,
            snapshot.totalValue,
            _dateToSql(snapshot.recordedAt),
            snapshot.note,
          ],
        );
      }

      for (final target in _seedTargets) {
        await _database.customStatement(
          '''
          INSERT INTO allocation_targets (id, category, target_percentage)
          VALUES (?, ?, ?)
          ''',
          [
            target.id,
            target.category.name,
            target.targetPercentage,
          ],
        );
      }
    });
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

    return (100 - (totalDifference * 1.5)).clamp(0, 100).toDouble();
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
}

String _buildSnapshotId(String assetId, DateTime recordedAt) {
  return '$assetId-${recordedAt.microsecondsSinceEpoch}';
}

int _dateToSql(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;

const _portfolioAssetId = 'portfolio';

final _seedAssets = <Asset>[
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

final _seedSnapshots = <AssetSnapshot>[
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
  AssetSnapshot(
    id: 'portfolio-20260715',
    assetId: _portfolioAssetId,
    totalValue: 55000000,
    recordedAt: DateTime(2026, 7, 15),
  ),
  AssetSnapshot(
    id: 'portfolio-20260615',
    assetId: _portfolioAssetId,
    totalValue: 53200000,
    recordedAt: DateTime(2026, 6, 15),
  ),
  AssetSnapshot(
    id: 'portfolio-20260515',
    assetId: _portfolioAssetId,
    totalValue: 51500000,
    recordedAt: DateTime(2026, 5, 15),
  ),
  AssetSnapshot(
    id: 'portfolio-20260415',
    assetId: _portfolioAssetId,
    totalValue: 49800000,
    recordedAt: DateTime(2026, 4, 15),
  ),
];

const _seedTargets = <AllocationTarget>[
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
