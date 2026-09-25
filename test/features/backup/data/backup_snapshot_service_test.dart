import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/features/backup/data/backup_snapshot.dart';

void main() {
  group('BackupSnapshotService', () {
    late Directory tempDirectory;
    const service = BackupSnapshotService();

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'wasilah_snapshot_test_',
      );
    });

    tearDown(() async {
      await tempDirectory.delete(recursive: true);
    });

    test('createSnapshot produces a valid standalone sqlite file', () async {
      final databaseFile = File('${tempDirectory.path}/wasilah.sqlite');
      final database = AppDatabase.forTesting(
        NativeDatabase.createInBackground(databaseFile),
      );
      addTearDown(database.close);
      await database.customStatement(
        'INSERT INTO assets (id, name, code, category) '
        "VALUES ('btc', 'Bitcoin', 'BTC', 'crypto')",
      );

      final snapshotFile = await service.createSnapshot(database);
      addTearDown(() {
        if (snapshotFile.existsSync()) {
          snapshotFile.deleteSync();
        }
      });

      expect(snapshotFile.existsSync(), isTrue);
      expect(service.isValidSqliteFile(snapshotFile), isTrue);
    });

    test('isValidSqliteFile rejects a non-sqlite file', () async {
      final garbageFile = File('${tempDirectory.path}/garbage.sqlite');
      await garbageFile.writeAsString('not a sqlite database');

      expect(service.isValidSqliteFile(garbageFile), isFalse);
    });

    test('isValidSqliteFile rejects a missing file', () {
      final missingFile = File('${tempDirectory.path}/missing.sqlite');

      expect(service.isValidSqliteFile(missingFile), isFalse);
    });

    test('readSchemaVersion returns the database user_version', () async {
      final databaseFile = File('${tempDirectory.path}/wasilah.sqlite');
      final database = AppDatabase.forTesting(
        NativeDatabase.createInBackground(databaseFile),
      );
      addTearDown(database.close);
      // Sentuh koneksi supaya migration (yang men-set user_version) jalan.
      await database.customSelect('PRAGMA user_version').get();

      final snapshotFile = await service.createSnapshot(database);
      addTearDown(() {
        if (snapshotFile.existsSync()) {
          snapshotFile.deleteSync();
        }
      });

      expect(service.readSchemaVersion(snapshotFile), appDatabaseSchemaVersion);
    });

    test('readSchemaVersion returns null for a non-sqlite file', () async {
      final garbageFile = File('${tempDirectory.path}/garbage.sqlite');
      await garbageFile.writeAsString('not a sqlite database');

      expect(service.readSchemaVersion(garbageFile), isNull);
    });
  });
}
