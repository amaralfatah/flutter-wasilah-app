# Google Drive Backup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users connect their Google account and back up/restore the local Wasilah portfolio database to their own Google Drive App Data Folder, with an automatic once-per-24h backup and manual backup/restore controls in Settings.

**Architecture:** New `lib/features/backup/` feature following the existing feature-folder pattern (`data/`, `providers/`, `presentation/`). A `BackupSnapshotService` creates a consistent SQLite snapshot via `VACUUM INTO`. A `GoogleAuthService` wraps `google_sign_in` v7 (scope `drive.appdata` only). A `DriveBackupService` wraps `googleapis` Drive v3 (`spaces=appDataFolder`) for upload/list/delete/download, with pure helper functions (`backupIdsToDelete`, `shouldAutoBackup`) kept separate so they're unit-testable without hitting the network. A `BackupController` (plain `Notifier`, mirroring `ThemeModeController`) owns connection/backup state and is surfaced through a `BackupSection` widget in Settings and a `RestorePage`.

**Tech Stack:** Flutter/Dart, Riverpod (`Notifier`), `google_sign_in` ^7.x, `googleapis` (Drive v3), `http`, Drift/sqlite3 (existing), `shared_preferences` (existing).

**Reference spec:** `docs/superpowers/specs/2026-07-18-google-drive-backup-design.md`

---

### Task 1: Add dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add packages with `flutter pub add`**

Run from `flutter_wasilah_app/`:

```bash
flutter pub add google_sign_in googleapis http
```

This resolves and pins the latest compatible versions automatically (avoids hand-guessing version numbers).

- [ ] **Step 2: Verify pubspec.yaml was updated**

Open `pubspec.yaml` and confirm `google_sign_in`, `googleapis`, and `http` now appear under `dependencies:`.

- [ ] **Step 3: Run pub get and verify it resolves cleanly**

Run: `flutter pub get`
Expected: `Got dependencies!` with no version conflicts.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add google_sign_in, googleapis, http dependencies"
```

---

### Task 2: Backup preferences (last backup time, auto-backup toggle)

**Files:**
- Modify: `lib/core/storage/preferences_service.dart`
- Test: `test/core/storage/preferences_service_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/storage/preferences_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/storage/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesService backup preferences', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to no last backup time and auto backup enabled', () async {
      final preferences = SharedPreferencesService(
        await SharedPreferences.getInstance(),
      );

      expect(preferences.readLastBackupAt(), isNull);
      expect(preferences.readAutoBackupEnabled(), isTrue);
    });

    test('persists last backup time and auto backup toggle', () async {
      final preferences = SharedPreferencesService(
        await SharedPreferences.getInstance(),
      );
      final backupTime = DateTime(2026, 7, 18, 9, 30);

      await preferences.writeLastBackupAt(backupTime);
      await preferences.writeAutoBackupEnabled(false);

      expect(preferences.readLastBackupAt(), backupTime);
      expect(preferences.readAutoBackupEnabled(), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/storage/preferences_service_test.dart`
Expected: FAIL — `readLastBackupAt` / `writeLastBackupAt` / `readAutoBackupEnabled` / `writeAutoBackupEnabled` are not defined on `PreferencesService`.

- [ ] **Step 3: Implement the preference methods**

Replace the contents of `lib/core/storage/preferences_service.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PreferencesService {
  ThemeMode readThemeMode();

  Future<void> writeThemeMode(ThemeMode mode);

  DateTime? readLastBackupAt();

  Future<void> writeLastBackupAt(DateTime value);

  bool readAutoBackupEnabled();

  Future<void> writeAutoBackupEnabled(bool enabled);
}

class SharedPreferencesService implements PreferencesService {
  SharedPreferencesService(this._preferences);

  static const _themeModeKey = 'theme_mode';
  static const _lastBackupAtKey = 'last_backup_at_millis';
  static const _autoBackupEnabledKey = 'auto_backup_enabled';

  final SharedPreferences _preferences;

  @override
  ThemeMode readThemeMode() {
    final rawValue = _preferences.getString(_themeModeKey);
    return switch (rawValue) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  Future<void> writeThemeMode(ThemeMode mode) {
    return _preferences.setString(_themeModeKey, mode.name);
  }

  @override
  DateTime? readLastBackupAt() {
    final millis = _preferences.getInt(_lastBackupAtKey);
    if (millis == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  Future<void> writeLastBackupAt(DateTime value) {
    return _preferences.setInt(
      _lastBackupAtKey,
      value.millisecondsSinceEpoch,
    );
  }

  @override
  bool readAutoBackupEnabled() {
    return _preferences.getBool(_autoBackupEnabledKey) ?? true;
  }

  @override
  Future<void> writeAutoBackupEnabled(bool enabled) {
    return _preferences.setBool(_autoBackupEnabledKey, enabled);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences belum diinisialisasi.');
});

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return SharedPreferencesService(ref.watch(sharedPreferencesProvider));
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/storage/preferences_service_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/core/storage/preferences_service.dart test/core/storage/preferences_service_test.dart
git commit -m "feat: add backup preferences to PreferencesService"
```

---

### Task 3: Extract shared database file path resolution

**Why:** Restore needs to close the live DB, replace the file on disk, and reopen it. Today the file path (`wasilah.sqlite` in the app documents directory) is only known inside `openConnection()`. Extract it so restore code can reuse the exact same path.

**Files:**
- Modify: `lib/core/database/app_database.dart`

- [ ] **Step 1: Extract `databaseFileName` and `resolveDatabaseFile()`**

In `lib/core/database/app_database.dart`, replace the `openConnection()` function at the bottom of the file with:

```dart
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
```

No other lines in the file change.

- [ ] **Step 2: Run the existing database test to confirm nothing broke**

Run: `flutter test test/core/database/app_database_test.dart`
Expected: PASS (uses `AppDatabase.forTesting`, unaffected by this refactor)

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze lib/core/database/app_database.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/core/database/app_database.dart
git commit -m "refactor: extract resolveDatabaseFile for reuse by restore flow"
```

---

### Task 4: Backup snapshot service (VACUUM INTO + SQLite validation)

**Files:**
- Create: `lib/features/backup/data/backup_snapshot.dart`
- Test: `test/features/backup/data/backup_snapshot_service_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/backup/data/backup_snapshot_service_test.dart`:

```dart
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
        "INSERT INTO assets (id, name, code, category, current_value, "
        "allocation_percentage, last_updated_at) "
        "VALUES ('btc', 'Bitcoin', 'BTC', 'crypto', 100, 100, 0)",
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
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/backup/data/backup_snapshot_service_test.dart`
Expected: FAIL — cannot find `package:flutter_wasilah_app/features/backup/data/backup_snapshot.dart`

- [ ] **Step 3: Implement BackupSnapshotService**

Create `lib/features/backup/data/backup_snapshot.dart`:

```dart
import 'dart:io';

import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

class BackupSnapshotService {
  const BackupSnapshotService();

  Future<File> createSnapshot(AppDatabase database) async {
    final tempDir = await getTemporaryDirectory();
    final snapshotPath = p.join(
      tempDir.path,
      'wasilah_backup_${DateTime.now().millisecondsSinceEpoch}.sqlite',
    );
    final snapshotFile = File(snapshotPath);
    if (snapshotFile.existsSync()) {
      await snapshotFile.delete();
    }

    final escapedPath = snapshotPath.replaceAll("'", "''");
    await database.customStatement("VACUUM INTO '$escapedPath'");

    return snapshotFile;
  }

  bool isValidSqliteFile(File file) {
    if (!file.existsSync() || file.lengthSync() == 0) {
      return false;
    }

    sqlite3.Database? database;
    try {
      database = sqlite3.sqlite3.open(
        file.path,
        mode: sqlite3.OpenMode.readOnly,
      );
      final result = database.select('PRAGMA integrity_check');
      return result.isNotEmpty && result.first.values.first == 'ok';
    } catch (_) {
      return false;
    } finally {
      database?.dispose();
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/backup/data/backup_snapshot_service_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/backup/data/backup_snapshot.dart test/features/backup/data/backup_snapshot_service_test.dart
git commit -m "feat: add BackupSnapshotService for VACUUM INTO snapshots"
```

---

### Task 5: Drive backup service (upload/list/delete/download + prune logic)

**Files:**
- Create: `lib/features/backup/data/drive_backup_service.dart`
- Test: `test/features/backup/data/drive_backup_service_test.dart`

- [ ] **Step 1: Write the failing test for the prune selection logic**

`backupIdsToDelete` is a pure function so it can be tested without any network or `DriveApi` involved.

Create `test/features/backup/data/drive_backup_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/backup/data/drive_backup_service.dart';

void main() {
  group('backupIdsToDelete', () {
    test('keeps the newest N backups and returns the rest for deletion', () {
      final backups = [
        DriveBackupFile(
          id: 'oldest',
          name: 'a',
          createdAt: DateTime(2026, 1, 1),
          sizeBytes: 10,
        ),
        DriveBackupFile(
          id: 'newest',
          name: 'b',
          createdAt: DateTime(2026, 3, 1),
          sizeBytes: 10,
        ),
        DriveBackupFile(
          id: 'middle',
          name: 'c',
          createdAt: DateTime(2026, 2, 1),
          sizeBytes: 10,
        ),
      ];

      final idsToDelete = backupIdsToDelete(backups, keep: 2);

      expect(idsToDelete, ['oldest']);
    });

    test('returns nothing to delete when within the keep limit', () {
      final backups = [
        DriveBackupFile(
          id: 'only',
          name: 'a',
          createdAt: DateTime(2026, 1, 1),
          sizeBytes: 10,
        ),
      ];

      expect(backupIdsToDelete(backups, keep: 7), isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/backup/data/drive_backup_service_test.dart`
Expected: FAIL — cannot find `package:flutter_wasilah_app/features/backup/data/drive_backup_service.dart`

- [ ] **Step 3: Implement DriveBackupService**

Create `lib/features/backup/data/drive_backup_service.dart`:

```dart
import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;

class DriveBackupFile {
  const DriveBackupFile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.sizeBytes,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final int sizeBytes;
}

class DriveBackupService {
  DriveBackupService(this._driveApi);

  static const int maxBackupsToKeep = 7;
  static const String _fileFields = 'id,name,createdTime,size';

  final drive.DriveApi _driveApi;

  Future<DriveBackupFile> upload(File snapshotFile) async {
    final metadata = drive.File()
      ..name = p.basename(snapshotFile.path)
      ..parents = ['appDataFolder'];
    final media = drive.Media(
      snapshotFile.openRead(),
      snapshotFile.lengthSync(),
    );

    final created = await _driveApi.files.create(
      metadata,
      uploadMedia: media,
      $fields: _fileFields,
    );

    return _toBackupFile(created);
  }

  Future<List<DriveBackupFile>> listBackups() async {
    final result = await _driveApi.files.list(
      spaces: 'appDataFolder',
      orderBy: 'createdTime desc',
      pageSize: 100,
      $fields: 'files($_fileFields)',
    );

    return (result.files ?? const <drive.File>[])
        .map(_toBackupFile)
        .toList();
  }

  Future<void> deleteBackup(String fileId) {
    return _driveApi.files.delete(fileId);
  }

  Future<File> download(String fileId, File destination) async {
    final media =
        await _driveApi.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final sink = destination.openWrite();
    await media.stream.pipe(sink);
    await sink.close();

    return destination;
  }

  Future<void> pruneOldBackups() async {
    final backups = await listBackups();
    final idsToDelete = backupIdsToDelete(backups, keep: maxBackupsToKeep);
    for (final id in idsToDelete) {
      await deleteBackup(id);
    }
  }

  DriveBackupFile _toBackupFile(drive.File file) {
    return DriveBackupFile(
      id: file.id!,
      name: file.name ?? 'backup',
      createdAt: file.createdTime ?? DateTime.now(),
      sizeBytes: int.tryParse(file.size ?? '0') ?? 0,
    );
  }
}

List<String> backupIdsToDelete(
  List<DriveBackupFile> backups, {
  required int keep,
}) {
  final sorted = [...backups]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  if (sorted.length <= keep) {
    return const [];
  }
  return sorted.sublist(keep).map((backup) => backup.id).toList();
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/backup/data/drive_backup_service_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/backup/data/drive_backup_service.dart test/features/backup/data/drive_backup_service_test.dart
git commit -m "feat: add DriveBackupService for Drive appDataFolder operations"
```

---

### Task 6: Google auth service

**Files:**
- Create: `lib/features/backup/data/google_auth_service.dart`

**Note:** This is a thin wrapper around the `google_sign_in` plugin, which talks to platform channels. It cannot be meaningfully unit-tested without a real device/emulator and a real Google account — that is covered by the manual QA pass in Task 15. No test file for this task.

- [ ] **Step 1: Implement GoogleAuthService**

Create `lib/features/backup/data/google_auth_service.dart`:

```dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  static const List<String> scopes = <String>[
    'https://www.googleapis.com/auth/drive.appdata',
  ];

  final GoogleSignIn _signIn = GoogleSignIn.instance;
  Future<void>? _initialization;

  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      _signIn.authenticationEvents;

  Future<void> ensureInitialized() {
    return _initialization ??= _signIn.initialize().catchError((error) {
      _initialization = null;
      throw error;
    });
  }

  Future<GoogleSignInAccount?> attemptSilentSignIn() async {
    await ensureInitialized();
    return _signIn.attemptLightweightAuthentication();
  }

  Future<GoogleSignInAccount> signIn() async {
    await ensureInitialized();
    return _signIn.authenticate(scopeHint: scopes);
  }

  Future<void> disconnect() async {
    await ensureInitialized();
    await _signIn.disconnect();
  }

  Future<http.Client?> authenticatedHttpClient(
    GoogleSignInAccount account, {
    bool promptIfNecessary = false,
  }) async {
    final authorization = promptIfNecessary
        ? await account.authorizationClient.authorizeScopes(scopes)
        : await account.authorizationClient.authorizationForScopes(scopes);

    if (authorization == null) {
      return null;
    }

    return _BearerTokenClient(authorization.accessToken);
  }
}

class _BearerTokenClient extends http.BaseClient {
  _BearerTokenClient(this._accessToken);

  final String _accessToken;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
```

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze lib/features/backup/data/google_auth_service.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/backup/data/google_auth_service.dart
git commit -m "feat: add GoogleAuthService wrapping google_sign_in for Drive scope"
```

---

### Task 7: Backup controller (state, connect/disconnect, backup, restore, auto-backup trigger)

**Files:**
- Create: `lib/features/backup/providers/backup_controller.dart`
- Test: `test/features/backup/providers/backup_controller_test.dart`

- [ ] **Step 1: Write the failing test for the pure auto-backup trigger logic**

`shouldAutoBackup` is a pure function so it can be tested without Riverpod, network, or platform channels.

Create `test/features/backup/providers/backup_controller_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/backup/providers/backup_controller.dart';

void main() {
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
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/backup/providers/backup_controller_test.dart`
Expected: FAIL — cannot find `package:flutter_wasilah_app/features/backup/providers/backup_controller.dart`

- [ ] **Step 3: Implement BackupState and BackupController**

Create `lib/features/backup/providers/backup_controller.dart`:

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/core/storage/preferences_service.dart';
import 'package:flutter_wasilah_app/features/backup/data/backup_snapshot.dart';
import 'package:flutter_wasilah_app/features/backup/data/drive_backup_service.dart';
import 'package:flutter_wasilah_app/features/backup/data/google_auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum BackupConnectionStatus { disconnected, connecting, connected }

@immutable
class BackupState {
  const BackupState({
    this.connectionStatus = BackupConnectionStatus.disconnected,
    this.accountEmail,
    this.autoBackupEnabled = true,
    this.lastBackupAt,
    this.isBackingUp = false,
    this.isRestoring = false,
    this.errorMessage,
  });

  final BackupConnectionStatus connectionStatus;
  final String? accountEmail;
  final bool autoBackupEnabled;
  final DateTime? lastBackupAt;
  final bool isBackingUp;
  final bool isRestoring;
  final String? errorMessage;

  bool get isConnected => connectionStatus == BackupConnectionStatus.connected;

  bool get isBusy => isBackingUp || isRestoring;

  BackupState copyWith({
    BackupConnectionStatus? connectionStatus,
    String? accountEmail,
    bool? autoBackupEnabled,
    DateTime? lastBackupAt,
    bool? isBackingUp,
    bool? isRestoring,
    String? errorMessage,
    bool clearError = false,
    bool clearAccountEmail = false,
  }) {
    return BackupState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      accountEmail: clearAccountEmail
          ? null
          : (accountEmail ?? this.accountEmail),
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      isRestoring: isRestoring ?? this.isRestoring,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

final backupSnapshotServiceProvider = Provider<BackupSnapshotService>((ref) {
  return const BackupSnapshotService();
});

final backupControllerProvider =
    NotifierProvider<BackupController, BackupState>(BackupController.new);

class BackupController extends Notifier<BackupState> {
  static const _autoBackupInterval = Duration(hours: 24);

  @override
  BackupState build() {
    final preferences = ref.watch(preferencesServiceProvider);
    final initial = BackupState(
      autoBackupEnabled: preferences.readAutoBackupEnabled(),
      lastBackupAt: preferences.readLastBackupAt(),
    );
    _restoreSession();
    return initial;
  }

  Future<void> _restoreSession() async {
    final GoogleSignInAccount? account;
    try {
      final authService = ref.read(googleAuthServiceProvider);
      account = await authService.attemptSilentSignIn();
    } catch (_) {
      // Diam: sign-in tersimpan tidak tersedia (mis. Play Services
      // tidak ada), tetap tampil sebagai belum terhubung.
      return;
    }
    if (account == null) {
      return;
    }
    state = state.copyWith(
      connectionStatus: BackupConnectionStatus.connected,
      accountEmail: account.email,
    );
  }

  Future<void> connect() async {
    state = state.copyWith(
      connectionStatus: BackupConnectionStatus.connecting,
      clearError: true,
    );
    try {
      final authService = ref.read(googleAuthServiceProvider);
      final account = await authService.signIn();
      await ref.read(preferencesServiceProvider).writeAutoBackupEnabled(true);
      state = state.copyWith(
        connectionStatus: BackupConnectionStatus.connected,
        accountEmail: account.email,
        autoBackupEnabled: true,
      );
    } catch (_) {
      state = state.copyWith(
        connectionStatus: BackupConnectionStatus.disconnected,
        errorMessage: 'Gagal menghubungkan akun Google.',
      );
    }
  }

  Future<void> disconnect() async {
    if (state.isBusy) {
      return;
    }
    final authService = ref.read(googleAuthServiceProvider);
    await authService.disconnect();
    state = state.copyWith(
      connectionStatus: BackupConnectionStatus.disconnected,
      clearAccountEmail: true,
    );
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    await ref.read(preferencesServiceProvider).writeAutoBackupEnabled(enabled);
    state = state.copyWith(autoBackupEnabled: enabled);
  }

  Future<void> backupNow() async {
    if (state.isBusy) {
      return;
    }
    state = state.copyWith(isBackingUp: true, clearError: true);
    try {
      await _performBackup(promptIfNecessary: true);
      state = state.copyWith(isBackingUp: false);
    } catch (_) {
      state = state.copyWith(
        isBackingUp: false,
        errorMessage: 'Backup gagal. Coba lagi nanti.',
      );
    }
  }

  Future<void> maybeAutoBackup() async {
    if (!state.isConnected || !state.autoBackupEnabled || state.isBusy) {
      return;
    }
    final due = shouldAutoBackup(
      now: DateTime.now(),
      lastBackupAt: state.lastBackupAt,
      interval: _autoBackupInterval,
    );
    if (!due) {
      return;
    }
    state = state.copyWith(isBackingUp: true);
    try {
      await _performBackup(promptIfNecessary: false);
    } catch (_) {
      // Diam: dicoba lagi otomatis pada resume/launch berikutnya.
    } finally {
      state = state.copyWith(isBackingUp: false);
    }
  }

  Future<List<DriveBackupFile>> listBackups() async {
    final authorized = await _authorizedDriveService(promptIfNecessary: true);
    try {
      return await authorized.service.listBackups();
    } finally {
      authorized.client.close();
    }
  }

  Future<void> restore(String fileId) async {
    if (state.isBusy) {
      throw StateError('Proses backup/restore lain sedang berjalan.');
    }
    state = state.copyWith(isRestoring: true, clearError: true);
    try {
      await _performRestore(fileId);
    } finally {
      state = state.copyWith(isRestoring: false);
    }
  }

  Future<void> _performRestore(String fileId) async {
    final authorized = await _authorizedDriveService(promptIfNecessary: true);
    final File downloadFile;
    try {
      final tempDir = await getTemporaryDirectory();
      downloadFile = File(
        p.join(
          tempDir.path,
          'wasilah_restore_${DateTime.now().millisecondsSinceEpoch}.sqlite',
        ),
      );
      await authorized.service.download(fileId, downloadFile);
    } finally {
      authorized.client.close();
    }

    final snapshotService = ref.read(backupSnapshotServiceProvider);
    if (!snapshotService.isValidSqliteFile(downloadFile)) {
      await downloadFile.delete();
      throw StateError('File backup tidak valid.');
    }

    await ref.read(appDatabaseProvider).close();

    final currentDbFile = await resolveDatabaseFile();
    final safetyCopy = File('${currentDbFile.path}.bak');
    if (currentDbFile.existsSync()) {
      if (safetyCopy.existsSync()) {
        await safetyCopy.delete();
      }
      await currentDbFile.rename(safetyCopy.path);
    }

    try {
      await downloadFile.rename(currentDbFile.path);
    } catch (_) {
      if (safetyCopy.existsSync()) {
        await safetyCopy.rename(currentDbFile.path);
      }
      rethrow;
    }

    ref.invalidate(appDatabaseProvider);

    if (safetyCopy.existsSync()) {
      await safetyCopy.delete();
    }
  }

  Future<({DriveBackupService service, http.Client client})>
  _authorizedDriveService({required bool promptIfNecessary}) async {
    final authService = ref.read(googleAuthServiceProvider);
    final account = await authService.attemptSilentSignIn();
    if (account == null) {
      throw StateError('Akun Google belum terhubung.');
    }
    final client = await authService.authenticatedHttpClient(
      account,
      promptIfNecessary: promptIfNecessary,
    );
    if (client == null) {
      throw StateError('Otorisasi Google Drive dibutuhkan.');
    }
    return (service: DriveBackupService(drive.DriveApi(client)), client: client);
  }

  Future<void> _performBackup({required bool promptIfNecessary}) async {
    final authorized = await _authorizedDriveService(
      promptIfNecessary: promptIfNecessary,
    );
    final snapshotService = ref.read(backupSnapshotServiceProvider);
    final database = ref.read(appDatabaseProvider);

    final snapshotFile = await snapshotService.createSnapshot(database);
    try {
      if (!snapshotService.isValidSqliteFile(snapshotFile)) {
        throw StateError('Snapshot database tidak valid.');
      }
      await authorized.service.upload(snapshotFile);
      await authorized.service.pruneOldBackups();
    } finally {
      authorized.client.close();
      if (snapshotFile.existsSync()) {
        await snapshotFile.delete();
      }
    }

    final now = DateTime.now();
    await ref.read(preferencesServiceProvider).writeLastBackupAt(now);
    state = state.copyWith(lastBackupAt: now);
  }
}

bool shouldAutoBackup({
  required DateTime now,
  required DateTime? lastBackupAt,
  required Duration interval,
}) {
  if (lastBackupAt == null) {
    return true;
  }
  return now.difference(lastBackupAt) >= interval;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/backup/providers/backup_controller_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Run static analysis on the new file**

Run: `flutter analyze lib/features/backup/providers/backup_controller.dart`
Expected: No issues found

- [ ] **Step 6: Commit**

```bash
git add lib/features/backup/providers/backup_controller.dart test/features/backup/providers/backup_controller_test.dart
git commit -m "feat: add BackupController for connect/backup/restore flows"
```

---

### Task 8: Android manifest — explicit INTERNET permission

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add the permission**

In `android/app/src/main/AndroidManifest.xml`, add this line as a direct child of `<manifest>`, placed after the closing `</application>` tag and before the existing `<queries>` block:

```xml
    <uses-permission android:name="android.permission.INTERNET" />
```

The relevant section should read:

```xml
    </application>
    <uses-permission android:name="android.permission.INTERNET" />
    <!-- Required to query activities that can process text, see:
         https://developer.android.com/training/package-visibility and
         https://developer.android.com/reference/android/content/Intent#ACTION_PROCESS_TEXT.

         In particular, this is used by the Flutter engine in io.flutter.plugin.text.ProcessTextPlugin. -->
    <queries>
```

- [ ] **Step 2: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "chore: declare INTERNET permission explicitly for Drive backup"
```

---

### Task 9: Backup section widget for Settings

**Files:**
- Create: `lib/features/backup/presentation/widgets/backup_section.dart`
- Test: `test/features/backup/presentation/backup_section_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `test/features/backup/presentation/backup_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/backup/presentation/widgets/backup_section.dart';
import 'package:flutter_wasilah_app/features/backup/providers/backup_controller.dart';

void main() {
  group('BackupSection', () {
    testWidgets('shows connect button when not connected', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backupControllerProvider.overrideWith(
              () => _FakeBackupController(const BackupState()),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: BackupSection()),
          ),
        ),
      );

      expect(find.text('Hubungkan akun Google'), findsOneWidget);
      expect(find.text('Backup sekarang'), findsNothing);
    });

    testWidgets('shows backup controls and last backup time when connected', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backupControllerProvider.overrideWith(
              () => _FakeBackupController(
                BackupState(
                  connectionStatus: BackupConnectionStatus.connected,
                  accountEmail: 'user@gmail.com',
                  lastBackupAt: DateTime(2026, 7, 17),
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: BackupSection()),
          ),
        ),
      );

      expect(find.text('user@gmail.com'), findsOneWidget);
      expect(find.text('Backup sekarang'), findsOneWidget);
      expect(find.textContaining('17 Juli 2026'), findsOneWidget);
    });
  });
}

class _FakeBackupController extends BackupController {
  _FakeBackupController(this._initialState);

  final BackupState _initialState;

  @override
  BackupState build() => _initialState;
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/backup/presentation/backup_section_test.dart`
Expected: FAIL — cannot find `package:flutter_wasilah_app/features/backup/presentation/widgets/backup_section.dart`

- [ ] **Step 3: Implement BackupSection**

Create `lib/features/backup/presentation/widgets/backup_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/features/backup/providers/backup_controller.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_primary_button.dart';
import 'package:go_router/go_router.dart';

class BackupSection extends ConsumerWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupControllerProvider);
    final controller = ref.read(backupControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!state.isConnected) ...[
          Text(
            'Hubungkan akun Google untuk mem-backup data portofolio Anda.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: 'Hubungkan akun Google',
            isLoading:
                state.connectionStatus == BackupConnectionStatus.connecting,
            onPressed: controller.connect,
          ),
        ] else ...[
          Row(
            children: [
              const Icon(Icons.account_circle_outlined),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  state.accountEmail ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: state.isBusy ? null : controller.disconnect,
                child: const Text('Putuskan'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Backup otomatis'),
            value: state.autoBackupEnabled,
            onChanged: controller.setAutoBackupEnabled,
          ),
          Text(
            state.isRestoring
                ? 'Sedang memulihkan data...'
                : state.lastBackupAt == null
                ? 'Belum pernah backup.'
                : 'Backup terakhir: ${formatFullDate(state.lastBackupAt!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: 'Backup sekarang',
            isLoading: state.isBackingUp,
            onPressed: state.isBusy ? null : controller.backupNow,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppPrimaryButton(
            label: 'Pulihkan dari backup',
            isFullWidth: true,
            onPressed: state.isBusy
                ? null
                : () => context.push(RouteNames.backupRestore),
          ),
        ],
        if (state.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            state.errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/backup/presentation/backup_section_test.dart`
Expected: PASS (2 tests) — this will still fail at this point because `RouteNames.backupRestore` doesn't exist yet.

Run `flutter analyze lib/features/backup/presentation/widgets/backup_section.dart` to confirm the only error is the missing `RouteNames.backupRestore` constant, then proceed to Step 5 before re-running the test.

- [ ] **Step 5: Add the route name constant referenced above**

Modify `lib/core/router/route_names.dart`:

```dart
abstract final class RouteNames {
  static const String dashboard = '/dashboard';
  static const String history = '/history';
  static const String assets = '/assets';
  static const String assetCreate = '/assets/new';
  static const String assetUpdate = '/assets/update';
  static const String target = '/target';
  static const String targetCreate = '/target/new';
  static const String settings = '/settings';
  static const String backupRestore = '/settings/backup/restore';
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/features/backup/presentation/backup_section_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 7: Commit**

```bash
git add lib/features/backup/presentation/widgets/backup_section.dart lib/core/router/route_names.dart test/features/backup/presentation/backup_section_test.dart
git commit -m "feat: add BackupSection widget with connect/backup/restore controls"
```

---

### Task 10: Restore page

**Files:**
- Create: `lib/features/backup/presentation/pages/restore_page.dart`
- Modify: `lib/core/router/app_router.dart`

- [ ] **Step 1: Implement RestorePage**

Create `lib/features/backup/presentation/pages/restore_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/features/backup/data/drive_backup_service.dart';
import 'package:flutter_wasilah_app/features/backup/providers/backup_controller.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_error_view.dart';

final _backupListProvider = FutureProvider.autoDispose<List<DriveBackupFile>>((
  ref,
) {
  return ref.read(backupControllerProvider.notifier).listBackups();
});

class RestorePage extends ConsumerWidget {
  const RestorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupsAsync = ref.watch(_backupListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pulihkan dari backup')),
      body: backupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => AppErrorView(
          title: 'Daftar backup gagal dimuat',
          onRetry: () => ref.invalidate(_backupListProvider),
        ),
        data: (backups) {
          if (backups.isEmpty) {
            return const AppEmptyState(
              title: 'Belum ada backup',
              message: 'Backup pertama Anda akan muncul di sini.',
              icon: Icons.cloud_off_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: backups.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final backup = backups[index];
              return ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(formatFullDate(backup.createdAt)),
                subtitle: Text(_formatFileSize(backup.sizeBytes)),
                onTap: () => _confirmRestore(context, ref, backup),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmRestore(
    BuildContext context,
    WidgetRef ref,
    DriveBackupFile backup,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pulihkan data ini?'),
        content: Text(
          'Data portofolio saat ini akan diganti dengan backup tanggal '
          '${formatFullDate(backup.createdAt)}. Tindakan ini tidak dapat '
          'dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Pulihkan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref.read(backupControllerProvider.notifier).restore(backup.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil dipulihkan.')),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pemulihan gagal. Coba lagi.')),
        );
      }
    }
  }
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
```

- [ ] **Step 2: Wire the route**

Modify `lib/core/router/app_router.dart`:

Add this import alongside the other feature imports:

```dart
import 'package:flutter_wasilah_app/features/backup/presentation/pages/restore_page.dart';
```

Add this route as a top-level `GoRoute`, alongside the other non-shell routes (e.g. right after the `RouteNames.targetCreate` route block):

```dart
      GoRoute(
        path: RouteNames.backupRestore,
        builder: (context, state) => const RestorePage(),
      ),
```

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze lib/features/backup/presentation/pages/restore_page.dart lib/core/router/app_router.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/features/backup/presentation/pages/restore_page.dart lib/core/router/app_router.dart
git commit -m "feat: add RestorePage and wire backup restore route"
```

---

### Task 11: Wire BackupSection into Settings page

**Files:**
- Modify: `lib/features/settings/presentation/pages/settings_page.dart`

- [ ] **Step 1: Add a "Backup" card to Settings**

In `lib/features/settings/presentation/pages/settings_page.dart`, add this import:

```dart
import 'package:flutter_wasilah_app/features/backup/presentation/widgets/backup_section.dart';
```

Insert a new `AppCard` between the "Tampilan" card and the "Aplikasi" card (i.e. right after the closing of the first `AppCard` + `SizedBox(height: AppSpacing.xl)`, before the second `AppCard`):

```dart
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SettingsSectionHeader('Backup'),
                SizedBox(height: AppSpacing.md),
                BackupSection(),
              ],
            ),
          ),
```

The full `children` list of the outer `ListView` should now read, in order: theme card, `SizedBox(height: AppSpacing.xl)`, backup card, `SizedBox(height: AppSpacing.xl)`, app-info card.

- [ ] **Step 2: Run existing settings-related tests**

Run: `flutter analyze lib/features/settings/presentation/pages/settings_page.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/presentation/pages/settings_page.dart
git commit -m "feat: surface BackupSection in Settings page"
```

---

### Task 12: Trigger auto-backup on app launch/resume

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: Convert App to a ConsumerStatefulWidget with a lifecycle observer**

Replace the contents of `lib/app.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/app_router.dart';
import 'package:flutter_wasilah_app/core/theme/app_theme.dart';
import 'package:flutter_wasilah_app/features/backup/providers/backup_controller.dart';
import 'package:flutter_wasilah_app/features/settings/providers/theme_mode_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backupControllerProvider.notifier).maybeAutoBackup();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(backupControllerProvider.notifier).maybeAutoBackup();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Wasilah',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 2: Run the full test suite to confirm nothing that depends on `App` broke**

Run: `flutter test test/app/router/app_router_hero_test.dart`
Expected: PASS

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze lib/app.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart
git commit -m "feat: trigger auto-backup on app launch and resume"
```

---

### Task 13: Google Cloud Console setup documentation

**Files:**
- Create: `docs/google-drive-backup-setup.md`

**Why:** Backing up to Drive requires an OAuth client registered in Google Cloud Console, tied to this app's package name and signing certificate. This is a manual, one-time console task that cannot be scripted from this repo — document it so it isn't lost.

- [ ] **Step 1: Write the setup doc**

Create `docs/google-drive-backup-setup.md`:

```markdown
# Google Drive Backup — Cloud Console Setup

One-time setup required before the Google Drive backup feature will work.
Package name: `com.amar.wasilah`.

## 1. Get the SHA-1 signing fingerprints

Debug (used by `flutter run`):

```bash
cd android
./gradlew signingReport
```

Look for the `SHA1` line under the `debug` variant. Repeat for the `release`
variant once a release keystore exists.

## 2. Google Cloud Console

1. Go to https://console.cloud.google.com/ and select or create a project
   (the existing Firebase project for this app can be reused).
2. **APIs & Services > Library** — enable the **Google Drive API**.
3. **APIs & Services > OAuth consent screen**:
   - User type: External.
   - Scopes: add `.../auth/drive.appdata` (marked non-sensitive by Google —
     no verification review required).
4. **APIs & Services > Credentials > Create Credentials > OAuth client ID**:
   - Application type: Android.
   - Package name: `com.amar.wasilah`.
   - SHA-1 certificate fingerprint: paste the debug SHA-1 from step 1.
   - Repeat this step for the release SHA-1 once available (each
     certificate needs its own OAuth client entry).

No changes to `google-services.json` are needed for sign-in itself — that
file is currently only used for Firebase Crashlytics.

## 3. Verify

Run the app on a device or emulator with Google Play Services, open
**Setelan > Backup**, and tap **Hubungkan akun Google**. If the OAuth client
isn't configured correctly, sign-in will fail immediately with a
`GoogleSignInException` (`ApiException: 10`), which means the SHA-1/package
name pair doesn't match what's registered in Cloud Console.
```

- [ ] **Step 2: Commit**

```bash
git add docs/google-drive-backup-setup.md
git commit -m "docs: add Google Cloud Console setup steps for Drive backup"
```

---

### Task 14: Full verification pass

**Files:** none (verification only)

- [ ] **Step 1: Run static analysis on the whole project**

Run: `flutter analyze`
Expected: No issues found. If issues appear, fix them in the relevant file from the tasks above and re-run.

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: All tests pass, including the new backup tests from Tasks 2, 4, 5, 7, and 9.

- [ ] **Step 3: Manual QA checklist (requires a real Android device/emulator with Play Services and a completed Task 13 Cloud Console setup)**

Walk through and confirm each of these:

- [ ] Open Settings, tap "Hubungkan akun Google" — Google account picker appears and sign-in succeeds.
- [ ] Tap "Backup sekarang" — button shows loading, then "Backup terakhir" updates to today's date.
- [ ] Force-close and reopen the app — account stays connected (silent sign-in via `attemptLightweightAuthentication`).
- [ ] Add/edit an asset, tap "Pulihkan dari backup", confirm the earlier backup is listed with a plausible size.
- [ ] Select that backup, confirm the warning dialog, confirm restore — the asset edit is reverted to match the backed-up state.
- [ ] Turn off "Backup otomatis", force-close, wait, reopen — no new backup is created.
- [ ] Turn "Backup otomatis" back on, manually set the device clock forward >24h (or wait), reopen the app — a new automatic backup happens silently (verify via "Backup terakhir" timestamp).
- [ ] Turn off device network, tap "Backup sekarang" — a clear error message appears and the app does not crash.
- [ ] Tap "Putuskan" to disconnect — Settings returns to the "Hubungkan akun Google" state.

- [ ] **Step 4: Final commit if any fixes were needed**

```bash
git add -A
git commit -m "fix: address issues found during backup feature verification"
```

(Skip this step if Steps 1–3 required no changes.)
