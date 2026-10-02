import 'dart:io';
import 'dart:math';

/// Salinan pengaman database lama selama restore berlangsung.
File databaseSafetyCopyFile(File databaseFile) =>
    File('${databaseFile.path}.bak');

/// Penanda restore yang belum terverifikasi. Selama file ini ada, isi
/// [databaseFile] belum boleh dianggap sah.
File restoreMarkerFile(File databaseFile) =>
    File('${databaseFile.path}.restoring');

/// Identitas proses ini, ditulis ke penanda restore. Penanda milik proses
/// yang sedang berjalan berarti restore masih berlangsung (mis. verifikasi
/// membuka database baru) — bukan sisa proses yang mati di tengah jalan.
final String _sessionToken =
    '$pid-${DateTime.now().microsecondsSinceEpoch}-'
    '${Random().nextInt(1 << 32)}';

/// Tandai awal pertukaran file database. Ditulis dan di-flush sebelum file
/// lama dipindah, supaya kalau proses mati di tengah jalan, pembukaan
/// berikutnya tahu bahwa isi [databaseFile] belum terverifikasi.
Future<void> beginRestoreSwap(File databaseFile) async {
  await restoreMarkerFile(
    databaseFile,
  ).writeAsString(_sessionToken, flush: true);
}

/// Restore selesai (berhasil atau sudah dikembalikan): hapus penanda.
Future<void> endRestoreSwap(File databaseFile) async {
  final marker = restoreMarkerFile(databaseFile);
  if (marker.existsSync()) {
    await marker.delete();
  }
}

/// Pulihkan database dari restore yang terputus. Dipanggil sebelum file
/// database dibuka.
///
/// - Ada penanda dari proses lain: restore belum terverifikasi saat proses
///   mati. Kembalikan salinan pengaman (kalau ada) ke tempatnya.
/// - Tanpa penanda tapi file utama hilang dan salinan pengaman ada: kembalikan
///   salinan pengaman, daripada membuat database kosong baru.
Future<void> recoverInterruptedRestore(File databaseFile) async {
  final marker = restoreMarkerFile(databaseFile);
  final safetyCopy = databaseSafetyCopyFile(databaseFile);

  if (marker.existsSync()) {
    final owner = await marker.readAsString();
    if (owner == _sessionToken) {
      // Restore di proses ini masih berjalan.
      return;
    }
    if (safetyCopy.existsSync()) {
      if (databaseFile.existsSync()) {
        await databaseFile.delete();
      }
      await safetyCopy.rename(databaseFile.path);
    }
    await marker.delete();
    return;
  }

  if (!databaseFile.existsSync() && safetyCopy.existsSync()) {
    await safetyCopy.rename(databaseFile.path);
  }
}
