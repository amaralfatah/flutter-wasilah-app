import 'package:flutter/foundation.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset.dart';

@immutable
class AllocationTarget {
  const AllocationTarget({
    required this.id,
    required this.category,
    required this.targetPercentage,
  });

  final String id;
  final AssetCategory category;
  final double targetPercentage;

  AllocationTarget copyWith({
    String? id,
    AssetCategory? category,
    double? targetPercentage,
  }) {
    return AllocationTarget(
      id: id ?? this.id,
      category: category ?? this.category,
      targetPercentage: targetPercentage ?? this.targetPercentage,
    );
  }

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

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AllocationTarget &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            category == other.category &&
            targetPercentage == other.targetPercentage;
  }

  @override
  int get hashCode => Object.hash(id, category, targetPercentage);
}
