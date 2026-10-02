import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/core/database/database_file_recovery.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/core/errors/error_reporter.dart';
import 'package:flutter_wasilah_app/core/storage/preferences_service.dart';
import 'package:flutter_wasilah_app/features/backup/data/backup_snapshot.dart';
import 'package:flutter_wasilah_app/features/backup/data/google_auth_service.dart';
import 'package:flutter_wasilah_app/features/backup/providers/backup_controller.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  group('BackupController auto backup failures', () {
    Future<(ProviderContainer, _RecordingReporter)> createContainer(
      Future<http.Client?> Function() authorize,
    ) async {
      SharedPreferences.setMockInitialValues({
        'backup_account_connected': true,
        'auto_backup_enabled': true,
      });
      final preferences = await SharedPreferences.getInstance();
      final reporter = _RecordingReporter();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          googleAuthServiceProvider.overrideWithValue(_FakeAuth(authorize)),
          errorReporterProvider.overrideWithValue(reporter),
          backupSnapshotServiceProvider.overrideWithValue(
            const _FakeSnapshotService(),
          ),
          appDatabaseProvider.overrideWith((ref) {
            final database = AppDatabase.forTesting(NativeDatabase.memory());
            ref.onDispose(database.close);
            return database;
          }),
          backupRetryDelayProvider.overrideWithValue(Duration.zero),
        ],
      );
      addTearDown(container.dispose);
      return (container, reporter);
    }

    test('an unexpected failure is reported and shown', () async {
      final (container, reporter) = await createContainer(
        () => throw Exception('network down'),
      );

      await container.read(backupControllerProvider.notifier).maybeAutoBackup();

      final state = container.read(backupControllerProvider);
      expect(state.isBackingUp, isFalse);
      expect(state.error, isA<AutoBackupFailedException>());
      expect(reporter.reasons, ['Auto backup failed']);
    });

    test('missing Drive authorization is shown and reported apart', () async {
      final (container, reporter) = await createContainer(() async => null);

      await container.read(backupControllerProvider.notifier).maybeAutoBackup();

      final state = container.read(backupControllerProvider);
      expect(state.error, isA<GoogleAuthorizationRequiredException>());
      expect(reporter.reasons, ['Drive authorization required']);
    });

    test('a failed cleanup after upload still counts as backed up', () async {
      final (container, reporter) = await createContainer(
        () async => MockClient((request) async {
          if (request.url.path.startsWith('/upload/')) {
            return _uploadedResponse();
          }
          return http.Response('boom', 500);
        }),
      );

      await container.read(backupControllerProvider.notifier).maybeAutoBackup();

      final state = container.read(backupControllerProvider);
      expect(state.isBackingUp, isFalse);
      expect(state.error, isNull);
      expect(state.lastBackupAt, isNotNull);
      expect(reporter.reasons, ['Backup cleanup failed']);
    });

    test('a transient network failure is retried once', () async {
      var uploads = 0;
      final (container, reporter) = await createContainer(
        () async => MockClient((request) async {
          if (request.url.path.startsWith('/upload/')) {
            uploads++;
            if (uploads == 1) {
              throw http.ClientException('connection reset');
            }
            return _uploadedResponse();
          }
          return http.Response(
            jsonEncode({'files': <Object>[]}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await container.read(backupControllerProvider.notifier).maybeAutoBackup();

      final state = container.read(backupControllerProvider);
      expect(uploads, 2);
      expect(state.error, isNull);
      expect(state.lastBackupAt, isNotNull);
      expect(reporter.reasons, isEmpty);
    });
  });

  group('BackupController restore', () {
    late Directory directory;
    late File databaseFile;
    late PathProviderPlatform previousPathProvider;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('wasilah_restore_');
      databaseFile = File(p.join(directory.path, databaseFileName));
      previousPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _FakePathProvider(directory.path);
    });

    tearDown(() {
      PathProviderPlatform.instance = previousPathProvider;
      directory.deleteSync(recursive: true);
    });

    /// Database berskema lengkap berisi satu target alokasi bertanda [id].
    Future<void> writeDatabase(File file, String id) async {
      final database = AppDatabase.forTesting(NativeDatabase(file));
      await database.customStatement(
        "INSERT INTO allocation_targets VALUES ('$id', 'saham', 50)",
      );
      await database.close();
    }

    Future<List<int>> remoteBytes(String id) async {
      final file = File(p.join(directory.path, 'remote_source.sqlite'));
      await writeDatabase(file, id);
      final bytes = file.readAsBytesSync();
      file.deleteSync();
      return bytes;
    }

    Future<ProviderContainer> createContainer(
      List<int> remote, {
      BackupSnapshotService snapshotService = const BackupSnapshotService(),
    }) async {
      SharedPreferences.setMockInitialValues({
        'backup_account_connected': true,
      });
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          googleAuthServiceProvider.overrideWithValue(
            _FakeAuth(
              () async => MockClient(
                (request) async => http.Response.bytes(
                  remote,
                  200,
                  headers: {'content-type': 'application/octet-stream'},
                ),
              ),
            ),
          ),
          errorReporterProvider.overrideWithValue(_RecordingReporter()),
          backupSnapshotServiceProvider.overrideWithValue(snapshotService),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    Future<List<String>> readIds(ProviderContainer container) async {
      final rows = await container
          .read(appDatabaseProvider)
          .customSelect('SELECT id FROM allocation_targets')
          .get();
      return rows.map((row) => row.read<String>('id')).toList();
    }

    List<String> leftovers() => directory
        .listSync()
        .map((entity) => p.basename(entity.path))
        .where((name) => name != databaseFileName)
        .toList();

    test('swaps in the downloaded database', () async {
      await writeDatabase(databaseFile, 'local');
      final container = await createContainer(await remoteBytes('remote'));
      expect(await readIds(container), ['local']);

      await container.read(backupControllerProvider.notifier).restore('id');

      expect(await readIds(container), ['remote']);
      expect(container.read(backupControllerProvider).isRestoring, isFalse);
      expect(leftovers(), isEmpty);
    });

    test('a failed file swap rolls back and reopens the database', () async {
      await writeDatabase(databaseFile, 'local');
      final container = await createContainer(
        await remoteBytes('remote'),
        snapshotService: const _VanishingDownloadSnapshotService(),
      );
      final closedDatabase = container.read(appDatabaseProvider);
      expect(await readIds(container), ['local']);

      await expectLater(
        container.read(backupControllerProvider.notifier).restore('id'),
        throwsA(isA<FileSystemException>()),
      );

      expect(container.read(appDatabaseProvider), isNot(closedDatabase));
      expect(await readIds(container), ['local']);
      expect(leftovers(), isEmpty);
    });

    test('a restore that fails to open is rolled back', () async {
      await writeDatabase(databaseFile, 'local');
      // Lolos integrity check dan versinya didukung, tapi migrasinya gagal
      // karena tabelnya tidak ada.
      final source = File(p.join(directory.path, 'broken_source.sqlite'));
      final raw = sqlite3.sqlite3.open(source.path);
      try {
        raw.execute('CREATE TABLE junk (x); PRAGMA user_version = 9;');
      } finally {
        raw.dispose();
      }
      final broken = source.readAsBytesSync();
      source.deleteSync();
      final container = await createContainer(broken);

      await expectLater(
        container.read(backupControllerProvider.notifier).restore('id'),
        throwsA(isA<RestoreVerificationFailedException>()),
      );

      expect(await readIds(container), ['local']);
      expect(restoreMarkerFile(databaseFile).existsSync(), isFalse);
      expect(leftovers(), isEmpty);
    });
  });

  group('BackupController disconnect', () {
    test('clears the local connection even when offline', () async {
      SharedPreferences.setMockInitialValues({
        'backup_account_connected': true,
        'backup_account_email': 'me@example.com',
      });
      final preferences = await SharedPreferences.getInstance();
      final reporter = _RecordingReporter();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          googleAuthServiceProvider.overrideWithValue(
            _FakeAuth(
              () async => null,
              disconnect: () => throw const SocketException('offline'),
            ),
          ),
          errorReporterProvider.overrideWithValue(reporter),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(backupControllerProvider).isConnected, isTrue);

      await container.read(backupControllerProvider.notifier).disconnect();

      final state = container.read(backupControllerProvider);
      final service = container.read(preferencesServiceProvider);
      expect(state.isConnected, isFalse);
      expect(state.accountEmail, isNull);
      expect(service.readBackupConnected(), isFalse);
      expect(service.readBackupAccountEmail(), isNull);
      expect(reporter.reasons, ['Google disconnect failed']);
    });
  });

  group('isTransientNetworkError', () {
    test('accepts connection and timeout errors', () {
      expect(isTransientNetworkError(const SocketException('x')), isTrue);
      expect(isTransientNetworkError(http.ClientException('x')), isTrue);
    });

    test('rejects auth and logic errors', () {
      expect(
        isTransientNetworkError(const GoogleAuthorizationRequiredException()),
        isFalse,
      );
      expect(
        isTransientNetworkError(const InvalidSnapshotException()),
        isFalse,
      );
    });
  });

  group('isBackupStale', () {
    final now = DateTime(2026, 9, 25);

    test('is false without any backup yet', () {
      expect(isBackupStale(now: now, lastBackupAt: null), isFalse);
    });

    test('is false within 7 days', () {
      expect(
        isBackupStale(now: now, lastBackupAt: DateTime(2026, 9, 18)),
        isFalse,
      );
    });

    test('is true after more than 7 days', () {
      expect(
        isBackupStale(now: now, lastBackupAt: DateTime(2026, 9, 17)),
        isTrue,
      );
    });
  });

  group('shouldAutoBackup', () {
    const interval = Duration(hours: 24);

    test('returns true when there is no previous backup', () {
      final result = shouldAutoBackup(
        now: DateTime(2026, 7, 18, 9),
        lastBackupAt: null,
        interval: interval,
      );

      expect(result, isTrue);
    });

    test('returns false when the last backup was under 24 hours ago', () {
      final result = shouldAutoBackup(
        now: DateTime(2026, 7, 18, 9),
        lastBackupAt: DateTime(2026, 7, 17, 12),
        interval: interval,
      );

      expect(result, isFalse);
    });

    test('returns true when the last backup was 24+ hours ago', () {
      final result = shouldAutoBackup(
        now: DateTime(2026, 7, 18, 9),
        lastBackupAt: DateTime(2026, 7, 17, 8),
        interval: interval,
      );

      expect(result, isTrue);
    });
  });

  group('shouldAttemptAutoBackup', () {
    const interval = Duration(hours: 24);
    const cooldown = Duration(hours: 1);

    test('returns true on the first attempt when a backup is due', () {
      final result = shouldAttemptAutoBackup(
        now: DateTime(2026, 7, 18, 9),
        lastBackupAt: null,
        lastAttemptAt: null,
        interval: interval,
        retryCooldown: cooldown,
      );

      expect(result, isTrue);
    });

    test('returns false while the retry cooldown is still active', () {
      final result = shouldAttemptAutoBackup(
        now: DateTime(2026, 7, 18, 9),
        lastBackupAt: null,
        lastAttemptAt: DateTime(2026, 7, 18, 8, 30),
        interval: interval,
        retryCooldown: cooldown,
      );

      expect(result, isFalse);
    });

    test('returns true again once the retry cooldown has elapsed', () {
      final result = shouldAttemptAutoBackup(
        now: DateTime(2026, 7, 18, 9),
        lastBackupAt: null,
        lastAttemptAt: DateTime(2026, 7, 18, 7, 30),
        interval: interval,
        retryCooldown: cooldown,
      );

      expect(result, isTrue);
    });

    test('still respects the backup interval after the cooldown', () {
      final result = shouldAttemptAutoBackup(
        now: DateTime(2026, 7, 18, 9),
        lastBackupAt: DateTime(2026, 7, 18, 6),
        lastAttemptAt: DateTime(2026, 7, 18, 6),
        interval: interval,
        retryCooldown: cooldown,
      );

      expect(result, isFalse);
    });
  });
}

class _FakeAuth extends GoogleAuthService {
  _FakeAuth(this._authorize, {Future<void> Function()? disconnect})
    : _disconnect = disconnect;

  final Future<http.Client?> Function() _authorize;
  final Future<void> Function()? _disconnect;

  @override
  Future<void> disconnect() => _disconnect?.call() ?? Future<void>.value();

  @override
  Future<void> ensureInitialized() async {}

  @override
  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      const Stream.empty();

  @override
  Future<http.Client?> authenticatedHttpClient({
    GoogleSignInAccount? account,
    bool promptIfNecessary = false,
  }) => _authorize();
}

class _RecordingReporter extends ErrorReporter {
  final reasons = <String>[];

  @override
  void report(Object error, StackTrace stackTrace, {required String reason}) {
    reasons.add(reason);
  }
}

http.Response _uploadedResponse() => http.Response(
  jsonEncode({
    'id': 'new',
    'name': 'backup.sqlite',
    'createdTime': '2026-10-02T00:00:00Z',
    'size': '4',
  }),
  200,
  headers: {'content-type': 'application/json'},
);

class _FakeSnapshotService extends BackupSnapshotService {
  const _FakeSnapshotService();

  @override
  Future<File> createSnapshot(AppDatabase database) async {
    final directory = Directory.systemTemp.createTempSync('wasilah_test_');
    return File('${directory.path}/backup.sqlite')..writeAsStringSync('data');
  }

  @override
  bool isValidSqliteFile(File file) => true;
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this._path);

  final String _path;

  @override
  Future<String?> getTemporaryPath() async => _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;
}

/// File unduhan lenyap tepat sebelum ditukar, sehingga pemindahannya ke
/// lokasi database gagal setelah database lama sudah dipindah ke `.bak`.
class _VanishingDownloadSnapshotService extends BackupSnapshotService {
  const _VanishingDownloadSnapshotService();

  @override
  int? readSchemaVersion(File file) {
    final version = super.readSchemaVersion(file);
    file.deleteSync();
    return version;
  }
}
