import 'dart:io';

import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

class BackupSnapshotService {
  const BackupSnapshotService();

  Future<File> createSnapshot(AppDatabase database) async {
    final tempDir = await getTemporaryDirectory();
    final snapshotPath = p.join(
      tempDir.path,
      'wasilah_backup_${DateTime.now().millisecondsSinceEpoch}.sqlite',
    );
    final snapshotFile = File(snapshotPath);
    if (snapshotFile.existsSync()) {
      await snapshotFile.delete();
    }

    final escapedPath = snapshotPath.replaceAll("'", "''");
    await database.customStatement("VACUUM INTO '$escapedPath'");

    return snapshotFile;
  }

  bool isValidSqliteFile(File file) {
    if (!file.existsSync() || file.lengthSync() == 0) {
      return false;
    }

    sqlite3.Database? database;
    try {
      database = sqlite3.sqlite3.open(
        file.path,
        mode: sqlite3.OpenMode.readOnly,
      );
      final result = database.select('PRAGMA integrity_check');
      return result.isNotEmpty && result.first.values.first == 'ok';
    } catch (_) {
      return false;
    } finally {
      database?.dispose();
    }
  }
}
