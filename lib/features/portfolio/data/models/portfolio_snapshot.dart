import 'package:flutter_wasilah_app/features/portfolio/data/models/value_snapshot.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'portfolio_snapshot.freezed.dart';

/// Satu titik histori bulanan portofolio gabungan (bukan per aset -- lihat
/// `AssetSnapshot` untuk itu). Menggantikan baris sentinel
/// `asset_id = 'portfolio'` yang dulu numpang di `asset_snapshots`.
@freezed
abstract class PortfolioSnapshot
    with _$PortfolioSnapshot
    implements ValueSnapshot {
  const factory PortfolioSnapshot({
    required String id,
    required double totalValue,
    required DateTime recordedAt,
    String? note,

    /// Total modal gabungan per tanggal pencatatan; `null` bila belum ada
    /// satu aset pun yang punya modal.
    double? totalCost,
  }) = _PortfolioSnapshot;
  const PortfolioSnapshot._();

  factory PortfolioSnapshot.fromJson(Map<String, dynamic> json) {
    return PortfolioSnapshot(
      id: json['id'] as String,
      totalValue: (json['totalValue'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      note: json['note'] as String?,
      totalCost: (json['totalCost'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'totalValue': totalValue,
      'recordedAt': recordedAt.toIso8601String(),
      'note': note,
      'totalCost': totalCost,
    };
  }

  /// Untung/rugi terhadap [totalCost]; `null` bila modal belum diisi.
  @override
  double? get profitLoss {
    final cost = totalCost;
    return cost == null ? null : totalValue - cost;
  }

  /// [profitLoss] dalam persen modal; `null` bila modal kosong atau nol.
  @override
  double? get profitLossPercentage {
    final cost = totalCost;
    if (cost == null || cost == 0) {
      return null;
    }
    return (totalValue - cost) / cost * 100;
  }
}
