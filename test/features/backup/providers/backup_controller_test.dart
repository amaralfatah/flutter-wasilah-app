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
