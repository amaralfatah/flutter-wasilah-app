import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/backup/data/drive_backup_service.dart';

void main() {
  group('backupIdsToDelete', () {
    test('keeps the newest N backups and returns the rest for deletion', () {
      final backups = [
        DriveBackupFile(
          id: 'oldest',
          name: 'a',
          createdAt: DateTime(2026),
          sizeBytes: 10,
        ),
        DriveBackupFile(
          id: 'newest',
          name: 'b',
          createdAt: DateTime(2026, 3),
          sizeBytes: 10,
        ),
        DriveBackupFile(
          id: 'middle',
          name: 'c',
          createdAt: DateTime(2026, 2),
          sizeBytes: 10,
        ),
      ];

      final idsToDelete = backupIdsToDelete(backups, keep: 2);

      expect(idsToDelete, ['oldest']);
    });

    test('returns nothing to delete when within the keep limit', () {
      final backups = [
        DriveBackupFile(
          id: 'only',
          name: 'a',
          createdAt: DateTime(2026),
          sizeBytes: 10,
        ),
      ];

      expect(backupIdsToDelete(backups, keep: 7), isEmpty);
    });
  });
}
