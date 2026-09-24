import 'package:freezed_annotation/freezed_annotation.dart';

part 'asset_snapshot.freezed.dart';

@freezed
abstract class AssetSnapshot with _$AssetSnapshot {
  const factory AssetSnapshot({
    required String id,
    required String assetId,
    required double totalValue,
    required DateTime recordedAt,
    String? note,

    /// Total modal per tanggal pencatatan; `null` bila belum diisi.
    double? totalCost,
  }) = _AssetSnapshot;
  const AssetSnapshot._();

  factory AssetSnapshot.fromJson(Map<String, dynamic> json) {
    return AssetSnapshot(
      id: json['id'] as String,
      assetId: json['assetId'] as String,
      totalValue: (json['totalValue'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      note: json['note'] as String?,
      totalCost: (json['totalCost'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetId': assetId,
      'totalValue': totalValue,
      'recordedAt': recordedAt.toIso8601String(),
      'note': note,
      'totalCost': totalCost,
    };
  }

  /// Untung/rugi terhadap [totalCost]; `null` bila modal belum diisi.
  double? get profitLoss {
    final cost = totalCost;
    return cost == null ? null : totalValue - cost;
  }

  /// [profitLoss] dalam persen modal; `null` bila modal kosong atau nol.
  double? get profitLossPercentage {
    final cost = totalCost;
    if (cost == null || cost == 0) {
      return null;
    }
    return (totalValue - cost) / cost * 100;
  }
}
