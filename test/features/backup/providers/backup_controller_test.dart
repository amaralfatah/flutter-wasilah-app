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
