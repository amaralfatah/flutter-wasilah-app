import 'package:drift/drift.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/allocation_target.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_summary.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/portfolio_repository.dart';

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
      SELECT id, name, code, category, current_value, allocation_percentage, last_updated_at, total_cost, market_symbol, quantity, avg_buy_price, price_currency
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
      SELECT id, name, code, category, current_value, allocation_percentage, last_updated_at, total_cost, market_symbol, quantity, avg_buy_price, price_currency
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
          id, name, code, category, current_value, allocation_percentage, last_updated_at, total_cost, market_symbol, quantity, avg_buy_price, price_currency
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          asset.id,
          asset.name,
          asset.code,
          asset.category.name,
          asset.currentValue,
          asset.allocationPercentage,
          _dateToSql(asset.lastUpdatedAt),
          asset.totalCost,
          _normalizeMarketSymbol(asset.marketSymbol),
          asset.quantity,
          asset.avgBuyPrice,
          _normalizePriceCurrency(asset.priceCurrency),
        ],
      );

      await _saveSnapshot(
        assetId: asset.id,
        totalValue: asset.currentValue,
        recordedAt: asset.lastUpdatedAt,
        totalCost: asset.totalCost,
      );
      await _recalculateAllocations();
      await _savePortfolioSnapshot(asset.lastUpdatedAt);
    });
  }

  @override
  Future<void> updateAsset(Asset asset) async {
    await _ensureInitialized();

    await _database.transaction(() async {
      await _database.customUpdate(
        '''
        UPDATE assets
        SET name = ?, code = ?, category = ?, total_cost = ?, market_symbol = ?, quantity = ?, avg_buy_price = ?, price_currency = ?
        WHERE id = ?
        ''',
        variables: [
          Variable.withString(asset.name),
          Variable.withString(asset.code),
          Variable.withString(asset.category.name),
          Variable<double>(asset.totalCost),
          Variable<String>(_normalizeMarketSymbol(asset.marketSymbol)),
          Variable<double>(asset.quantity),
          Variable<double>(asset.avgBuyPrice),
          Variable<String>(_normalizePriceCurrency(asset.priceCurrency)),
          Variable.withString(asset.id),
        ],
      );

      // Modal di form edit adalah modal terkini, jadi ikut mengoreksi
      // snapshot terakhir supaya histori PnL tidak menyimpang dari detail.
      final latest = await _latestSnapshotOrNull(asset.id);
      if (latest == null || latest.totalCost == asset.totalCost) {
        return;
      }
      await _database.customStatement(
        'UPDATE asset_snapshots SET total_cost = ? WHERE id = ?',
        [asset.totalCost, latest.id],
      );
      await _refreshPortfolioCosts(from: latest.recordedAt);
    });
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

      final remainingAssets = await getAssets();
      if (remainingAssets.isNotEmpty) {
        final lastUpdatedAt = remainingAssets
            .map((asset) => asset.lastUpdatedAt)
            .reduce((latest, next) => latest.isAfter(next) ? latest : next);
        await _savePortfolioSnapshot(lastUpdatedAt);
      }
    });
  }

  @override
  Future<List<AssetSnapshot>> getAssetHistory(String assetId) async {
    await _ensureInitialized();
    final rows = await _database
        .customSelect(
          '''
      SELECT rowid AS row_id, id, asset_id, total_value, recorded_at, note, total_cost
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
  Future<void> deleteSnapshot(String snapshotId) async {
    await _ensureInitialized();

    await _database.transaction(() async {
      final row = await _database
          .customSelect(
            '''
        SELECT rowid AS row_id, id, asset_id, total_value, recorded_at, note, total_cost
        FROM asset_snapshots
        WHERE id = ?
        LIMIT 1
        ''',
            variables: [Variable.withString(snapshotId)],
          )
          .getSingleOrNull();

      if (row == null) {
        return;
      }

      final deleted = _mapSnapshot(row);

      await _database.customStatement(
        'DELETE FROM asset_snapshots WHERE id = ?',
        [snapshotId],
      );

      if (deleted.assetId == _portfolioAssetId) {
        return;
      }

      final remainingRow = await _database
          .customSelect(
            '''
        SELECT rowid AS row_id, id, asset_id, total_value, recorded_at, note, total_cost
        FROM asset_snapshots
        WHERE asset_id = ?
        ORDER BY recorded_at DESC, row_id DESC
        LIMIT 1
        ''',
            variables: [Variable.withString(deleted.assetId)],
          )
          .getSingleOrNull();
      final remaining = remainingRow == null
          ? null
          : _mapSnapshot(remainingRow);

      await _database.customUpdate(
        '''
        UPDATE assets
        SET current_value = ?, last_updated_at = ?, total_cost = ?
        WHERE id = ?
        ''',
        variables: [
          Variable.withReal(remaining?.totalValue ?? 0),
          Variable.withDateTime(
            remaining?.recordedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          ),
          Variable<double>(remaining?.totalCost),
          Variable.withString(deleted.assetId),
        ],
      );

      await _recalculateAllocations();

      // The portfolio's monthly history snapshot for that month baked in
      // the now-deleted value, so it must be regenerated from what's left.
      await _savePortfolioSnapshot(deleted.recordedAt);
    });
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
    double? totalCost,
    double? quantity,
    double? avgBuyPrice,
    String? priceCurrency,
  }) async {
    await _ensureInitialized();

    await _database.transaction(() async {
      final existingAsset = await getAssetById(assetId);
      if (existingAsset == null) {
        throw StateError('Asset tidak ditemukan.');
      }

      await _saveSnapshot(
        assetId: assetId,
        totalValue: totalValue,
        recordedAt: recordedAt,
        note: note,
        // Tanpa input modal, bawa modal terakhir per tanggal itu supaya
        // histori PnL tidak bolong di bulan yang hanya update nilai.
        totalCost:
            totalCost ??
            await _historicalAssetCost(assetId, recordedAt) ??
            existingAsset.totalCost,
      );

      // current_value/last_updated_at harus mengikuti snapshot paling baru
      // secara kronologis, bukan nilai yang baru saja diinput -- input bisa
      // saja backdate (tanggal mundur) dan tidak boleh menimpa nilai terkini.
      final latestSnapshot = await _latestSnapshot(assetId);
      await _database.customUpdate(
        '''
        UPDATE assets
        SET current_value = ?, last_updated_at = ?, total_cost = ?,
            quantity = ?, avg_buy_price = ?, price_currency = ?
        WHERE id = ?
        ''',
        variables: [
          Variable.withReal(latestSnapshot.totalValue),
          Variable.withDateTime(latestSnapshot.recordedAt),
          Variable<double>(latestSnapshot.totalCost),
          // null berarti field tak diubah di form ini: pertahankan nilai lama.
          Variable<double>(quantity ?? existingAsset.quantity),
          Variable<double>(avgBuyPrice ?? existingAsset.avgBuyPrice),
          Variable<String>(
            _normalizePriceCurrency(priceCurrency) ??
                existingAsset.priceCurrency,
          ),
          Variable.withString(assetId),
        ],
      );

      await _recalculateAllocations();

      final portfolioTotal = await _historicalPortfolioTotal(recordedAt);
      await _saveSnapshot(
        assetId: _portfolioAssetId,
        totalValue: portfolioTotal.value,
        recordedAt: recordedAt,
        note: note,
        totalCost: portfolioTotal.cost,
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
    final portfolioTotal = await _historicalPortfolioTotal(recordedAt);

    await _saveSnapshot(
      assetId: _portfolioAssetId,
      totalValue: portfolioTotal.value,
      recordedAt: recordedAt,
      totalCost: portfolioTotal.cost,
    );
  }

  /// Menghitung ulang modal di snapshot portofolio sejak [from], karena
  /// modal satu aset terbawa ke semua bulan setelahnya.
  Future<void> _refreshPortfolioCosts({required DateTime from}) async {
    final rows = await _database
        .customSelect(
          '''
      SELECT id, recorded_at
      FROM asset_snapshots
      WHERE asset_id = ? AND recorded_at >= ?
      ''',
          variables: [
            Variable.withString(_portfolioAssetId),
            Variable.withInt(_dateToSql(from)),
          ],
        )
        .get();

    for (final row in rows) {
      final total = await _historicalPortfolioTotal(
        row.read<DateTime>('recorded_at'),
      );
      await _database.customStatement(
        'UPDATE asset_snapshots SET total_cost = ? WHERE id = ?',
        [total.cost, row.read<String>('id')],
      );
    }
  }

  /// Modal [assetId] dari snapshot terakhir yang punya modal, per [asOf].
  Future<double?> _historicalAssetCost(String assetId, DateTime asOf) async {
    final row = await _database
        .customSelect(
          '''
      SELECT total_cost
      FROM asset_snapshots
      WHERE asset_id = ? AND recorded_at <= ? AND total_cost IS NOT NULL
      ORDER BY recorded_at DESC
      LIMIT 1
      ''',
          variables: [
            Variable.withString(assetId),
            Variable.withInt(_dateToSql(asOf)),
          ],
        )
        .getSingleOrNull();

    return row?.read<double>('total_cost');
  }

  /// The most recent snapshot for [assetId] by recorded_at. Assumes at
  /// least one snapshot exists (callers only use this right after saving one).
  Future<AssetSnapshot> _latestSnapshot(String assetId) async {
    return (await _latestSnapshotOrNull(assetId))!;
  }

  Future<AssetSnapshot?> _latestSnapshotOrNull(String assetId) async {
    final row = await _database
        .customSelect(
          '''
      SELECT rowid AS row_id, id, asset_id, total_value, recorded_at, note, total_cost
      FROM asset_snapshots
      WHERE asset_id = ?
      ORDER BY recorded_at DESC, row_id DESC
      LIMIT 1
      ''',
          variables: [Variable.withString(assetId)],
        )
        .getSingleOrNull();

    return row == null ? null : _mapSnapshot(row);
  }

  /// Sums each asset's most recent recorded value at or before [asOf].
  /// An asset with no snapshot that far back wasn't tracked yet at that
  /// point in time, so it contributes 0 rather than its current value --
  /// otherwise backfilling one asset's past value would drag in every
  /// other asset's *today* value and skew that month's total.
  ///
  /// Modal aset yang belum diisi dianggap sama dengan nilainya (PnL nol),
  /// supaya PnL portofolio tidak terdongkrak oleh aset tanpa modal. `cost`
  /// bernilai `null` bila belum ada satu aset pun yang punya modal.
  Future<({double value, double? cost})> _historicalPortfolioTotal(
    DateTime asOf,
  ) async {
    final assets = await getAssets();
    var total = 0.0;
    var cost = 0.0;
    var hasCost = false;

    for (final asset in assets) {
      final row = await _database
          .customSelect(
            '''
        SELECT total_value
        FROM asset_snapshots
        WHERE asset_id = ? AND recorded_at <= ?
        ORDER BY recorded_at DESC
        LIMIT 1
        ''',
            variables: [
              Variable.withString(asset.id),
              Variable.withInt(_dateToSql(asOf)),
            ],
          )
          .getSingleOrNull();

      final value = row?.read<double>('total_value') ?? 0;
      final assetCost = row == null
          ? null
          : await _historicalAssetCost(asset.id, asOf);
      total += value;
      cost += assetCost ?? value;
      hasCost = hasCost || assetCost != null;
    }

    return (value: total, cost: hasCost ? cost : null);
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
      totalCost: row.readNullable<double>('total_cost'),
      marketSymbol: row.readNullable<String>('market_symbol'),
      quantity: row.readNullable<double>('quantity'),
      avgBuyPrice: row.readNullable<double>('avg_buy_price'),
      priceCurrency: row.readNullable<String>('price_currency'),
    );
  }

  AssetSnapshot _mapSnapshot(QueryRow row) {
    return AssetSnapshot(
      id: row.read<String>('id'),
      assetId: row.read<String>('asset_id'),
      totalValue: row.read<double>('total_value'),
      recordedAt: row.read<DateTime>('recorded_at'),
      note: row.readNullable<String>('note'),
      totalCost: row.readNullable<double>('total_cost'),
    );
  }

  Future<void> _saveSnapshot({
    required String assetId,
    required double totalValue,
    required DateTime recordedAt,
    String? note,
    double? totalCost,
  }) async {
    // The snapshot id already encodes assetId + local year/month, so
    // deleting by id is both the dedup key and timezone-safe. (A prior
    // version deduped via `strftime(..., 'unixepoch')`, which computes the
    // month in UTC -- for timezones ahead of UTC (e.g. WIB/UTC+7), an
    // early-morning date on the 1st of a month can fall on the previous
    // UTC month, so the DELETE wouldn't match the existing row and the
    // INSERT would collide with it on a UNIQUE constraint.)
    final snapshotId = _buildSnapshotId(assetId, recordedAt);

    await _database.customStatement(
      'DELETE FROM asset_snapshots WHERE id = ?',
      [snapshotId],
    );

    await _database.customStatement(
      '''
      INSERT INTO asset_snapshots (
        id, asset_id, total_value, recorded_at, note, total_cost
      ) VALUES (?, ?, ?, ?, ?, ?)
      ''',
      [
        snapshotId,
        assetId,
        totalValue,
        _dateToSql(recordedAt),
        note,
        totalCost,
      ],
    );
  }
}

/// Huruf besar, di-trim; string kosong dianggap tidak ada simbol.
String? _normalizeMarketSymbol(String? symbol) {
  final trimmed = symbol?.trim().toUpperCase();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String? _normalizePriceCurrency(String? currency) {
  final trimmed = currency?.trim().toUpperCase();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String _buildSnapshotId(String assetId, DateTime recordedAt) {
  return '$assetId-${recordedAt.year}-${recordedAt.month.toString().padLeft(2, '0')}';
}

int _dateToSql(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;

const _portfolioAssetId = 'portfolio';
