import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'allocation_target.freezed.dart';

@freezed
abstract class AllocationTarget with _$AllocationTarget {
  const factory AllocationTarget({
    required String id,
    required AssetCategory category,
    required double targetPercentage,
  }) = _AllocationTarget;
  const AllocationTarget._();

  factory AllocationTarget.fromJson(Map<String, dynamic> json) {
    return AllocationTarget(
      id: json['id'] as String,
      category: AssetCategory.values.byName(json['category'] as String),
      targetPercentage: (json['targetPercentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.name,
      'targetPercentage': targetPercentage,
    };
  }
}
