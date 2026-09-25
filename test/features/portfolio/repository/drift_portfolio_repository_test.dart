import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/allocation_target.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/drift_asset_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/drift_portfolio_repository.dart';

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

    AppDatabase openDatabase() =>
        AppDatabase.forTesting(NativeDatabase.createInBackground(databaseFile));

    test('starts with an empty portfolio on first launch', () async {
      final database = openDatabase();
      addTearDown(database.close);
      final repository = DriftPortfolioRepository(database);

      final positions = await repository.getPositions();
      final targets = await repository.getAllocationTargets();
      final summary = await repository.getPortfolioSummary();

      expect(positions, isEmpty);
      expect(targets, isEmpty);
      expect(summary.totalValue, 0);
      expect(summary.monthlyChangePercentage, 0);
      expect(summary.targetProgressPercentage, 0);
      expect(summary.positions, isEmpty);
    });

    test('a master asset without value is not part of the portfolio', () async {
      final database = openDatabase();
      addTearDown(database.close);
      await DriftAssetRepository(database).createAsset(_btc);
      final repository = DriftPortfolioRepository(database);

      expect(await repository.getPositions(), isEmpty);
      expect(await repository.getPositionByAssetId('btc'), isNull);
      expect((await repository.getPortfolioSummary()).totalValue, 0);
    });

    test('first value update creates the holding and persists it', () async {
      final firstDatabase = openDatabase();
      await DriftAssetRepository(firstDatabase).createAsset(_btc);
      await DriftPortfolioRepository(firstDatabase).updateAssetValue(
        assetId: 'btc',
        totalValue: 50000000,
        recordedAt: DateTime(2026, 7, 15),
        note: 'Update Juli',
        quantity: 0.05,
        avgBuyPrice: 60000,
        priceCurrency: 'usd',
      );
      await firstDatabase.close();

      final reopenedDatabase = openDatabase();
      addTearDown(reopenedDatabase.close);
      final repository = DriftPortfolioRepository(reopenedDatabase);

      final position = await repository.getPositionByAssetId('btc');
      final history = await repository.getAssetHistory('btc');
      final summary = await repository.getPortfolioSummary();

      expect(position, isNotNull);
      expect(position!.name, 'Bitcoin');
      expect(position.currentValue, 50000000);
      expect(position.lastUpdatedAt, DateTime(2026, 7, 15));
      expect(position.allocationPercentage, 100);
      expect(position.quantity, 0.05);
      expect(position.avgBuyPrice, 60000);
      expect(position.priceCurrency, 'USD');
      expect(history, hasLength(1));
      expect(history.first.note, 'Update Juli');
      expect(history.first.totalValue, 50000000);
      expect(summary.totalValue, 50000000);
    });

    test(
      'rounds rupiah amounts to whole rupiah but keeps unit price and '
      'quantity precise',
      () async {
        final database = openDatabase();
        addTearDown(database.close);
        await DriftAssetRepository(database).createAsset(_btc);
        await DriftAssetRepository(database).createAsset(_cash);
        final repository = DriftPortfolioRepository(database);

        await repository.updateAssetValue(
          assetId: 'btc',
          totalValue: 16345678.9,
          totalCost: 15000000.4,
          quantity: 0.0123,
          avgBuyPrice: 60000.55,
          priceCurrency: 'USD',
          recordedAt: DateTime(2026, 7),
        );
        await repository.updateAssetValue(
          assetId: 'cash',
          totalValue: 0.1 + 0.2,
          recordedAt: DateTime(2026, 7),
        );

        final position = await repository.getPositionByAssetId('btc');
        final history = await repository.getAssetHistory('btc');
        final portfolio = await repository.getPortfolioHistory();

        expect(position!.currentValue, 16345679);
        expect(position.totalCost, 15000000);
        expect(position.quantity, 0.0123);
        expect(position.avgBuyPrice, 60000.55);
        expect(history.single.totalValue, 16345679);
        expect(history.single.totalCost, 15000000);
        expect(portfolio.single.totalValue, 16345679);
      },
    );

    test('stores the exchange rate used with each asset snapshot', () async {
      final database = openDatabase();
      addTearDown(database.close);
      await DriftAssetRepository(database).createAsset(_btc);
      final repository = DriftPortfolioRepository(database);

      await repository.updateAssetValue(
        assetId: 'btc',
        totalValue: 16400000,
        recordedAt: DateTime(2026, 6),
        fxCurrency: 'usd',
        fxRate: 16400,
      );
      await repository.updateAssetValue(
        assetId: 'btc',
        totalValue: 17000000,
        recordedAt: DateTime(2026, 7),
      );

      final history = await repository.getAssetHistory('btc');
      final june = history.firstWhere(
        (item) => item.recordedAt == DateTime(2026, 6),
      );
      final july = history.firstWhere(
        (item) => item.recordedAt == DateTime(2026, 7),
      );

      expect(june.fxCurrency, 'USD');
      expect(june.fxRate, 16400);
      expect(july.fxCurrency, isNull);
      expect(july.fxRate, isNull);
    });

    test(
      'replaces same-day asset history when updated twice on one date',
      () async {
        final database = openDatabase();
        addTearDown(database.close);
        await DriftAssetRepository(database).createAsset(_btc);
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

        final position = await repository.getPositionByAssetId('btc');
        final history = await repository.getAssetHistory('btc');

        expect(position!.currentValue, 21000000);
        expect(position.lastUpdatedAt, recordedAt);
        expect(history, hasLength(1));
        expect(history.first.recordedAt, recordedAt);
        expect(history.first.totalValue, 21000000);
        expect(history.first.note, 'Update sore');
      },
    );

    test(
      'keeps quantity, price and cost when an update leaves them empty',
      () async {
        final database = openDatabase();
        addTearDown(database.close);
        await DriftAssetRepository(database).createAsset(_btc);
        final repository = DriftPortfolioRepository(database);

        await repository.updateAssetValue(
          assetId: 'btc',
          totalValue: 10000000,
          recordedAt: DateTime(2026, 6),
          quantity: 0.1,
          avgBuyPrice: 50000,
          priceCurrency: 'USD',
          totalCost: 8000000,
        );
        await repository.updateAssetValue(
          assetId: 'btc',
          totalValue: 12000000,
          recordedAt: DateTime(2026, 7),
        );

        final position = await repository.getPositionByAssetId('btc');
        expect(position!.quantity, 0.1);
        expect(position.avgBuyPrice, 50000);
        expect(position.priceCurrency, 'USD');
        expect(position.totalCost, 8000000);
        expect(position.profitLoss, 4000000);
        expect(position.profitLossPercentage, 50);
      },
    );

    test(
      'backdated updates use each asset historical value, not its current '
      'value',
      () async {
        final database = openDatabase();
        addTearDown(database.close);
        final repository = DriftPortfolioRepository(database);

        await _track(database, _btc, 10000000, DateTime(2026, 5));
        await _track(database, _cash, 5000000, DateTime(2026, 5));

        // Bring btc up to date across two more months.
        await repository.updateAssetValue(
          assetId: 'btc',
          totalValue: 12000000,
          recordedAt: DateTime(2026, 6),
        );
        await repository.updateAssetValue(
          assetId: 'btc',
          totalValue: 15000000,
          recordedAt: DateTime(2026, 7),
        );

        final history = await repository.getPortfolioHistory();
        double totalAt(DateTime date) =>
            history.firstWhere((item) => item.recordedAt == date).totalValue;

        // Cash never changes, so each month's total should reflect btc's
        // value at that point in time, not its final (July) value.
        expect(totalAt(DateTime(2026, 5)), 15000000);
        expect(totalAt(DateTime(2026, 6)), 17000000);
        expect(totalAt(DateTime(2026, 7)), 20000000);
      },
    );

    test(
      'a backdated update recalculates later portfolio months that carry it '
      'forward, keeping their notes',
      () async {
        final database = openDatabase();
        addTearDown(database.close);
        final repository = DriftPortfolioRepository(database);

        await _track(database, _btc, 10000000, DateTime(2026, 5));
        await _track(database, _cash, 5000000, DateTime(2026, 5));
        await repository.updateAssetValue(
          assetId: 'btc',
          totalValue: 12000000,
          recordedAt: DateTime(2026, 6),
        );
        await repository.updateAssetValue(
          assetId: 'btc',
          totalValue: 15000000,
          recordedAt: DateTime(2026, 7),
          note: 'Update Juli',
        );

        // Cash for June is corrected afterwards; July has no cash snapshot
        // of its own, so it carries June's corrected value forward.
        await repository.updateAssetValue(
          assetId: 'cash',
          totalValue: 8000000,
          recordedAt: DateTime(2026, 6),
        );

        final history = await repository.getPortfolioHistory();
        final july = history.firstWhere(
          (item) => item.recordedAt == DateTime(2026, 7),
        );
        final may = history.firstWhere(
          (item) => item.recordedAt == DateTime(2026, 5),
        );

        expect(may.totalValue, 15000000);
        expect(july.totalValue, 23000000);
        expect(july.note, 'Update Juli');
      },
    );

    test(
      'deleting a past asset snapshot recalculates later portfolio months',
      () async {
        final database = openDatabase();
        addTearDown(database.close);
        final repository = DriftPortfolioRepository(database);

        await _track(database, _btc, 10000000, DateTime(2026, 5));
        await _track(database, _cash, 5000000, DateTime(2026, 5));
        await repository.updateAssetValue(
          assetId: 'cash',
          totalValue: 8000000,
          recordedAt: DateTime(2026, 6),
        );
        await repository.updateAssetValue(
          assetId: 'btc',
          totalValue: 15000000,
          recordedAt: DateTime(2026, 7),
        );

        final cashJune = (await repository.getAssetHistory(
          'cash',
        )).firstWhere((item) => item.recordedAt == DateTime(2026, 6));
        await repository.deleteAssetSnapshot(cashJune.id);

        final history = await repository.getPortfolioHistory();
        final july = history.firstWhere(
          (item) => item.recordedAt == DateTime(2026, 7),
        );
        expect(july.totalValue, 20000000);
      },
    );

    test(
      'a backdated update does not overwrite the asset current value',
      () async {
        final database = openDatabase();
        addTearDown(database.close);
        final repository = DriftPortfolioRepository(database);

        await _track(database, _btc, 10000000, DateTime(2026, 7));

        // The latest known value is set in July...
        await repository.updateAssetValue(
          assetId: 'btc',
          totalValue: 20000000,
          recordedAt: DateTime(2026, 7, 15),
        );

        // ...then the user fills in a missed entry for an earlier month.
        await repository.updateAssetValue(
          assetId: 'btc',
          totalValue: 5000000,
          recordedAt: DateTime(2026, 5),
        );

        final position = await repository.getPositionByAssetId('btc');
        final summary = await repository.getPortfolioSummary();

        // current_value must stay pinned to the latest chronological entry
        // (July), not the value that happened to be entered last (May).
        expect(position!.currentValue, 20000000);
        expect(position.lastUpdatedAt, DateTime(2026, 7, 15));
        expect(summary.totalValue, 20000000);
      },
    );

    test(
      'backfilling one asset for a past month excludes assets not yet '
      'tracked back then, instead of using their current value',
      () async {
        final database = openDatabase();
        addTearDown(database.close);
        final repository = DriftPortfolioRepository(database);

        // btc is tracked from this month (July) with no prior history.
        await _track(database, _btc, 20000000, DateTime(2026, 7));

        // gold is a second asset the user just started tracking, and they
        // backfill its value for last month (June), which btc has no
        // record of.
        await _track(database, _gold, 5000000, DateTime(2026, 7));
        await repository.updateAssetValue(
          assetId: 'gold',
          totalValue: 3000000,
          recordedAt: DateTime(2026, 6),
        );

        final history = await repository.getPortfolioHistory();
        final juneEntry = history.firstWhere(
          (item) => item.recordedAt == DateTime(2026, 6),
        );

        // June's total should be just gold's backfilled value (3M) -- btc
        // didn't exist back then and must not be padded in at its current
        // (July) value of 20M.
        expect(juneEntry.totalValue, 3000000);
      },
    );

    test(
      'deleting last month value updates the monthly portfolio history',
      () async {
        final database = openDatabase();
        addTearDown(database.close);
        final repository = DriftPortfolioRepository(database);

        await _track(database, _btc, 10000000, DateTime(2026, 6));
        await repository.updateAssetValue(
          assetId: 'btc',
          totalValue: 15000000,
          recordedAt: DateTime(2026, 7),
        );

        var history = await repository.getPortfolioHistory();
        expect(
          history
              .firstWhere((item) => item.recordedAt == DateTime(2026, 7))
              .totalValue,
          15000000,
        );

        final assetHistory = await repository.getAssetHistory('btc');
        final julySnapshot = assetHistory.firstWhere(
          (item) => item.recordedAt == DateTime(2026, 7),
        );
        await repository.deleteAssetSnapshot(julySnapshot.id);

        final position = await repository.getPositionByAssetId('btc');
        final summary = await repository.getPortfolioSummary();
        history = await repository.getPortfolioHistory();
        final updatedJulyEntry = history.firstWhere(
          (item) => item.recordedAt == DateTime(2026, 7),
        );

        // With July's value deleted, btc (and thus the portfolio) should
        // fall back to June's value everywhere, not stay stuck at 15M.
        expect(position!.currentValue, 10000000);
        expect(summary.totalValue, 10000000);
        expect(updatedJulyEntry.totalValue, 10000000);
      },
    );

    test(
      'deleting the only snapshot removes the holding but keeps the master',
      () async {
        final database = openDatabase();
        addTearDown(database.close);
        final repository = DriftPortfolioRepository(database);
        await _track(database, _btc, 10000000, DateTime(2026, 7));

        final snapshot = (await repository.getAssetHistory('btc')).single;
        await repository.deleteAssetSnapshot(snapshot.id);

        expect(await repository.getPositionByAssetId('btc'), isNull);
        expect(
          await DriftAssetRepository(database).getAssetById('btc'),
          isNotNull,
        );
      },
    );

    test('deletes a portfolio snapshot independently', () async {
      final database = openDatabase();
      addTearDown(database.close);
      final repository = DriftPortfolioRepository(database);
      await _track(database, _btc, 10000000, DateTime(2026, 7));

      final snapshot = (await repository.getPortfolioHistory()).single;
      await repository.deletePortfolioSnapshot(snapshot.id);

      expect(await repository.getPortfolioHistory(), isEmpty);
      expect(await repository.getAssetHistory('btc'), hasLength(1));
      expect(
        (await repository.getPositionByAssetId('btc'))!.currentValue,
        10000000,
      );
    });

    test(
      'removeFromPortfolio drops holding and history, then recomputes totals',
      () async {
        final database = openDatabase();
        addTearDown(database.close);
        final repository = DriftPortfolioRepository(database);
        await _track(database, _btc, 10000000, DateTime(2026, 7));
        await _track(database, _cash, 5000000, DateTime(2026, 7));

        await repository.removeFromPortfolio('btc');

        final positions = await repository.getPositions();
        final history = await repository.getPortfolioHistory();
        expect(positions.map((position) => position.id), ['cash']);
        expect(positions.single.allocationPercentage, 100);
        expect(await repository.getAssetHistory('btc'), isEmpty);
        expect(history.single.totalValue, 5000000);
        expect(
          await DriftAssetRepository(database).getAssetById('btc'),
          isNotNull,
        );
      },
    );

    test('throws when updating the value of an unknown asset', () async {
      final database = openDatabase();
      addTearDown(database.close);
      final repository = DriftPortfolioRepository(database);

      await expectLater(
        repository.updateAssetValue(
          assetId: 'ghost',
          totalValue: 1,
          recordedAt: DateTime(2026, 7),
        ),
        throwsStateError,
      );
    });

    test('announces every write on the changes stream', () async {
      final database = openDatabase();
      addTearDown(database.close);
      final repository = DriftPortfolioRepository(database);
      var count = 0;
      final subscription = repository.changes.listen((_) => count++);
      addTearDown(subscription.cancel);

      await DriftAssetRepository(database).createAsset(_btc);
      await repository.updateAssetValue(
        assetId: 'btc',
        totalValue: 1000,
        recordedAt: DateTime(2026, 7),
      );
      await repository.getPositions();
      await pumpEventQueue();

      expect(count, 2);
    });

    test('skips allocation targets with an unknown category', () async {
      final database = openDatabase();
      addTearDown(database.close);
      final repository = DriftPortfolioRepository(database);
      await database.customStatement(
        'INSERT INTO allocation_targets (id, category, target_percentage) '
        "VALUES ('t-bond', 'bond', 20), ('t-cash', 'cash', 10)",
      );

      final targets = await repository.getAllocationTargets();

      expect(targets.map((target) => target.category), [AssetCategory.cash]);
      final summary = await repository.getPortfolioSummary();
      expect(summary.totalValue, 0);
    });

    test('saves and deletes allocation targets', () async {
      final database = openDatabase();
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

    test(
      'target progress stays above zero when targets exist but allocation '
      'is still imbalanced',
      () async {
        final database = openDatabase();
        addTearDown(database.close);
        final repository = DriftPortfolioRepository(database);

        await _track(
          database,
          const Asset(
            id: 'bbri',
            name: 'Bank Rakyat Indonesia',
            code: 'BBRI',
            category: AssetCategory.stock,
          ),
          12000000,
          DateTime(2026, 7, 16),
        );

        await repository.saveAllocationTarget(
          const AllocationTarget(
            id: 'target-stock',
            category: AssetCategory.stock,
            targetPercentage: 50,
          ),
        );
        await repository.saveAllocationTarget(
          const AllocationTarget(
            id: 'target-cash',
            category: AssetCategory.cash,
            targetPercentage: 50,
          ),
        );

        final summary = await repository.getPortfolioSummary();

        expect(summary.targetProgressPercentage, 50);
      },
    );
  });
}

const _btc = Asset(
  id: 'btc',
  name: 'Bitcoin',
  code: 'BTC',
  category: AssetCategory.crypto,
);

const _cash = Asset(
  id: 'cash',
  name: 'Kas',
  code: 'CASH',
  category: AssetCategory.cash,
);

const _gold = Asset(
  id: 'gold',
  name: 'Emas',
  code: 'XAU',
  category: AssetCategory.preciousMetal,
);

/// Buat master aset lalu isi nilai pertamanya (alur tambah aset dua langkah).
Future<void> _track(
  AppDatabase database,
  Asset asset,
  double value,
  DateTime recordedAt,
) async {
  await DriftAssetRepository(database).createAsset(asset);
  await DriftPortfolioRepository(database).updateAssetValue(
    assetId: asset.id,
    totalValue: value,
    recordedAt: recordedAt,
  );
}
