import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
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

    test('seeds default portfolio data on first launch', () async {
      final database = AppDatabase.forTesting(
        NativeDatabase.createInBackground(databaseFile),
      );
      addTearDown(database.close);
      final repository = DriftPortfolioRepository(database);

      final assets = await repository.getAssets();
      final targets = await repository.getAllocationTargets();
      final summary = await repository.getPortfolioSummary();

      expect(assets, hasLength(5));
      expect(targets, hasLength(4));
      expect(summary.totalValue, 55000000);
    });

    test('persists updated asset value after reopening the database', () async {
      final firstDatabase = AppDatabase.forTesting(
        NativeDatabase.createInBackground(databaseFile),
      );
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
      expect(history, hasLength(3));
      expect(history.first.note, 'Update Juli');
      expect(summary.totalValue, 86800000);
    });
  });
}
