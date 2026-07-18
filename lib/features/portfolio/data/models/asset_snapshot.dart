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
  }) = _AssetSnapshot;
  const AssetSnapshot._();

  factory AssetSnapshot.fromJson(Map<String, dynamic> json) {
    return AssetSnapshot(
      id: json['id'] as String,
      assetId: json['assetId'] as String,
      totalValue: (json['totalValue'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetId': assetId,
      'totalValue': totalValue,
      'recordedAt': recordedAt.toIso8601String(),
      'note': note,
    };
  }
}
