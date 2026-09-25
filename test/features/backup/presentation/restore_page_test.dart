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
