import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
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
    this.error,
  });

  final BackupConnectionStatus connectionStatus;
  final String? accountEmail;
  final bool autoBackupEnabled;
  final DateTime? lastBackupAt;
  final bool isBackingUp;
  final bool isRestoring;
  final Object? error;

  bool get isConnected => connectionStatus == BackupConnectionStatus.connected;

  bool get isBusy => isBackingUp || isRestoring;

  BackupState copyWith({
    BackupConnectionStatus? connectionStatus,
    String? accountEmail,
    bool? autoBackupEnabled,
    DateTime? lastBackupAt,
    bool? isBackingUp,
    bool? isRestoring,
    Object? error,
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
      error: clearError ? null : (error ?? this.error),
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
  // Setelah satu percobaan auto-backup (berhasil atau gagal), jangan coba
  // lagi dalam rentang ini. Tanpa jeda ini setiap resume akan mengulang
  // percobaan yang gagal — dan tiap percobaan berpotensi memunculkan UI
  // Credential Manager.
  static const _autoBackupRetryCooldown = Duration(hours: 1);

  /// Akun aktif hasil sign-in interaktif di sesi ini, disinkronkan dari
  /// [GoogleAuthService.authenticationEvents].
  ///
  /// Boleh null walau status terhubung: setelah app restart, identitas dibaca
  /// dari preferences dan token Drive diambil lewat authorization client
  /// tingkat instance — tanpa autentikasi ulang, jadi tanpa UI Credential
  /// Manager.
  GoogleSignInAccount? _account;
  DateTime? _lastAutoBackupAttemptAt;

  @override
  BackupState build() {
    final preferences = ref.watch(preferencesServiceProvider);
    // Status terhubung dipulihkan dari preferences, bukan dari sign-in ulang.
    final wasConnected = preferences.readBackupConnected();
    final initial = BackupState(
      autoBackupEnabled: preferences.readAutoBackupEnabled(),
      lastBackupAt: preferences.readLastBackupAt(),
      connectionStatus: wasConnected
          ? BackupConnectionStatus.connected
          : BackupConnectionStatus.disconnected,
      accountEmail: wasConnected ? preferences.readBackupAccountEmail() : null,
    );
    unawaited(_startSession());
    return initial;
  }

  Future<void> _startSession() async {
    final authService = ref.read(googleAuthServiceProvider);
    try {
      await authService.ensureInitialized();
    } catch (error) {
      // Diam: Google Sign-In tidak tersedia (mis. tanpa Play Services),
      // tetap tampil sebagai belum terhubung.
      if (kDebugMode) {
        debugPrint('Google sign-in initialize skipped: $error');
      }
      return;
    }

    // Sumber kebenaran tunggal untuk akun aktif. Berlangganan saja tidak
    // memunculkan UI apa pun.
    final subscription = authService.authenticationEvents.listen(
      _handleAuthenticationEvent,
      onError: (Object error) {
        if (kDebugMode) {
          debugPrint('Google sign-in event error: $error');
        }
      },
    );
    ref.onDispose(subscription.cancel);

    // Tidak ada silent sign-in di sini. `attemptLightweightAuthentication()`
    // di Android lewat Credential Manager dan tetap mengedipkan bottom sheet
    // walau tidak butuh input user. Autentikasi hanya terjadi lewat
    // [connect], yang dipicu user.
  }

  void _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    final account = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };
    _account = account;
    final preferences = ref.read(preferencesServiceProvider);
    if (account == null) {
      state = state.copyWith(
        connectionStatus: BackupConnectionStatus.disconnected,
        clearAccountEmail: true,
      );
      unawaited(preferences.writeBackupConnected(false));
      unawaited(preferences.writeBackupAccountEmail(null));
      return;
    }
    state = state.copyWith(
      connectionStatus: BackupConnectionStatus.connected,
      accountEmail: account.email,
    );
    unawaited(preferences.writeBackupConnected(true));
    unawaited(preferences.writeBackupAccountEmail(account.email));
  }

  Future<void> connect() async {
    state = state.copyWith(
      connectionStatus: BackupConnectionStatus.connecting,
      clearError: true,
    );
    try {
      final authService = ref.read(googleAuthServiceProvider);
      final account = await authService.signIn();
      _account = account;
      final preferences = ref.read(preferencesServiceProvider);
      await preferences.writeAutoBackupEnabled(true);
      await preferences.writeBackupConnected(true);
      await preferences.writeBackupAccountEmail(account.email);
      state = state.copyWith(
        connectionStatus: BackupConnectionStatus.connected,
        accountEmail: account.email,
        autoBackupEnabled: true,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Google sign-in connect failed: $error');
      }
      state = state.copyWith(
        connectionStatus: BackupConnectionStatus.disconnected,
        error: const GoogleConnectFailedException(),
      );
    }
  }

  Future<void> disconnect() async {
    if (state.isBusy) {
      return;
    }
    final authService = ref.read(googleAuthServiceProvider);
    await authService.disconnect();
    _account = null;
    _lastAutoBackupAttemptAt = null;
    final preferences = ref.read(preferencesServiceProvider);
    await preferences.writeBackupConnected(false);
    await preferences.writeBackupAccountEmail(null);
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
        error: const BackupFailedException(),
      );
    }
  }

  Future<void> maybeAutoBackup() async {
    if (!state.isConnected || !state.autoBackupEnabled || state.isBusy) {
      return;
    }
    final now = DateTime.now();
    final due = shouldAttemptAutoBackup(
      now: now,
      lastBackupAt: state.lastBackupAt,
      lastAttemptAt: _lastAutoBackupAttemptAt,
      interval: _autoBackupInterval,
      retryCooldown: _autoBackupRetryCooldown,
    );
    if (!due) {
      return;
    }
    _lastAutoBackupAttemptAt = now;
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
      throw const InvalidBackupFileException();
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
    // Sengaja tidak memanggil silent sign-in di sini. Gerbangnya status
    // terhubung (dari preferences), bukan keberadaan objek akun: token Drive
    // diambil dari grant yang sudah di-cache platform.
    if (!state.isConnected) {
      throw const GoogleNotConnectedException();
    }
    final client = await authService.authenticatedHttpClient(
      account: _account,
      promptIfNecessary: promptIfNecessary,
    );
    if (client == null) {
      throw const GoogleAuthorizationRequiredException();
    }
    return (
      service: DriveBackupService(drive.DriveApi(client)),
      client: client,
    );
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

/// [shouldAutoBackup] plus jeda antar percobaan.
///
/// Percobaan yang gagal atau dibatalkan tidak mengubah `lastBackupAt`, jadi
/// tanpa [retryCooldown] backup akan dicoba ulang di setiap resume — dan tiap
/// percobaan bisa memunculkan UI Google Sign-In.
bool shouldAttemptAutoBackup({
  required DateTime now,
  required DateTime? lastBackupAt,
  required DateTime? lastAttemptAt,
  required Duration interval,
  required Duration retryCooldown,
}) {
  if (lastAttemptAt != null && now.difference(lastAttemptAt) < retryCooldown) {
    return false;
  }
  return shouldAutoBackup(
    now: now,
    lastBackupAt: lastBackupAt,
    interval: interval,
  );
}
