import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/features/backup/data/drive_backup_service.dart';
import 'package:flutter_wasilah_app/features/backup/presentation/pages/restore_page.dart';
import 'package:flutter_wasilah_app/features/backup/providers/backup_controller.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';

void main() {
  Future<void> restoreFailingWith(WidgetTester tester, Object error) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupControllerProvider.overrideWith(
            () => _FakeBackupController(error),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RestorePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pulihkan'));
    await tester.pumpAndSettle();
  }

  testWidgets('explains a backup from a newer app version', (tester) async {
    await restoreFailingWith(
      tester,
      const IncompatibleBackupVersionException(),
    );

    expect(
      find.text(
        'Backup ini dibuat versi aplikasi yang lebih baru. '
        'Perbarui aplikasi dulu.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('explains a backup too old to migrate', (tester) async {
    await restoreFailingWith(tester, const OutdatedBackupVersionException());

    expect(
      find.text(
        'Backup ini terlalu lama dan tidak bisa dipulihkan lagi. '
        'Pilih backup yang lebih baru.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('explains a corrupted backup that was rolled back', (
    tester,
  ) async {
    await restoreFailingWith(
      tester,
      const RestoreVerificationFailedException(),
    );

    expect(
      find.text('File backup rusak. Data sebelumnya sudah dikembalikan.'),
      findsOneWidget,
    );
  });

  testWidgets('explains a restore that is already running', (tester) async {
    await restoreFailingWith(tester, const RestoreInProgressException());

    expect(
      find.text(
        'Backup atau pemulihan sedang berjalan. Tunggu sampai selesai.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('blocks the list with a progress overlay while restoring', (
    tester,
  ) async {
    final controller = _PendingBackupController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backupControllerProvider.overrideWith(() => controller)],
        child: const MaterialApp(
          locale: Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RestorePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pulihkan'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sedang memulihkan data...'), findsOneWidget);
    expect(tester.widget<ListTile>(find.byType(ListTile)).enabled, isFalse);

    controller.finish();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('falls back to a generic message', (tester) async {
    await restoreFailingWith(tester, StateError('boom'));

    expect(find.text('Pemulihan gagal. Coba lagi.'), findsOneWidget);
  });
}

class _FakeBackupController extends BackupController {
  _FakeBackupController(this._restoreError);

  final Object _restoreError;

  @override
  BackupState build() =>
      const BackupState(connectionStatus: BackupConnectionStatus.connected);

  @override
  Future<List<DriveBackupFile>> listBackups() async => [
    DriveBackupFile(
      id: 'backup-1',
      name: 'wasilah.sqlite',
      createdAt: DateTime(2026, 9, 20),
      sizeBytes: 2048,
    ),
  ];

  @override
  Future<void> restore(String fileId) => Future.error(_restoreError);
}

class _PendingBackupController extends BackupController {
  final _completer = Completer<void>();

  @override
  BackupState build() =>
      const BackupState(connectionStatus: BackupConnectionStatus.connected);

  @override
  Future<List<DriveBackupFile>> listBackups() async => [
    DriveBackupFile(
      id: 'backup-1',
      name: 'wasilah.sqlite',
      createdAt: DateTime(2026, 9, 20),
      sizeBytes: 2048,
    ),
  ];

  @override
  Future<void> restore(String fileId) async {
    state = state.copyWith(isRestoring: true);
    try {
      await _completer.future;
    } finally {
      state = state.copyWith(isRestoring: false);
    }
  }

  // Gagal supaya halaman tetap terbuka (sukses menutupnya).
  void finish() => _completer.completeError(StateError('stop'));
}
