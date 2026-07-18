import 'package:flutter/foundation.dart';

@immutable
class AssetSnapshot {
  const AssetSnapshot({
    required this.id,
    required this.assetId,
    required this.totalValue,
    required this.recordedAt,
    this.note,
  });

  final String id;
  final String assetId;
  final double totalValue;
  final DateTime recordedAt;
  final String? note;

  AssetSnapshot copyWith({
    String? id,
    String? assetId,
    double? totalValue,
    DateTime? recordedAt,
    String? note,
  }) {
    return AssetSnapshot(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      totalValue: totalValue ?? this.totalValue,
      recordedAt: recordedAt ?? this.recordedAt,
      note: note ?? this.note,
    );
  }

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

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AssetSnapshot &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            assetId == other.assetId &&
            totalValue == other.totalValue &&
            recordedAt == other.recordedAt &&
            note == other.note;
  }

  @override
  int get hashCode => Object.hash(id, assetId, totalValue, recordedAt, note);
}
