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
