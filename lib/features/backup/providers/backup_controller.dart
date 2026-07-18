import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/core/storage/preferences_service.dart';
import 'package:flutter_wasilah_app/features/backup/data/backup_snapshot.dart';
import 'package:flutter_wasilah_app/features/backup/data/drive_backup_service.dart';
import 'package:flutter_wasilah_app/features/backup/data/google_auth_service.dart';
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
    final authService = ref.read(googleAuthServiceProvider);
    final account = await authService.attemptSilentSignIn();
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
