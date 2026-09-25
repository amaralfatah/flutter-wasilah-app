import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  group('AppDatabase', () {
    late Directory tempDirectory;
    late File databaseFile;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp('wasilah_db_test_');
      databaseFile = File('${tempDirectory.path}/wasilah.sqlite');
    });

    tearDown(() async {
      await tempDirectory.delete(recursive: true);
    });

    test(
      'refuses to upgrade a database older than the supported minimum',
      () async {
        final raw = sqlite3.sqlite3.open(databaseFile.path);
        try {
          raw.execute('''
          CREATE TABLE assets (id TEXT PRIMARY KEY NOT NULL);
          PRAGMA user_version = 7;
        ''');
        } finally {
          raw.dispose();
        }

        final database = AppDatabase.forTesting(
          NativeDatabase.createInBackground(databaseFile),
        );
        addTearDown(database.close);

        await expectLater(
          database.customSelect('SELECT 1').get(),
          throwsA(anything),
        );
      },
    );

    test('rounds stored rupiah amounts on upgrade from version 8', () async {
      final fresh = AppDatabase.forTesting(
        NativeDatabase.createInBackground(databaseFile),
      );
      await fresh.customSelect('SELECT 1').get();
      await fresh.close();
      _seedFractionalVersionEight(databaseFile);

      final database = AppDatabase.forTesting(
        NativeDatabase.createInBackground(databaseFile),
      );
      addTearDown(database.close);

      final holding = await database
          .customSelect("SELECT * FROM holdings WHERE asset_id = 'btc'")
          .getSingle();
      expect(holding.read<double>('current_value'), 18200001);
      expect(holding.read<double>('total_cost'), 15000000);
      expect(holding.read<double>('quantity'), 0.0234);
      expect(holding.read<double>('avg_buy_price'), 60000.55);

      final snapshot = await database
          .customSelect('SELECT * FROM asset_snapshots')
          .getSingle();
      expect(snapshot.read<double>('total_value'), 18200001);
      expect(snapshot.readNullable<double>('total_cost'), isNull);

      final portfolio = await database
          .customSelect('SELECT * FROM portfolio_snapshots')
          .getSingle();
      expect(portfolio.read<double>('total_value'), 18200001);
      expect(portfolio.read<double>('total_cost'), 15000000);
    });

    test(
      'adds empty exchange-rate columns to asset_snapshots on upgrade from '
      'version 9',
      () async {
        final fresh = AppDatabase.forTesting(
          NativeDatabase.createInBackground(databaseFile),
        );
        await fresh.customSelect('SELECT 1').get();
        await fresh.close();
        _downgradeToVersionNine(databaseFile);

        final database = AppDatabase.forTesting(
          NativeDatabase.createInBackground(databaseFile),
        );
        addTearDown(database.close);

        final snapshot = await database
            .customSelect('SELECT * FROM asset_snapshots')
            .getSingle();
        expect(snapshot.read<double>('total_value'), 18200000);
        expect(snapshot.readNullable<String>('fx_currency'), isNull);
        expect(snapshot.readNullable<double>('fx_rate'), isNull);
      },
    );

    test(
      'dedupes allocation targets per category and adds indexes on upgrade '
      'from version 10',
      () async {
        final fresh = AppDatabase.forTesting(
          NativeDatabase.createInBackground(databaseFile),
        );
        await fresh.customSelect('SELECT 1').get();
        await fresh.close();
        final raw = sqlite3.sqlite3.open(databaseFile.path);
        try {
          raw.execute('''
            DROP INDEX allocation_targets_category_idx;
            DROP INDEX portfolio_snapshots_recorded_idx;
            INSERT INTO allocation_targets (id, category, target_percentage)
            VALUES ('old', 'crypto', 10), ('new', 'crypto', 25);
            PRAGMA user_version = 10;
          ''');
        } finally {
          raw.dispose();
        }

        final database = AppDatabase.forTesting(
          NativeDatabase.createInBackground(databaseFile),
        );
        addTearDown(database.close);

        final targets = await database
            .customSelect('SELECT id FROM allocation_targets')
            .get();
        expect(targets.map((row) => row.read<String>('id')), ['new']);

        final indexes = await database
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'index' "
              "AND name IN ('allocation_targets_category_idx', "
              "'portfolio_snapshots_recorded_idx')",
            )
            .get();
        expect(indexes, hasLength(2));

        await expectLater(
          database.customStatement(
            'INSERT INTO allocation_targets (id, category, target_percentage) '
            "VALUES ('dup', 'crypto', 5)",
          ),
          throwsA(anything),
        );
      },
    );

    test('enforces foreign keys between holdings and assets', () async {
      final database = AppDatabase.forTesting(
        NativeDatabase.createInBackground(databaseFile),
      );
      addTearDown(database.close);

      await expectLater(
        database.customStatement(
          'INSERT INTO holdings (asset_id, current_value, last_updated_at) '
          "VALUES ('ghost', 1, 0)",
        ),
        throwsA(anything),
      );
    });

    test('creates market_quotes on a brand-new database', () async {
      final database = AppDatabase.forTesting(
        NativeDatabase.createInBackground(databaseFile),
      );
      addTearDown(database.close);

      expect(await _countRows(database, 'market_quotes'), 0);
    });
  });
}

/// Isi database skema terkini dengan nominal rupiah pecahan (hasil konversi
/// kurs sebelum pembulatan), lalu turunkan versinya ke 8.
void _seedFractionalVersionEight(File file) {
  final database = sqlite3.sqlite3.open(file.path);
  try {
    database.execute('''
      INSERT INTO assets (id, name, code, category)
      VALUES ('btc', 'Bitcoin', 'BTC', 'crypto');

      INSERT INTO holdings (
        asset_id, current_value, total_cost, quantity, avg_buy_price,
        price_currency, last_updated_at
      ) VALUES ('btc', 18200000.73, 14999999.6, 0.0234, 60000.55, 'USD',
        1784055600);

      INSERT INTO asset_snapshots (
        id, asset_id, total_value, recorded_at, note, total_cost
      ) VALUES ('btc-2026-07', 'btc', 18200000.73, 1784055600, NULL, NULL);

      INSERT INTO portfolio_snapshots (
        id, total_value, total_cost, recorded_at, note
      ) VALUES ('portfolio-2026-07', 18200000.73, 14999999.6, 1784055600,
        NULL);

      PRAGMA user_version = 8;
    ''');
  } finally {
    database.dispose();
  }
}

/// Bentuk ulang `asset_snapshots` seperti skema v9 (tanpa kolom kurs), isi
/// satu baris, lalu turunkan versinya ke 9.
void _downgradeToVersionNine(File file) {
  final database = sqlite3.sqlite3.open(file.path);
  try {
    database.execute('''
      DROP TABLE asset_snapshots;
      CREATE TABLE asset_snapshots (
        id TEXT PRIMARY KEY NOT NULL,
        asset_id TEXT NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
        total_value REAL NOT NULL,
        recorded_at INTEGER NOT NULL,
        note TEXT,
        total_cost REAL
      );

      INSERT INTO assets (id, name, code, category)
      VALUES ('btc', 'Bitcoin', 'BTC', 'crypto');

      INSERT INTO asset_snapshots (
        id, asset_id, total_value, recorded_at, note, total_cost
      ) VALUES ('btc-2026-07', 'btc', 18200000, 1784055600, NULL, NULL);

      PRAGMA user_version = 9;
    ''');
  } finally {
    database.dispose();
  }
}

Future<int> _countRows(AppDatabase database, String tableName) async {
  final row = await database
      .customSelect('SELECT COUNT(*) AS count FROM $tableName')
      .getSingle();
  return row.read<int>('count');
}
