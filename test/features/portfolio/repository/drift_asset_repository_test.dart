import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/drift_asset_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/drift_portfolio_repository.dart';

void main() {
  group('DriftAssetRepository', () {
    late AppDatabase database;
    late DriftAssetRepository repository;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repository = DriftAssetRepository(database);
    });

    tearDown(() => database.close());

    test('creates, edits, and deletes a master asset', () async {
      await repository.createAsset(_gold);

      var asset = await repository.getAssetById('gold');
      expect(asset, _gold);

      await repository.updateAsset(
        asset!.copyWith(name: 'Logam Mulia', code: 'LM'),
      );
      asset = await repository.getAssetById('gold');
      expect(asset!.name, 'Logam Mulia');
      expect(asset.code, 'LM');
      expect(asset.category, AssetCategory.preciousMetal);

      await repository.deleteAsset('gold');
      expect(await repository.getAssetById('gold'), isNull);
      expect(await repository.getAssets(), isEmpty);
    });

    test(
      'normalizes and persists marketSymbol, and clears it back to null',
      () async {
        await repository.createAsset(
          const Asset(
            id: 'bmri',
            name: 'Bank Mandiri',
            code: 'BMRI',
            category: AssetCategory.stock,
            // Lowercase and padded with whitespace on purpose: the
            // repository must normalize it to trimmed, uppercase.
            marketSymbol: '  bmri.jk  ',
          ),
        );

        var asset = await repository.getAssetById('bmri');
        expect(asset?.marketSymbol, 'BMRI.JK');

        await repository.updateAsset(asset!.copyWith(marketSymbol: ''));

        asset = await repository.getAssetById('bmri');
        expect(asset?.marketSymbol, isNull);
      },
    );

    test('refuses to delete an asset that is still in the portfolio', () async {
      await repository.createAsset(_gold);
      final portfolio = DriftPortfolioRepository(database);
      await portfolio.updateAssetValue(
        assetId: 'gold',
        totalValue: 12000000,
        recordedAt: DateTime(2026, 7, 16),
      );

      await expectLater(
        repository.deleteAsset('gold'),
        throwsA(isA<AssetHasHoldingException>()),
      );
      expect(await repository.getAssetById('gold'), isNotNull);

      await portfolio.removeFromPortfolio('gold');
      await repository.deleteAsset('gold');
      expect(await repository.getAssetById('gold'), isNull);
    });
  });
}

const _gold = Asset(
  id: 'gold',
  name: 'Emas',
  code: 'XAU',
  category: AssetCategory.preciousMetal,
);
