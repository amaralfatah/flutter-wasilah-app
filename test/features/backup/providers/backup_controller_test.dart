import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/core/errors/error_reporter.dart';
import 'package:flutter_wasilah_app/core/storage/preferences_service.dart';
import 'package:flutter_wasilah_app/features/backup/data/google_auth_service.dart';
import 'package:flutter_wasilah_app/features/backup/providers/backup_controller.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

    test('missing Drive authorization is shown but not reported', () async {
      final (container, reporter) = await createContainer(() async => null);

      await container.read(backupControllerProvider.notifier).maybeAutoBackup();

      final state = container.read(backupControllerProvider);
      expect(state.error, isA<GoogleAuthorizationRequiredException>());
      expect(reporter.reasons, isEmpty);
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
  _FakeAuth(this._authorize);

  final Future<http.Client?> Function() _authorize;

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
