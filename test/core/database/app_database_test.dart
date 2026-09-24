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

    test('adds empty total_cost to assets on upgrade from version 3', () async {
      _createVersionOneDatabase(databaseFile, userVersion: 3);

      final database = AppDatabase.forTesting(
        NativeDatabase.createInBackground(databaseFile),
      );
      addTearDown(database.close);

      final row = await database
          .customSelect("SELECT total_cost FROM assets WHERE id = 'btc'")
          .getSingle();
      expect(row.readNullable<double>('total_cost'), isNull);
    });

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

Future<int> _countRows(AppDatabase database, String tableName) async {
  final row = await database
      .customSelect('SELECT COUNT(*) AS count FROM $tableName')
      .getSingle();
  return row.read<int>('count');
}
