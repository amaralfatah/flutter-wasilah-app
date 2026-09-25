import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Versi skema saat ini. Dipisah dari [AppDatabase.schemaVersion] supaya bisa
/// dibaca (mis. untuk validasi file backup) tanpa membuka koneksi database.
const int appDatabaseSchemaVersion = 11;

/// Versi skema tertua yang masih bisa di-upgrade (dan di-restore dari
/// backup).
const int minSupportedSchemaVersion = 8;

/// Nama tabel semu untuk notifikasi perubahan data aset/portofolio.
const _portfolioDataTable = 'portfolio_data';

class AppDatabase extends GeneratedDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => appDatabaseSchemaVersion;

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

      // Histori bulanan per aset.
      await customStatement('''
        CREATE TABLE asset_snapshots (
          id TEXT PRIMARY KEY NOT NULL,
          asset_id TEXT NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
          total_value REAL NOT NULL,
          recorded_at INTEGER NOT NULL,
          note TEXT,
          total_cost REAL,
          fx_currency TEXT,
          fx_rate REAL
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
      await _createIndexesV11();
    },
    // Satu transaksi: migrasi yang gagal di tengah jalan tidak meninggalkan
    // skema setengah jadi yang akan dicoba ulang dari awal.
    onUpgrade: (migrator, from, to) => transaction(() async {
      // Langkah migrasi di bawah [minSupportedSchemaVersion] sudah dipangkas:
      // satu-satunya database yang dipakai sudah melewatinya.
      if (from < minSupportedSchemaVersion) {
        throw StateError('Skema database v$from tidak didukung lagi.');
      }
      if (from < 9) {
        // Nominal rupiah kini disimpan bulat; quantity & avg_buy_price
        // (harga per unit, bisa dalam USD) sengaja tidak dibulatkan.
        await customStatement('''
          UPDATE holdings
          SET current_value = ROUND(current_value), total_cost = ROUND(total_cost);
        ''');
        await customStatement('''
          UPDATE asset_snapshots
          SET total_value = ROUND(total_value), total_cost = ROUND(total_cost);
        ''');
        await customStatement('''
          UPDATE portfolio_snapshots
          SET total_value = ROUND(total_value), total_cost = ROUND(total_cost);
        ''');
      }
      if (from < 10) {
        await _addColumnIfMissing('asset_snapshots', 'fx_currency', 'TEXT');
        await _addColumnIfMissing('asset_snapshots', 'fx_rate', 'REAL');
      }
      if (from < 11) {
        // Satu target per kategori: sisakan baris terbaru sebelum dikunci
        // indeks UNIQUE.
        await customStatement('''
          DELETE FROM allocation_targets
          WHERE rowid NOT IN (
            SELECT MAX(rowid) FROM allocation_targets GROUP BY category
          );
        ''');
        await _createIndexesV11();
      }
    }),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Tulis data aset/portofolio dalam satu transaksi lalu kabari
  /// [portfolioChanges]. SQL mentah (`customStatement`) tidak memicu
  /// notifikasi stream drift, jadi semua tulis wajib lewat sini.
  Future<T> writePortfolio<T>(Future<T> Function() action) async {
    final result = await transaction(action);
    notifyUpdates({const TableUpdate(_portfolioDataTable)});
    return result;
  }

  /// Berbunyi setiap kali [writePortfolio] selesai.
  Stream<void> get portfolioChanges => tableUpdates(
    const TableUpdateQuery.onTableName(_portfolioDataTable),
  ).map((_) {});

  Future<void> _createIndexesV11() async {
    await customStatement('''
      CREATE INDEX IF NOT EXISTS portfolio_snapshots_recorded_idx
      ON portfolio_snapshots (recorded_at);
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS allocation_targets_category_idx
      ON allocation_targets (category);
    ''');
  }

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
