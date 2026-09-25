import 'package:drift/drift.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/allocation_target.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/holding.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_summary.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/drift_asset_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/portfolio_repository.dart';

class DriftPortfolioRepository implements PortfolioRepository {
  DriftPortfolioRepository(this._database);

  final AppDatabase _database;

  static const _positionColumns = '''
    a.id, a.name, a.code, a.category, a.market_symbol,
    h.current_value, h.total_cost, h.quantity, h.avg_buy_price,
    h.price_currency, h.last_updated_at
  ''';

  @override
  Future<List<AllocationTarget>> getAllocationTargets() async {
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
  Future<List<PortfolioPosition>> getPositions() async {
    final rows = await _database.customSelect('''
      SELECT $_positionColumns
      FROM holdings h
      JOIN assets a ON a.id = h.asset_id
      ORDER BY h.current_value DESC, a.name ASC
      ''').get();

    final entries = rows
        .map((row) => (asset: mapAssetRow(row), holding: _mapHolding(row)))
        .toList(growable: false);
    final total = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.holding.currentValue,
    );

    return entries
        .map(
          (entry) => PortfolioPosition(
            asset: entry.asset,
            holding: entry.holding,
            allocationPercentage: total == 0
                ? 0
                : entry.holding.currentValue / total * 100,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<PortfolioPosition?> getPositionByAssetId(String assetId) async {
    final positions = await getPositions();
    return positions.where((position) => position.id == assetId).firstOrNull;
  }

  @override
  Future<List<AssetSnapshot>> getAssetHistory(String assetId) async {
    final rows = await _database
        .customSelect(
          '''
      SELECT rowid AS row_id, id, asset_id, total_value, recorded_at, note,
        total_cost, fx_currency, fx_rate
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
  Future<List<PortfolioSnapshot>> getPortfolioHistory() async {
    final rows = await _database.customSelect('''
      SELECT rowid AS row_id, id, total_value, recorded_at, note, total_cost
      FROM portfolio_snapshots
      ORDER BY recorded_at DESC, row_id DESC
      ''').get();

    return rows
        .map(
          (row) => PortfolioSnapshot(
            id: row.read<String>('id'),
            totalValue: row.read<double>('total_value'),
            recordedAt: row.read<DateTime>('recorded_at'),
            note: row.readNullable<String>('note'),
            totalCost: row.readNullable<double>('total_cost'),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> deleteAssetSnapshot(String snapshotId) async {
    await _database.transaction(() async {
      final row = await _database
          .customSelect(
            '''
        SELECT rowid AS row_id, id, asset_id, total_value, recorded_at, note,
        total_cost, fx_currency, fx_rate
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

      final remaining = await _latestSnapshotOrNull(deleted.assetId);
      if (remaining == null) {
        // Tanpa histori, aset tidak lagi punya nilai di portofolio.
        await _database.customStatement(
          'DELETE FROM holdings WHERE asset_id = ?',
          [deleted.assetId],
        );
      } else {
        await _database.customUpdate(
          '''
          UPDATE holdings
          SET current_value = ?, last_updated_at = ?, total_cost = ?
          WHERE asset_id = ?
          ''',
          variables: [
            Variable.withReal(remaining.totalValue),
            Variable.withDateTime(remaining.recordedAt),
            Variable<double>(remaining.totalCost),
            Variable.withString(deleted.assetId),
          ],
        );
      }

      // The portfolio's monthly history snapshot for that month baked in
      // the now-deleted value, so it must be regenerated from what's left.
      await _savePortfolioSnapshot(deleted.recordedAt);
      await _refreshPortfolioSnapshotsAfter(deleted.recordedAt);
    });
  }

  @override
  Future<void> deletePortfolioSnapshot(String snapshotId) async {
    await _database.customStatement(
      'DELETE FROM portfolio_snapshots WHERE id = ?',
      [snapshotId],
    );
  }

  @override
  Future<void> removeFromPortfolio(String assetId) async {
    await _database.transaction(() async {
      final months = await _database
          .customSelect(
            'SELECT recorded_at FROM asset_snapshots WHERE asset_id = ? '
            'ORDER BY recorded_at',
            variables: [Variable.withString(assetId)],
          )
          .get();

      await _database.customStatement(
        'DELETE FROM asset_snapshots WHERE asset_id = ?',
        [assetId],
      );
      await _database.customStatement(
        'DELETE FROM holdings WHERE asset_id = ?',
        [assetId],
      );

      // Setiap bulan yang dulu memuat nilai aset ini dihitung ulang.
      for (final row in months) {
        await _savePortfolioSnapshot(row.read<DateTime>('recorded_at'));
      }
      if (months.isNotEmpty) {
        await _refreshPortfolioSnapshotsAfter(
          months.first.read<DateTime>('recorded_at'),
        );
      }
    });
  }

  @override
  Future<PortfolioSummary> getPortfolioSummary() async {
    final positions = await getPositions();
    final history = await getPortfolioHistory();
    final targets = await getAllocationTargets();
    final totalValue = positions.fold<double>(
      0,
      (sum, position) => sum + position.currentValue,
    );
    final lastUpdatedAt = positions.isEmpty
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : positions
              .map((position) => position.lastUpdatedAt)
              .reduce((latest, next) => latest.isAfter(next) ? latest : next);

    return PortfolioSummary(
      totalValue: totalValue,
      monthlyChangePercentage: _calculateMonthlyChange(history),
      targetProgressPercentage: _calculateTargetProgress(positions, targets),
      positions: positions,
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
    String? fxCurrency,
    double? fxRate,
  }) async {
    await _database.transaction(() async {
      final assetRow = await _database
          .customSelect(
            'SELECT id FROM assets WHERE id = ? LIMIT 1',
            variables: [Variable.withString(assetId)],
          )
          .getSingleOrNull();
      if (assetRow == null) {
        throw StateError('Asset tidak ditemukan.');
      }
      final existing = await _holdingOrNull(assetId);

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
            existing?.totalCost,
        fxCurrency: fxRate == null ? null : _normalizePriceCurrency(fxCurrency),
        fxRate: fxRate,
      );

      // current_value/last_updated_at harus mengikuti snapshot paling baru
      // secara kronologis, bukan nilai yang baru saja diinput -- input bisa
      // saja backdate (tanggal mundur) dan tidak boleh menimpa nilai terkini.
      final latestSnapshot = (await _latestSnapshotOrNull(assetId))!;
      await _database.customStatement(
        '''
        INSERT INTO holdings (
          asset_id, current_value, total_cost, quantity, avg_buy_price,
          price_currency, last_updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT (asset_id) DO UPDATE SET
          current_value = excluded.current_value,
          total_cost = excluded.total_cost,
          quantity = excluded.quantity,
          avg_buy_price = excluded.avg_buy_price,
          price_currency = excluded.price_currency,
          last_updated_at = excluded.last_updated_at
        ''',
        [
          assetId,
          latestSnapshot.totalValue,
          latestSnapshot.totalCost,
          // null berarti field tak diubah di form ini: pertahankan nilai lama.
          quantity ?? existing?.quantity,
          avgBuyPrice ?? existing?.avgBuyPrice,
          _normalizePriceCurrency(priceCurrency) ?? existing?.priceCurrency,
          _dateToSql(latestSnapshot.recordedAt),
        ],
      );

      await _savePortfolioSnapshot(recordedAt, note: note);
      await _refreshPortfolioSnapshotsAfter(recordedAt);
    });
  }

  @override
  Future<void> saveAllocationTarget(AllocationTarget target) async {
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
    await _database.customStatement(
      'DELETE FROM allocation_targets WHERE id = ?',
      [targetId],
    );
  }

  Future<Holding?> _holdingOrNull(String assetId) async {
    final row = await _database
        .customSelect(
          '''
      SELECT current_value, total_cost, quantity, avg_buy_price,
        price_currency, last_updated_at
      FROM holdings
      WHERE asset_id = ?
      LIMIT 1
      ''',
          variables: [Variable.withString(assetId)],
        )
        .getSingleOrNull();

    return row == null ? null : _mapHolding(row, assetId: assetId);
  }

  Future<void> _savePortfolioSnapshot(
    DateTime recordedAt, {
    String? note,
  }) async {
    final portfolioTotal = await _historicalPortfolioTotal(recordedAt);

    await _database.customStatement(
      '''
      INSERT OR REPLACE INTO portfolio_snapshots (
        id, total_value, total_cost, recorded_at, note
      ) VALUES (?, ?, ?, ?, ?)
      ''',
      [
        _buildSnapshotId(_portfolioSnapshotPrefix, recordedAt),
        portfolioTotal.value,
        portfolioTotal.cost,
        _dateToSql(recordedAt),
        note,
      ],
    );
  }

  /// Bulan-bulan setelah [after] ikut membawa nilai aset terakhir yang
  /// tercatat, jadi perubahan histori di [after] harus merambat ke sana.
  Future<void> _refreshPortfolioSnapshotsAfter(DateTime after) async {
    final rows = await _database
        .customSelect(
          'SELECT id, recorded_at FROM portfolio_snapshots '
          'WHERE recorded_at > ?',
          variables: [Variable.withInt(_dateToSql(after))],
        )
        .get();

    for (final row in rows) {
      final total = await _historicalPortfolioTotal(
        row.read<DateTime>('recorded_at'),
      );
      await _database.customStatement(
        'UPDATE portfolio_snapshots SET total_value = ?, total_cost = ? '
        'WHERE id = ?',
        [total.value, total.cost, row.read<String>('id')],
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

  Future<AssetSnapshot?> _latestSnapshotOrNull(String assetId) async {
    final row = await _database
        .customSelect(
          '''
      SELECT rowid AS row_id, id, asset_id, total_value, recorded_at, note,
        total_cost, fx_currency, fx_rate
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

  /// Sums each held asset's most recent recorded value at or before [asOf].
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
    final holdingRows = await _database
        .customSelect('SELECT asset_id FROM holdings')
        .get();
    var total = 0.0;
    var cost = 0.0;
    var hasCost = false;

    for (final holdingRow in holdingRows) {
      final assetId = holdingRow.read<String>('asset_id');
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
              Variable.withString(assetId),
              Variable.withInt(_dateToSql(asOf)),
            ],
          )
          .getSingleOrNull();

      final value = row?.read<double>('total_value') ?? 0;
      final assetCost = row == null
          ? null
          : await _historicalAssetCost(assetId, asOf);
      total += value;
      cost += assetCost ?? value;
      hasCost = hasCost || assetCost != null;
    }

    return (value: total, cost: hasCost ? cost : null);
  }

  double _calculateMonthlyChange(List<PortfolioSnapshot> history) {
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
    List<PortfolioPosition> positions,
    List<AllocationTarget> targets,
  ) {
    if (positions.isEmpty || targets.isEmpty) {
      return 0;
    }

    final actualByCategory = <AssetCategory, double>{};
    for (final position in positions) {
      actualByCategory.update(
        position.category,
        (value) => value + position.allocationPercentage,
        ifAbsent: () => position.allocationPercentage,
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

  Holding _mapHolding(QueryRow row, {String? assetId}) {
    return Holding(
      assetId: assetId ?? row.read<String>('id'),
      currentValue: row.read<double>('current_value'),
      lastUpdatedAt: row.read<DateTime>('last_updated_at'),
      totalCost: row.readNullable<double>('total_cost'),
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
      fxCurrency: row.readNullable<String>('fx_currency'),
      fxRate: row.readNullable<double>('fx_rate'),
    );
  }

  Future<void> _saveSnapshot({
    required String assetId,
    required double totalValue,
    required DateTime recordedAt,
    String? note,
    double? totalCost,
    String? fxCurrency,
    double? fxRate,
  }) async {
    // Nominal rupiah disimpan bulat: hasil konversi kurs menghasilkan pecahan,
    // sedangkan bilangan bulat dalam double selalu eksak saat dijumlahkan.
    //
    // The snapshot id already encodes assetId + local year/month, so
    // replacing by id is both the dedup key and timezone-safe. (A prior
    // version deduped via `strftime(..., 'unixepoch')`, which computes the
    // month in UTC -- for timezones ahead of UTC (e.g. WIB/UTC+7), an
    // early-morning date on the 1st of a month can fall on the previous
    // UTC month and miss the existing row.)
    await _database.customStatement(
      '''
      INSERT OR REPLACE INTO asset_snapshots (
        id, asset_id, total_value, recorded_at, note, total_cost,
        fx_currency, fx_rate
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        _buildSnapshotId(assetId, recordedAt),
        assetId,
        totalValue.roundToDouble(),
        _dateToSql(recordedAt),
        note,
        totalCost?.roundToDouble(),
        fxCurrency,
        fxRate,
      ],
    );
  }
}

String? _normalizePriceCurrency(String? currency) {
  final trimmed = currency?.trim().toUpperCase();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String _buildSnapshotId(String prefix, DateTime recordedAt) {
  final month = recordedAt.month.toString().padLeft(2, '0');
  return '$prefix-${recordedAt.year}-$month';
}

int _dateToSql(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;

/// Prefix id snapshot portofolio; sama dengan id sentinel lama supaya baris
/// hasil migrasi v8 tetap ter-dedup per bulan.
const _portfolioSnapshotPrefix = 'portfolio';
