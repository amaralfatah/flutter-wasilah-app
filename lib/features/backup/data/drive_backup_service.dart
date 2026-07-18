import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;

class DriveBackupFile {
  const DriveBackupFile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.sizeBytes,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final int sizeBytes;
}

class DriveBackupService {
  DriveBackupService(this._driveApi);

  static const int maxBackupsToKeep = 7;
  static const String _fileFields = 'id,name,createdTime,size';

  final drive.DriveApi _driveApi;

  Future<DriveBackupFile> upload(File snapshotFile) async {
    final metadata = drive.File()
      ..name = p.basename(snapshotFile.path)
      ..parents = ['appDataFolder'];
    final media = drive.Media(
      snapshotFile.openRead(),
      snapshotFile.lengthSync(),
    );

    final created = await _driveApi.files.create(
      metadata,
      uploadMedia: media,
      $fields: _fileFields,
    );

    return _toBackupFile(created);
  }

  Future<List<DriveBackupFile>> listBackups() async {
    final result = await _driveApi.files.list(
      spaces: 'appDataFolder',
      orderBy: 'createdTime desc',
      pageSize: 100,
      $fields: 'files($_fileFields)',
    );

    return (result.files ?? const <drive.File>[])
        .map(_toBackupFile)
        .toList();
  }

  Future<void> deleteBackup(String fileId) {
    return _driveApi.files.delete(fileId);
  }

  Future<File> download(String fileId, File destination) async {
    final media =
        await _driveApi.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final sink = destination.openWrite();
    await media.stream.pipe(sink);
    await sink.close();

    return destination;
  }

  Future<void> pruneOldBackups() async {
    final backups = await listBackups();
    final idsToDelete = backupIdsToDelete(backups, keep: maxBackupsToKeep);
    for (final id in idsToDelete) {
      await deleteBackup(id);
    }
  }

  DriveBackupFile _toBackupFile(drive.File file) {
    return DriveBackupFile(
      id: file.id!,
      name: file.name ?? 'backup',
      createdAt: (file.createdTime ?? DateTime.now()).toLocal(),
      sizeBytes: int.tryParse(file.size ?? '0') ?? 0,
    );
  }
}

List<String> backupIdsToDelete(
  List<DriveBackupFile> backups, {
  required int keep,
}) {
  final sorted = [...backups]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  if (sorted.length <= keep) {
    return const [];
  }
  return sorted.sublist(keep).map((backup) => backup.id).toList();
}
