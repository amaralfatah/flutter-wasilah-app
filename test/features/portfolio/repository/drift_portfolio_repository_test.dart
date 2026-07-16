import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/allocation_target.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/repository/drift_portfolio_repository.dart';

void main() {
  group('DriftPortfolioRepository', () {
    late Directory tempDirectory;
    late File databaseFile;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp('wasilah_test_');
      databaseFile = File('${tempDirectory.path}/wasilah.sqlite');
    });

    tearDown(() async {
      await tempDirectory.delete(recursive: true);
    });

    test('starts with an empty portfolio on first launch', () async {
      final database = AppDatabase.forTesting(
        NativeDatabase.createInBackground(databaseFile),
      );
      addTearDown(database.close);
      final repository = DriftPortfolioRepository(database);

      final assets = await repository.getAssets();
      final targets = await repository.getAllocationTargets();
      final summary = await repository.getPortfolioSummary();

      expect(assets, isEmpty);
      expect(targets, isEmpty);
      expect(summary.totalValue, 0);
      expect(summary.monthlyChangePercentage, 0);
      expect(summary.targetProgressPercentage, 0);
      expect(summary.assets, isEmpty);
    });

    test('persists updated asset value after reopening the database', () async {
      final firstDatabase = AppDatabase.forTesting(
        NativeDatabase.createInBackground(databaseFile),
      );
      await _insertAsset(firstDatabase);
      final firstRepository = DriftPortfolioRepository(firstDatabase);

      await firstRepository.updateAssetValue(
        assetId: 'btc',
        totalValue: 50000000,
        recordedAt: DateTime(2026, 7, 15),
        note: 'Update Juli',
      );
      await firstDatabase.close();

      final reopenedDatabase = AppDatabase.forTesting(
        NativeDatabase.createInBackground(databaseFile),
      );
      addTearDown(reopenedDatabase.close);
      final reopenedRepository = DriftPortfolioRepository(reopenedDatabase);

      final asset = await reopenedRepository.getAssetById('btc');
      final history = await reopenedRepository.getAssetHistory('btc');
      final summary = await reopenedRepository.getPortfolioSummary();

      expect(asset, isNotNull);
      expect(asset!.currentValue, 50000000);
      expect(asset.lastUpdatedAt, DateTime(2026, 7, 15));
      expect(history, hasLength(1));
      expect(history.first.note, 'Update Juli');
      expect(history.first.totalValue, 50000000);
      expect(summary.totalValue, 50000000);
    });

    test(
      'replaces same-day asset history when updated twice on one date',
      () async {
        final database = AppDatabase.forTesting(
          NativeDatabase.createInBackground(databaseFile),
        );
        addTearDown(database.close);
        await _insertAsset(database);
        final repository = DriftPortfolioRepository(database);
        final recordedAt = DateTime(2026, 7, 16);

        await repository.updateAssetValue(
          assetId: 'btc',
          totalValue: 20000000,
          recordedAt: recordedAt,
          note: 'Update pagi',
        );

        await repository.updateAssetValue(
          assetId: 'btc',
          totalValue: 21000000,
          recordedAt: recordedAt,
          note: 'Update sore',
        );

        final asset = await repository.getAssetById('btc');
        final history = await repository.getAssetHistory('btc');

        expect(asset, isNotNull);
        expect(asset!.currentValue, 21000000);
        expect(asset.lastUpdatedAt, recordedAt);
        expect(history, hasLength(1));
        expect(history.first.recordedAt, recordedAt);
        expect(history.first.totalValue, 21000000);
        expect(history.first.note, 'Update sore');
      },
    );

    test('creates, edits, and deletes assets', () async {
      final database = AppDatabase.forTesting(
        NativeDatabase.createInBackground(databaseFile),
      );
      addTearDown(database.close);
      final repository = DriftPortfolioRepository(database);
      final recordedAt = DateTime(2026, 7, 16);

      await repository.createAsset(
        Asset(
          id: 'gold',
          name: 'Emas',
          code: 'XAU',
          category: AssetCategory.preciousMetal,
          currentValue: 12000000,
          allocationPercentage: 0,
          lastUpdatedAt: recordedAt,
        ),
      );

      var asset = await repository.getAssetById('gold');
      var history = await repository.getAssetHistory('gold');

      expect(asset, isNotNull);
      expect(asset!.name, 'Emas');
      expect(asset.allocationPercentage, 100);
      expect(history, hasLength(1));
      expect(history.first.totalValue, 12000000);

      await repository.updateAsset(
        asset.copyWith(
          name: 'Logam Mulia',
          code: 'LM',
          category: AssetCategory.preciousMetal,
        ),
      );

      asset = await repository.getAssetById('gold');

      expect(asset, isNotNull);
      expect(asset!.name, 'Logam Mulia');
      expect(asset.code, 'LM');
      expect(asset.category, AssetCategory.preciousMetal);
      expect(asset.currentValue, 12000000);

      await repository.deleteAsset('gold');

      expect(await repository.getAssetById('gold'), isNull);
      expect(await repository.getAssetHistory('gold'), isEmpty);
      expect(await repository.getAssets(), isEmpty);
    });

    test('saves and deletes allocation targets', () async {
      final database = AppDatabase.forTesting(
        NativeDatabase.createInBackground(databaseFile),
      );
      addTearDown(database.close);
      final repository = DriftPortfolioRepository(database);

      await repository.saveAllocationTarget(
        const AllocationTarget(
          id: 'target-cash',
          category: AssetCategory.cash,
          targetPercentage: 40,
        ),
      );

      var targets = await repository.getAllocationTargets();

      expect(targets, hasLength(1));
      expect(targets.first.category, AssetCategory.cash);
      expect(targets.first.targetPercentage, 40);

      await repository.saveAllocationTarget(
        const AllocationTarget(
          id: 'target-cash-updated',
          category: AssetCategory.cash,
          targetPercentage: 55,
        ),
      );

      targets = await repository.getAllocationTargets();

      expect(targets, hasLength(1));
      expect(targets.first.id, 'target-cash-updated');
      expect(targets.first.targetPercentage, 55);

      await repository.deleteAllocationTarget('target-cash-updated');

      expect(await repository.getAllocationTargets(), isEmpty);
    });
  });
}

Future<void> _insertAsset(AppDatabase database) async {
  await database.customStatement(
    '''
    INSERT INTO assets (
      id, name, code, category, current_value, allocation_percentage, last_updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      'btc',
      'Bitcoin',
      'BTC',
      'crypto',
      18200000,
      100,
      DateTime(2026, 7, 15).millisecondsSinceEpoch ~/ 1000,
    ],
  );
}
