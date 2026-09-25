import 'package:flutter_wasilah_app/features/portfolio/data/models/allocation_target.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_summary.dart';

/// Sisi porto: holding, histori, dan target alokasi. Master data aset
/// (nama/kode/kategori/simbol) ada di `AssetRepository`.
abstract interface class PortfolioRepository {
  Future<PortfolioSummary> getPortfolioSummary();

  Future<List<PortfolioPosition>> getPositions();

  Future<PortfolioPosition?> getPositionByAssetId(String assetId);

  Future<List<PortfolioSnapshot>> getPortfolioHistory();

  Future<List<AssetSnapshot>> getAssetHistory(String assetId);

  /// Menghapus satu baris histori per-aset (`asset_snapshots`). Holding &
  /// snapshot portofolio bulan itu disesuaikan dengan histori yang tersisa;
  /// bila tak ada histori tersisa, aset keluar dari portofolio.
  Future<void> deleteAssetSnapshot(String snapshotId);

  /// Menghapus satu baris histori portofolio gabungan
  /// (`portfolio_snapshots`). Independen dari histori per-aset.
  Future<void> deletePortfolioSnapshot(String snapshotId);

  /// Meng-upsert holding aset [assetId]: bila belum punya holding, baris
  /// baru dibuat (mendukung alur tambah aset dua langkah -- buat master
  /// dulu, lalu isi nilainya lewat sini).
  Future<void> updateAssetValue({
    required String assetId,
    required double totalValue,
    required DateTime recordedAt,
    String? note,
    double? totalCost,
    double? quantity,
    double? avgBuyPrice,
    String? priceCurrency,

    /// Kurs konversi ke IDR yang dipakai input ini; disimpan di histori.
    String? fxCurrency,
    double? fxRate,
  });

  /// Mengeluarkan aset dari portofolio: holding dan seluruh histori per-aset
  /// dihapus, master aset tetap ada.
  Future<void> removeFromPortfolio(String assetId);

  Future<List<AllocationTarget>> getAllocationTargets();

  Future<void> saveAllocationTarget(AllocationTarget target);

  Future<void> deleteAllocationTarget(String targetId);

  /// Berbunyi setiap kali data aset/portofolio berubah (termasuk master aset,
  /// karena berbagi database yang sama).
  Stream<void> get changes;
}
