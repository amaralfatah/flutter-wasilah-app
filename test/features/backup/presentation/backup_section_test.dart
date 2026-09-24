import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/backup/presentation/widgets/backup_section.dart';
import 'package:flutter_wasilah_app/features/backup/providers/backup_controller.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';

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
            locale: Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
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
            locale: Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: BackupSection()),
          ),
        ),
      );

      expect(find.text('user@gmail.com'), findsOneWidget);
      expect(find.text('Backup sekarang'), findsOneWidget);
      expect(find.textContaining('17 Juli 2026'), findsOneWidget);
      expect(find.text('Bagikan file backup'), findsNothing);
    });

    testWidgets('asks for confirmation before backing up', (tester) async {
      await tester.pumpWidget(_connectedSection());

      await tester.tap(find.text('Backup sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Backup sekarang?'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Backup sekarang?'), findsNothing);
    });

    testWidgets('asks for confirmation before disconnecting', (tester) async {
      await tester.pumpWidget(_connectedSection());

      await tester.tap(find.text('Putuskan'));
      await tester.pumpAndSettle();

      expect(find.text('Putuskan akun Google?'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Putuskan akun Google?'), findsNothing);
    });
  });
}

Widget _connectedSection() {
  return ProviderScope(
    overrides: [
      backupControllerProvider.overrideWith(
        () => _FakeBackupController(
          const BackupState(
            connectionStatus: BackupConnectionStatus.connected,
            accountEmail: 'user@gmail.com',
          ),
        ),
      ),
    ],
    child: const MaterialApp(
      locale: Locale('id'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: BackupSection()),
    ),
  );
}

class _FakeBackupController extends BackupController {
  _FakeBackupController(this._initialState);

  final BackupState _initialState;

  @override
  BackupState build() => _initialState;
}
