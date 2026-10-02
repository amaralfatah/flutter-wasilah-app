import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/core/database/database_file_recovery.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  late Directory directory;
  late File databaseFile;
  late File safetyCopy;
  late File marker;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('wasilah_recovery_');
    databaseFile = File(p.join(directory.path, databaseFileName));
    safetyCopy = databaseSafetyCopyFile(databaseFile);
    marker = restoreMarkerFile(databaseFile);
  });

  tearDown(() => directory.deleteSync(recursive: true));

  group('recoverInterruptedRestore', () {
    test('restores the safety copy when the main file is missing', () async {
      safetyCopy.writeAsStringSync('old');

      await recoverInterruptedRestore(databaseFile);

      expect(databaseFile.readAsStringSync(), 'old');
      expect(safetyCopy.existsSync(), isFalse);
    });

    test('rolls back an unverified restore left by a killed process', () async {
      databaseFile.writeAsStringSync('restored-unverified');
      safetyCopy.writeAsStringSync('old');
      marker.writeAsStringSync('another-process');

      await recoverInterruptedRestore(databaseFile);

      expect(databaseFile.readAsStringSync(), 'old');
      expect(safetyCopy.existsSync(), isFalse);
      expect(marker.existsSync(), isFalse);
    });

    test('leaves a restore running in this process alone', () async {
      databaseFile.writeAsStringSync('restored');
      safetyCopy.writeAsStringSync('old');
      await beginRestoreSwap(databaseFile);

      await recoverInterruptedRestore(databaseFile);

      expect(databaseFile.readAsStringSync(), 'restored');
      expect(safetyCopy.existsSync(), isTrue);
      expect(marker.existsSync(), isTrue);

      await endRestoreSwap(databaseFile);
      expect(marker.existsSync(), isFalse);
    });

    test('keeps a committed database and its stale safety copy', () async {
      databaseFile.writeAsStringSync('current');
      safetyCopy.writeAsStringSync('stale');

      await recoverInterruptedRestore(databaseFile);

      expect(databaseFile.readAsStringSync(), 'current');
    });
  });

  group('openConnection', () {
    late PathProviderPlatform previousPathProvider;

    setUp(() {
      previousPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _FakePathProvider(directory.path);
    });

    tearDown(() => PathProviderPlatform.instance = previousPathProvider);

    test('reopens the old data after a crash mid-restore', () async {
      final raw = sqlite3.sqlite3.open(safetyCopy.path);
      try {
        raw.execute('''
          CREATE TABLE allocation_targets (
            id TEXT PRIMARY KEY NOT NULL,
            category TEXT NOT NULL,
            target_percentage REAL NOT NULL
          );
          INSERT INTO allocation_targets VALUES ('local', 'saham', 50);
          PRAGMA user_version = $appDatabaseSchemaVersion;
        ''');
      } finally {
        raw.dispose();
      }
      marker.writeAsStringSync('another-process');

      final database = AppDatabase();
      addTearDown(database.close);
      final rows = await database
          .customSelect('SELECT id FROM allocation_targets')
          .get();

      expect(rows.map((row) => row.read<String>('id')), ['local']);
      expect(marker.existsSync(), isFalse);
    });
  });
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this._path);

  final String _path;

  @override
  Future<String?> getTemporaryPath() async => _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;
}
