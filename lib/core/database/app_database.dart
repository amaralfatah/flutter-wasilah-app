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
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await customStatement('''
        CREATE TABLE assets (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          code TEXT NOT NULL,
          category TEXT NOT NULL,
          current_value REAL NOT NULL,
          allocation_percentage REAL NOT NULL,
          last_updated_at INTEGER NOT NULL
        );
      ''');

      await customStatement('''
        CREATE TABLE asset_snapshots (
          id TEXT PRIMARY KEY NOT NULL,
          asset_id TEXT NOT NULL,
          total_value REAL NOT NULL,
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
  );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'wasilah.sqlite'));
    final tempDirectory = await getTemporaryDirectory();
    sqlite3.sqlite3.tempDirectory = tempDirectory.path;
    return NativeDatabase.createInBackground(file);
  });
}
