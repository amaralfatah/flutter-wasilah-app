import 'package:flutter_wasilah_app/features/portfolio/data/models/asset_snapshot.dart';

/// Nilai aset per [date] dari [history] (snapshot bulanan): snapshot
/// terakhir di bulan [date] atau sebelumnya. Snapshot bulan [date] ikut
/// dihitung walau tanggalnya setelah [date], karena satu bulan hanya punya
/// satu snapshot dan update di bulan itu menimpanya. `0` bila belum ada
/// snapshot sampai bulan itu.
double valueAsOf(List<AssetSnapshot> history, DateTime date) {
  AssetSnapshot? latest;
  for (final snapshot in history) {
    final recordedAt = snapshot.recordedAt;
    final isOnOrBefore =
        recordedAt.year < date.year ||
        (recordedAt.year == date.year && recordedAt.month <= date.month);
    if (isOnOrBefore &&
        (latest == null || recordedAt.isAfter(latest.recordedAt))) {
      latest = snapshot;
    }
  }
  return latest?.totalValue ?? 0;
}
