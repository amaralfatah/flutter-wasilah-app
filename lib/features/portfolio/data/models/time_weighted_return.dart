import 'dart:math' as math;

import 'package:flutter_wasilah_app/features/portfolio/data/models/value_snapshot.dart';

/// Time-weighted return dari histori snapshot portofolio bulanan, dalam
/// persen. Mengukur hasil investasi tanpa terpengaruh besar/kecil atau
/// waktu setoran, sehingga cocok untuk menilai kemampuan berinvestasi.
///
/// Setoran bersih tiap bulan dibaca dari selisih modal antar-snapshot, lalu
/// return bulan itu dihitung dengan Modified Dietz (setoran dianggap masuk
/// di tengah bulan, karena tanggal pastinya tidak tercatat) dan dirantai
/// antarbulan.
///
/// [history] boleh urutan apa saja. Bila [year] diisi, hanya bulan yang
/// berakhir di tahun itu yang dirantai — Januari tetap memakai Desember
/// tahun sebelumnya sebagai nilai awal. Mengembalikan `null` bila belum ada
/// satu bulan pun yang bisa dihitung (butuh dua snapshot bermodal).
({double cumulative, double? annualized})? timeWeightedReturn(
  List<ValueSnapshot> history, {
  int? year,
}) {
  final sorted = [...history]
    ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

  var growth = 1.0;
  DateTime? start;
  DateTime? end;
  for (var index = 1; index < sorted.length; index++) {
    final previous = sorted[index - 1];
    final current = sorted[index];
    if (year != null && current.recordedAt.year != year) {
      continue;
    }

    final previousCost = previous.totalCost;
    final currentCost = current.totalCost;
    if (previousCost == null || currentCost == null) {
      continue;
    }

    final flow = currentCost - previousCost;
    final base = previous.totalValue + flow / 2;
    if (base <= 0) {
      continue;
    }

    growth *= 1 + (current.totalValue - previous.totalValue - flow) / base;
    start ??= previous.recordedAt;
    end = current.recordedAt;
  }

  if (start == null || end == null) {
    return null;
  }

  // Disetahunkan hanya bila rentangnya minimal setahun; periode pendek yang
  // disetahunkan membesar-besarkan hasil satu-dua bulan yang kebetulan.
  final days = end.difference(start).inDays;
  final annualized = days < 365 || growth <= 0
      ? null
      : (math.pow(growth, 365 / days).toDouble() - 1) * 100;

  return (cumulative: (growth - 1) * 100, annualized: annualized);
}
