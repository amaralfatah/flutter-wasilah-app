import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/backup/data/drive_backup_service.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

  group('DriveBackupService.download', () {
    test('removes the partial file when the stream breaks', () async {
      final directory = Directory.systemTemp.createTempSync('wasilah_dl_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final destination = File('${directory.path}/restore.sqlite');
      final client = MockClient.streaming((request, _) async {
        final controller = StreamController<List<int>>();
        unawaited(() async {
          controller.add([1, 2, 3]);
          await Future<void>.delayed(Duration.zero);
          controller.addError(const SocketException('connection reset'));
          await controller.close();
        }());
        return http.StreamedResponse(
          controller.stream,
          200,
          headers: {'content-type': 'application/octet-stream'},
        );
      });
      final service = DriveBackupService(drive.DriveApi(client));

      await expectLater(
        service.download('id', destination),
        throwsA(isA<SocketException>()),
      );
      expect(destination.existsSync(), isFalse);
    });
  });
}
