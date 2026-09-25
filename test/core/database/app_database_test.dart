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

    test('clears existing version 1 portfolio data on upgrade', () async {
      _createVersionOneDatabase(databaseFile);

      final database = AppDatabase.forTesting(
        NativeDatabase.createInBackground(databaseFile),
      );
      addTearDown(database.close);

      expect(await _countRows(database, 'assets'), 0);
      expect(await _countRows(database, 'asset_snapshots'), 0);
      expect(await _countRows(database, 'allocation_targets'), 0);
    });

    test(
      'carries empty total_cost into holdings on upgrade from version 3',
      () async {
        _createVersionOneDatabase(databaseFile, userVersion: 3);

        final database = AppDatabase.forTesting(
          NativeDatabase.createInBackground(databaseFile),
        );
        addTearDown(database.close);

        final row = await database
            .customSelect(
              "SELECT total_cost FROM holdings WHERE asset_id = 'btc'",
            )
            .getSingle();
        expect(row.readNullable<double>('total_cost'), isNull);
      },
    );

    test(
      'adds market_symbol column and market_quotes table on upgrade from '
      'version 5',
      () async {
        _createVersionOneDatabase(databaseFile, userVersion: 5);

        final database = AppDatabase.forTesting(
          NativeDatabase.createInBackground(databaseFile),
        );
        addTearDown(database.close);

        final row = await database
            .customSelect("SELECT market_symbol FROM assets WHERE id = 'btc'")
            .getSingle();
        expect(row.readNullable<String>('market_symbol'), isNull);

        // Existing asset data survives the migration untouched.
        final nameRow = await database
            .customSelect("SELECT name FROM assets WHERE id = 'btc'")
            .getSingle();
        expect(nameRow.read<String>('name'), 'Bitcoin');

        expect(await _countRows(database, 'market_quotes'), 0);
      },
    );

    test(
      'splits assets into master data and holdings on upgrade from version 7',
      () async {
        _createVersionOneDatabase(databaseFile, userVersion: 7);
        _seedVersionSevenColumns(databaseFile);

        final database = AppDatabase.forTesting(
          NativeDatabase.createInBackground(databaseFile),
        );
        addTearDown(database.close);

        final assetColumns = await _columnNames(database, 'assets');
        expect(assetColumns, {
          'id',
          'name',
          'code',
          'category',
          'market_symbol',
        });

        final master = await database
            .customSelect("SELECT * FROM assets WHERE id = 'btc'")
            .getSingle();
        expect(master.read<String>('name'), 'Bitcoin');
        expect(master.readNullable<String>('market_symbol'), 'BTC-USD');

        final holding = await database
            .customSelect("SELECT * FROM holdings WHERE asset_id = 'btc'")
            .getSingle();
        expect(holding.read<double>('current_value'), 18200000);
        expect(holding.read<double>('total_cost'), 15000000);
        expect(holding.read<double>('quantity'), 0.02);
        expect(holding.read<double>('avg_buy_price'), 60000);
        expect(holding.read<String>('price_currency'), 'USD');
        expect(holding.read<int>('last_updated_at'), 1784055600);

        // Riwayat porto pindah dari baris sentinel ke tabel sendiri.
        final portfolioRows = await database
            .customSelect('SELECT * FROM portfolio_snapshots')
            .get();
        expect(portfolioRows, hasLength(1));
        expect(portfolioRows.single.read<String>('id'), 'portfolio-2026-07');
        expect(portfolioRows.single.read<double>('total_value'), 18200000);
        expect(portfolioRows.single.read<double>('total_cost'), 15000000);

        final sentinelRows = await database
            .customSelect(
              'SELECT COUNT(*) AS count FROM asset_snapshots '
              "WHERE asset_id = 'portfolio'",
            )
            .getSingle();
        expect(sentinelRows.read<int>('count'), 0);
        expect(await _countRows(database, 'asset_snapshots'), 1);
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

void _createVersionOneDatabase(File file, {int userVersion = 1}) {
  final database = sqlite3.sqlite3.open(file.path);
  try {
    database.execute('''
      CREATE TABLE assets (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        category TEXT NOT NULL,
        current_value REAL NOT NULL,
        allocation_percentage REAL NOT NULL,
        last_updated_at INTEGER NOT NULL
      );

      CREATE TABLE asset_snapshots (
        id TEXT PRIMARY KEY NOT NULL,
        asset_id TEXT NOT NULL,
        total_value REAL NOT NULL,
        recorded_at INTEGER NOT NULL,
        note TEXT
      );

      CREATE TABLE allocation_targets (
        id TEXT PRIMARY KEY NOT NULL,
        category TEXT NOT NULL,
        target_percentage REAL NOT NULL
      );

      CREATE INDEX asset_snapshots_asset_recorded_idx
      ON asset_snapshots (asset_id, recorded_at DESC);

      INSERT INTO assets (
        id, name, code, category, current_value, allocation_percentage, last_updated_at
      ) VALUES ('btc', 'Bitcoin', 'BTC', 'crypto', 18200000, 100, 1784055600);

      INSERT INTO asset_snapshots (
        id, asset_id, total_value, recorded_at, note
      ) VALUES ('btc-20260715', 'btc', 18200000, 1784055600, 'Seed lama');

      INSERT INTO allocation_targets (
        id, category, target_percentage
      ) VALUES ('target-crypto', 'crypto', 35);

      PRAGMA user_version = $userVersion;
    ''');
  } finally {
    database.dispose();
  }
}

/// Lengkapi database versi 1 dengan kolom v5-v7 dan baris snapshot
/// sentinel `portfolio`, sehingga menyerupai database v7 sungguhan.
void _seedVersionSevenColumns(File file) {
  final database = sqlite3.sqlite3.open(file.path);
  try {
    database.execute('''
      ALTER TABLE assets ADD COLUMN total_cost REAL;
      ALTER TABLE assets ADD COLUMN market_symbol TEXT;
      ALTER TABLE assets ADD COLUMN quantity REAL;
      ALTER TABLE assets ADD COLUMN avg_buy_price REAL;
      ALTER TABLE assets ADD COLUMN price_currency TEXT;
      ALTER TABLE asset_snapshots ADD COLUMN total_cost REAL;

      CREATE TABLE market_quotes (
        symbol TEXT PRIMARY KEY NOT NULL,
        currency TEXT NOT NULL,
        price REAL NOT NULL,
        previous_close REAL,
        market_time INTEGER NOT NULL,
        fetched_at INTEGER NOT NULL
      );

      UPDATE assets SET total_cost = 15000000, market_symbol = 'BTC-USD',
        quantity = 0.02, avg_buy_price = 60000, price_currency = 'USD'
      WHERE id = 'btc';

      INSERT INTO asset_snapshots (
        id, asset_id, total_value, recorded_at, note, total_cost
      ) VALUES (
        'portfolio-2026-07', 'portfolio', 18200000, 1784055600, NULL, 15000000
      );
    ''');
  } finally {
    database.dispose();
  }
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

Future<Set<String>> _columnNames(AppDatabase database, String table) async {
  final rows = await database.customSelect('PRAGMA table_info($table)').get();
  return {for (final row in rows) row.read<String>('name')};
}

Future<int> _countRows(AppDatabase database, String tableName) async {
  final row = await database
      .customSelect('SELECT COUNT(*) AS count FROM $tableName')
      .getSingle();
  return row.read<int>('count');
}
