import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

class AppDatabase extends GeneratedDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 7;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await customStatement('''
        CREATE TABLE assets (
          id TEXT PRIMARY KEY NOT NULL,
          -- Master aset: identitas & atribut yang diubah lewat form edit aset.
          name TEXT NOT NULL,
          code TEXT NOT NULL,
          category TEXT NOT NULL,
          market_symbol TEXT,
          quantity REAL,
          avg_buy_price REAL,
          price_currency TEXT,
          -- Porto: nilai yang diubah lewat update nilai portofolio.
          current_value REAL NOT NULL,
          allocation_percentage REAL NOT NULL,
          total_cost REAL,
          last_updated_at INTEGER NOT NULL
        );
      ''');

      await customStatement('''
        CREATE TABLE market_quotes (
          symbol TEXT PRIMARY KEY NOT NULL,
          currency TEXT NOT NULL,
          price REAL NOT NULL,
          previous_close REAL,
          market_time INTEGER NOT NULL,
          fetched_at INTEGER NOT NULL
        );
      ''');

      await customStatement('''
        CREATE TABLE asset_snapshots (
          id TEXT PRIMARY KEY NOT NULL,
          asset_id TEXT NOT NULL,
          total_value REAL NOT NULL,
          recorded_at INTEGER NOT NULL,
          note TEXT,
          total_cost REAL
        );
      ''');

      await customStatement('''
        CREATE TABLE allocation_targets (
          id TEXT PRIMARY KEY NOT NULL,
          category TEXT NOT NULL,
          target_percentage REAL NOT NULL
        );
      ''');

      await customStatement('''
        CREATE INDEX asset_snapshots_asset_recorded_idx
        ON asset_snapshots (asset_id, recorded_at DESC);
      ''');
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await customStatement('DELETE FROM asset_snapshots');
        await customStatement('DELETE FROM assets');
        await customStatement('DELETE FROM allocation_targets');
      }
      if (from < 3) {
        // Keep only the latest snapshot per asset per month, dropping
        // duplicates created before history was deduplicated by month.
        await customStatement('''
          DELETE FROM asset_snapshots
          WHERE rowid NOT IN (
            SELECT MAX(rowid)
            FROM asset_snapshots
            GROUP BY asset_id, strftime('%Y-%m', recorded_at, 'unixepoch')
          );
        ''');
      }
      if (from < 5) {
        // NULL = modal belum diisi, sehingga PnL data lama tidak dihitung.
        // Build v4 awal hanya menambah kolom di `assets`, jadi setiap kolom
        // dicek dulu supaya database v4 itu tetap ikut dilengkapi.
        await _addColumnIfMissing('assets', 'total_cost', 'REAL');
        await _addColumnIfMissing('asset_snapshots', 'total_cost', 'REAL');
      }
      if (from < 6) {
        await _addColumnIfMissing('assets', 'market_symbol', 'TEXT');
        await customStatement('''
          CREATE TABLE IF NOT EXISTS market_quotes (
            symbol TEXT PRIMARY KEY NOT NULL,
            currency TEXT NOT NULL,
            price REAL NOT NULL,
            previous_close REAL,
            market_time INTEGER NOT NULL,
            fetched_at INTEGER NOT NULL
          );
        ''');
      }
      if (from < 7) {
        await _addColumnIfMissing('assets', 'quantity', 'REAL');
        await _addColumnIfMissing('assets', 'avg_buy_price', 'REAL');
        await _addColumnIfMissing('assets', 'price_currency', 'TEXT');
      }
    },
  );

  Future<void> _addColumnIfMissing(
    String table,
    String column,
    String type,
  ) async {
    final columns = await customSelect('PRAGMA table_info($table)').get();
    if (columns.any((row) => row.read<String>('name') == column)) {
      return;
    }
    await customStatement('ALTER TABLE $table ADD COLUMN $column $type');
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

const String databaseFileName = 'wasilah.sqlite';

Future<File> resolveDatabaseFile() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  return File(p.join(dbFolder.path, databaseFileName));
}

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final file = await resolveDatabaseFile();
    final tempDirectory = await getTemporaryDirectory();
    sqlite3.sqlite3.tempDirectory = tempDirectory.path;
    return NativeDatabase.createInBackground(file);
  });
}
