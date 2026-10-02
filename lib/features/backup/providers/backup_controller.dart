import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/core/database/database_file_recovery.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/core/errors/error_reporter.dart';
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
    } on Object catch (error) {
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
      unawaited(preferences.writeBackupConnected(connected: false));
      unawaited(preferences.writeBackupAccountEmail(null));
      return;
    }
    state = state.copyWith(
      connectionStatus: BackupConnectionStatus.connected,
      accountEmail: account.email,
    );
    unawaited(preferences.writeBackupConnected(connected: true));
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
      await preferences.writeAutoBackupEnabled(enabled: true);
      await preferences.writeBackupConnected(connected: true);
      await preferences.writeBackupAccountEmail(account.email);
      state = state.copyWith(
        connectionStatus: BackupConnectionStatus.connected,
        accountEmail: account.email,
        autoBackupEnabled: true,
      );
    } on Object catch (error, stackTrace) {
      // User menutup sendiri dialog akun: bukan kegagalan.
      final canceled =
          error is GoogleSignInException &&
          error.code == GoogleSignInExceptionCode.canceled;
      if (!canceled) {
        _report(error, stackTrace, reason: 'Google connect failed');
      }
      state = state.copyWith(
        connectionStatus: BackupConnectionStatus.disconnected,
        error: canceled ? null : const GoogleConnectFailedException(),
      );
    }
  }

  Future<void> disconnect() async {
    if (state.isBusy) {
      return;
    }
    final authService = ref.read(googleAuthServiceProvider);
    try {
      await authService.disconnect();
    } on Object catch (error, stackTrace) {
      // Mis. offline: grant di sisi Google mungkin masih ada, tapi di app ini
      // akun tetap diputus supaya UI tidak tertahan di status terhubung.
      // Kegagalan sisi Google hanya dilaporkan, tidak ditampilkan sebagai
      // error backup.
      _report(error, stackTrace, reason: 'Google disconnect failed');
    } finally {
      _account = null;
      _lastAutoBackupAttemptAt = null;
      final preferences = ref.read(preferencesServiceProvider);
      await preferences.writeBackupConnected(connected: false);
      await preferences.writeBackupAccountEmail(null);
      state = state.copyWith(
        connectionStatus: BackupConnectionStatus.disconnected,
        clearAccountEmail: true,
      );
    }
  }

  // Dipakai langsung sebagai `onChanged` Switch (ValueChanged<bool>).
  // ignore: avoid_positional_boolean_parameters
  Future<void> setAutoBackupEnabled(bool enabled) async {
    await ref
        .read(preferencesServiceProvider)
        .writeAutoBackupEnabled(enabled: enabled);
    state = state.copyWith(autoBackupEnabled: enabled);
  }

  Future<void> backupNow() async {
    if (state.isBusy) {
      return;
    }
    state = state.copyWith(isBackingUp: true, clearError: true);
    try {
      await _performBackupWithRetry(promptIfNecessary: true);
      state = state.copyWith(isBackingUp: false);
    } on Object catch (error, stackTrace) {
      final isAuthError = _isAuthError(error);
      _reportBackupFailure(error, stackTrace, reason: 'Manual backup failed');
      state = state.copyWith(
        isBackingUp: false,
        error: isAuthError ? error : const BackupFailedException(),
      );
    }
  }

  static bool _isAuthError(Object error) =>
      error is GoogleNotConnectedException ||
      error is GoogleAuthorizationRequiredException;

  void _report(Object error, StackTrace stackTrace, {required String reason}) {
    ref.read(errorReporterProvider).report(error, stackTrace, reason: reason);
  }

  /// Belum terhubung adalah keadaan normal, tidak dilaporkan. Otorisasi Drive
  /// yang hilang dilaporkan terpisah supaya bisa dibedakan dari error lain.
  void _reportBackupFailure(
    Object error,
    StackTrace stackTrace, {
    required String reason,
  }) {
    if (error is GoogleNotConnectedException) {
      return;
    }
    _report(
      error,
      stackTrace,
      reason: error is GoogleAuthorizationRequiredException
          ? 'Drive authorization required'
          : reason,
    );
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
      await _performBackupWithRetry(promptIfNecessary: false);
      state = state.copyWith(isBackingUp: false);
    } on Object catch (error, stackTrace) {
      // Dicoba lagi otomatis pada resume/launch berikutnya, tapi tetap
      // ditampilkan di pengaturan supaya kegagalan beruntun tidak luput.
      _reportBackupFailure(error, stackTrace, reason: 'Auto backup failed');
      state = state.copyWith(
        isBackingUp: false,
        error: _isAuthError(error) ? error : const AutoBackupFailedException(),
      );
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
      throw const RestoreInProgressException();
    }
    state = state.copyWith(isRestoring: true, clearError: true);
    try {
      await _performRestore(fileId);
    } on Object catch (error, stackTrace) {
      final isExpected =
          _isAuthError(error) ||
          error is InvalidBackupFileException ||
          error is IncompatibleBackupVersionException ||
          error is OutdatedBackupVersionException;
      if (!isExpected) {
        _report(error, stackTrace, reason: 'Restore failed');
      }
      rethrow;
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

    // Tolak backup dari versi skema yang lebih baru daripada yang dipahami
    // build ini: drift di sini tidak tahu cara downgrade, jadi database bisa
    // gagal dibuka kalau dipaksakan.
    final backupVersion = snapshotService.readSchemaVersion(downloadFile);
    if (backupVersion != null && backupVersion > appDatabaseSchemaVersion) {
      await downloadFile.delete();
      throw const IncompatibleBackupVersionException();
    }
    // Langkah migrasi untuk skema setua ini sudah dihapus dari app.
    if (backupVersion != null && backupVersion < minSupportedSchemaVersion) {
      await downloadFile.delete();
      throw const OutdatedBackupVersionException();
    }

    final currentDbFile = await resolveDatabaseFile();
    final safetyCopy = databaseSafetyCopyFile(currentDbFile);
    // Salinan pengaman sisa restore sebelumnya dibuang sebelum penanda
    // ditulis: selama penanda ada, `.bak` harus berasal dari restore ini.
    if (safetyCopy.existsSync()) {
      await safetyCopy.delete();
    }

    await ref.read(appDatabaseProvider).close();

    var movedAside = false;
    var movedIn = false;
    var committed = false;
    try {
      // Penanda tahan crash: kalau proses mati sebelum verifikasi selesai,
      // pembukaan database berikutnya mengembalikan salinan pengaman (lihat
      // [recoverInterruptedRestore]).
      await beginRestoreSwap(currentDbFile);
      if (currentDbFile.existsSync()) {
        await currentDbFile.rename(safetyCopy.path);
        movedAside = true;
      }
      await downloadFile.rename(currentDbFile.path);
      movedIn = true;

      ref.invalidate(appDatabaseProvider);

      // Buka database baru dan paksa migrasi jalan sekarang, bukan lazy pada
      // baca UI pertama, supaya restore yang rusak ketahuan sebelum safety
      // copy dibuang.
      try {
        await ref
            .read(appDatabaseProvider)
            .customSelect('PRAGMA user_version')
            .get();
      } on Object {
        throw const RestoreVerificationFailedException();
      }
      committed = true;
    } finally {
      try {
        var settled = committed;
        if (!committed) {
          try {
            await _rollBackRestore(
              currentDbFile: currentDbFile,
              safetyCopy: safetyCopy,
              movedAside: movedAside,
              movedIn: movedIn,
            );
            settled = true;
          } on Object catch (error, stackTrace) {
            // Error asli restore tetap yang dilempar. Penanda dibiarkan:
            // pemulihan diulang saat database dibuka di launch berikutnya.
            _report(error, stackTrace, reason: 'Restore rollback failed');
          }
        }
        if (settled) {
          // Titik commit: setelah penanda hilang, isi file database dianggap
          // sah.
          await endRestoreSwap(currentDbFile);
        }
        if (committed && safetyCopy.existsSync()) {
          await safetyCopy.delete();
        }
      } finally {
        if (downloadFile.existsSync()) {
          await downloadFile.delete();
        }
        // Apa pun yang terjadi, database yang tadi ditutup tidak boleh
        // tertinggal di provider: app akan macet tanpa koneksi.
        ref.invalidate(appDatabaseProvider);
      }
    }
  }

  /// Kembalikan database lama setelah restore gagal.
  Future<void> _rollBackRestore({
    required File currentDbFile,
    required File safetyCopy,
    required bool movedAside,
    required bool movedIn,
  }) async {
    if (movedIn) {
      try {
        await ref.read(appDatabaseProvider).close();
      } on Object {
        // Database hasil restore mungkin memang gagal dibuka.
      }
      if (currentDbFile.existsSync()) {
        await currentDbFile.delete();
      }
    }
    if (movedAside) {
      await safetyCopy.rename(currentDbFile.path);
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

  /// Satu kali coba ulang untuk gangguan jaringan sesaat, mis. koneksi belum
  /// siap tepat setelah app resume. Kalau upload pertama sebenarnya sampai
  /// tapi responsnya hilang, percobaan ulang menghasilkan backup ganda —
  /// tidak masalah, kelebihannya dipangkas
  /// [DriveBackupService.pruneOldBackups].
  Future<void> _performBackupWithRetry({
    required bool promptIfNecessary,
  }) async {
    try {
      await _performBackup(promptIfNecessary: promptIfNecessary);
    } on Object catch (error) {
      if (!isTransientNetworkError(error)) {
        rethrow;
      }
      await Future<void>.delayed(ref.read(backupRetryDelayProvider));
      await _performBackup(promptIfNecessary: promptIfNecessary);
    }
  }

  Future<void> _performBackup({required bool promptIfNecessary}) async {
    final authorized = await _authorizedDriveService(
      promptIfNecessary: promptIfNecessary,
    );
    final snapshotService = ref.read(backupSnapshotServiceProvider);
    final database = ref.read(appDatabaseProvider);

    try {
      final snapshotFile = await snapshotService.createSnapshot(database);
      try {
        if (!snapshotService.isValidSqliteFile(snapshotFile)) {
          throw const InvalidSnapshotException();
        }
        await authorized.service.upload(snapshotFile);
      } finally {
        if (snapshotFile.existsSync()) {
          await snapshotFile.delete();
        }
      }

      // Backup sudah aman di Drive begitu upload selesai: catat sekarang,
      // sebelum pemangkasan, supaya gagal pangkas tidak membuat backup yang
      // sebenarnya berhasil tercatat gagal.
      final now = DateTime.now();
      await ref.read(preferencesServiceProvider).writeLastBackupAt(now);
      state = state.copyWith(lastBackupAt: now, clearError: true);

      try {
        await authorized.service.pruneOldBackups();
      } on Object catch (error, stackTrace) {
        // Dicoba lagi pada backup berikutnya.
        _report(error, stackTrace, reason: 'Backup cleanup failed');
      }
    } finally {
      authorized.client.close();
    }
  }
}

final backupRetryDelayProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 5),
);

/// Error jaringan yang layak dicoba ulang: koneksi putus/timeout, atau Drive
/// sedang sibuk (5xx, 429).
bool isTransientNetworkError(Object error) {
  if (error is IOException ||
      error is http.ClientException ||
      error is TimeoutException) {
    return true;
  }
  if (error is drive.DetailedApiRequestError) {
    final status = error.status;
    return status == null || status == 429 || status >= 500;
  }
  return false;
}

/// Auto-backup hanya jalan saat app dibuka; lewat dari rentang ini berarti
/// backup sudah lama tidak berjalan dan perlu diingatkan.
const backupStaleAfter = Duration(days: 7);

bool isBackupStale({required DateTime now, required DateTime? lastBackupAt}) =>
    lastBackupAt != null && now.difference(lastBackupAt) > backupStaleAfter;

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
