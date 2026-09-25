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
  int get schemaVersion => 8;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      // Master aset: identitas & atribut yang diubah lewat form edit aset.
      // Nilai portofolio (current_value, total_cost, quantity, dst) hidup di
      // tabel `holdings`, terpisah dari master.
      await customStatement('''
        CREATE TABLE assets (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          code TEXT NOT NULL,
          category TEXT NOT NULL,
          market_symbol TEXT
        );
      ''');

      // Holding portofolio satu aset: nilai terkini, modal, jumlah unit, dan
      // kapan terakhir diupdate. RESTRICT: aset dengan holding tidak bisa
      // dihapus sebelum dikeluarkan dari portofolio (lihat juga pengecekan
      // level-aplikasi di DriftAssetRepository.deleteAsset).
      await customStatement('''
        CREATE TABLE holdings (
          asset_id TEXT PRIMARY KEY NOT NULL REFERENCES assets(id) ON DELETE RESTRICT,
          current_value REAL NOT NULL,
          total_cost REAL,
          quantity REAL,
          avg_buy_price REAL,
          price_currency TEXT,
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

      // Histori bulanan per aset (dulu juga menampung baris sentinel
      // `asset_id = 'portfolio'`; kini histori portofolio punya tabel
      // sendiri, lihat `portfolio_snapshots`).
      await customStatement('''
        CREATE TABLE asset_snapshots (
          id TEXT PRIMARY KEY NOT NULL,
          asset_id TEXT NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
          total_value REAL NOT NULL,
          recorded_at INTEGER NOT NULL,
          note TEXT,
          total_cost REAL
        );
      ''');

      // Histori bulanan gabungan portofolio.
      await customStatement('''
        CREATE TABLE portfolio_snapshots (
          id TEXT PRIMARY KEY NOT NULL,
          total_value REAL NOT NULL,
          total_cost REAL,
          recorded_at INTEGER NOT NULL,
          note TEXT
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
      if (from < 8) {
        // Kolom sumber disalin apa adanya; pastikan ada walau database
        // lama sempat melewatkan salah satu langkah upgrade di atas.
        for (final column in const [
          ('total_cost', 'REAL'),
          ('market_symbol', 'TEXT'),
          ('quantity', 'REAL'),
          ('avg_buy_price', 'REAL'),
          ('price_currency', 'TEXT'),
        ]) {
          await _addColumnIfMissing('assets', column.$1, column.$2);
        }
        await _addColumnIfMissing('asset_snapshots', 'total_cost', 'REAL');

        // 1) holdings = potongan porto dari `assets` lama, satu baris per
        // aset yang ada (semua aset lama selalu punya current_value).
        await customStatement('''
          CREATE TABLE holdings (
            asset_id TEXT PRIMARY KEY NOT NULL REFERENCES assets(id) ON DELETE RESTRICT,
            current_value REAL NOT NULL,
            total_cost REAL,
            quantity REAL,
            avg_buy_price REAL,
            price_currency TEXT,
            last_updated_at INTEGER NOT NULL
          );
        ''');
        await customStatement('''
          INSERT INTO holdings (
            asset_id, current_value, total_cost, quantity, avg_buy_price, price_currency, last_updated_at
          )
          SELECT id, current_value, total_cost, quantity, avg_buy_price, price_currency, last_updated_at
          FROM assets;
        ''');

        // 2) portfolio_snapshots = baris sentinel `asset_id = 'portfolio'`
        // yang dulu numpang di asset_snapshots, dipindah ke tabel sendiri.
        await customStatement('''
          CREATE TABLE portfolio_snapshots (
            id TEXT PRIMARY KEY NOT NULL,
            total_value REAL NOT NULL,
            total_cost REAL,
            recorded_at INTEGER NOT NULL,
            note TEXT
          );
        ''');
        await customStatement('''
          INSERT INTO portfolio_snapshots (id, total_value, total_cost, recorded_at, note)
          SELECT id, total_value, total_cost, recorded_at, note
          FROM asset_snapshots
          WHERE asset_id = 'portfolio';
        ''');
        await customStatement('''
          DELETE FROM asset_snapshots WHERE asset_id = 'portfolio';
        ''');

        // 3) assets dirampingkan jadi master data murni. Direkonstruksi via
        // tabel baru + salin + drop + rename, bukan `DROP COLUMN`, supaya
        // tidak bergantung pada versi sqlite3 yang mendukungnya.
        await customStatement('''
          CREATE TABLE assets_new (
            id TEXT PRIMARY KEY NOT NULL,
            name TEXT NOT NULL,
            code TEXT NOT NULL,
            category TEXT NOT NULL,
            market_symbol TEXT
          );
        ''');
        await customStatement('''
          INSERT INTO assets_new (id, name, code, category, market_symbol)
          SELECT id, name, code, category, market_symbol FROM assets;
        ''');
        await customStatement('DROP TABLE assets;');
        await customStatement('ALTER TABLE assets_new RENAME TO assets;');

        // Index milik `asset_snapshots` tidak tersentuh rebuild `assets`,
        // tapi dipastikan ada untuk database yang sempat kehilangannya.
        await customStatement('''
          CREATE INDEX IF NOT EXISTS asset_snapshots_asset_recorded_idx
          ON asset_snapshots (asset_id, recorded_at DESC);
        ''');
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
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
