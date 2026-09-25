import 'package:drift/drift.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/asset_repository.dart';

class DriftAssetRepository implements AssetRepository {
  DriftAssetRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<Asset>> getAssets() async {
    final rows = await _database.customSelect('''
      SELECT id, name, code, category, market_symbol
      FROM assets
      ORDER BY name ASC
      ''').get();

    return rows.map(mapAssetRow).toList(growable: false);
  }

  @override
  Future<Asset?> getAssetById(String assetId) async {
    final row = await _database
        .customSelect(
          '''
      SELECT id, name, code, category, market_symbol
      FROM assets
      WHERE id = ?
      LIMIT 1
      ''',
          variables: [Variable.withString(assetId)],
        )
        .getSingleOrNull();

    return row == null ? null : mapAssetRow(row);
  }

  @override
  Future<void> createAsset(Asset asset) async {
    await _database.customStatement(
      '''
      INSERT INTO assets (id, name, code, category, market_symbol)
      VALUES (?, ?, ?, ?, ?)
      ''',
      [
        asset.id,
        asset.name,
        asset.code,
        asset.category.name,
        normalizeMarketSymbol(asset.marketSymbol),
      ],
    );
  }

  @override
  Future<void> updateAsset(Asset asset) async {
    await _database.customUpdate(
      '''
      UPDATE assets
      SET name = ?, code = ?, category = ?, market_symbol = ?
      WHERE id = ?
      ''',
      variables: [
        Variable.withString(asset.name),
        Variable.withString(asset.code),
        Variable.withString(asset.category.name),
        Variable<String>(normalizeMarketSymbol(asset.marketSymbol)),
        Variable.withString(asset.id),
      ],
    );
  }

  @override
  Future<void> deleteAsset(String assetId) async {
    await _database.transaction(() async {
      final row = await _database
          .customSelect(
            '''
        SELECT
          (SELECT COUNT(*) FROM holdings WHERE asset_id = ?) +
          (SELECT COUNT(*) FROM asset_snapshots WHERE asset_id = ?) AS usage
        ''',
            variables: [
              Variable.withString(assetId),
              Variable.withString(assetId),
            ],
          )
          .getSingle();
      if (row.read<int>('usage') > 0) {
        throw const AssetHasHoldingException();
      }

      await _database.customStatement('DELETE FROM assets WHERE id = ?', [
        assetId,
      ]);
    });
  }
}

Asset mapAssetRow(QueryRow row) {
  return Asset(
    id: row.read<String>('id'),
    name: row.read<String>('name'),
    code: row.read<String>('code'),
    category: AssetCategory.fromName(row.read<String>('category')),
    marketSymbol: row.readNullable<String>('market_symbol'),
  );
}

/// Huruf besar, di-trim; string kosong dianggap tidak ada simbol.
String? normalizeMarketSymbol(String? symbol) {
  final trimmed = symbol?.trim().toUpperCase();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
