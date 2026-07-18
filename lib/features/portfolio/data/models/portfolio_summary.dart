import 'package:flutter/foundation.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset.dart';

@immutable
class PortfolioSummary {
  const PortfolioSummary({
    required this.totalValue,
    required this.monthlyChangePercentage,
    required this.targetProgressPercentage,
    required this.assets,
    required this.lastUpdatedAt,
  });

  final double totalValue;
  final double monthlyChangePercentage;
  final double targetProgressPercentage;
  final List<Asset> assets;
  final DateTime lastUpdatedAt;

  PortfolioSummary copyWith({
    double? totalValue,
    double? monthlyChangePercentage,
    double? targetProgressPercentage,
    List<Asset>? assets,
    DateTime? lastUpdatedAt,
  }) {
    return PortfolioSummary(
      totalValue: totalValue ?? this.totalValue,
      monthlyChangePercentage:
          monthlyChangePercentage ?? this.monthlyChangePercentage,
      targetProgressPercentage:
          targetProgressPercentage ?? this.targetProgressPercentage,
      assets: assets ?? this.assets,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioSummary(
      totalValue: (json['totalValue'] as num).toDouble(),
      monthlyChangePercentage:
          (json['monthlyChangePercentage'] as num).toDouble(),
      targetProgressPercentage:
          (json['targetProgressPercentage'] as num).toDouble(),
      assets: (json['assets'] as List<dynamic>)
          .map((item) => Asset.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalValue': totalValue,
      'monthlyChangePercentage': monthlyChangePercentage,
      'targetProgressPercentage': targetProgressPercentage,
      'assets': assets.map((asset) => asset.toJson()).toList(growable: false),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PortfolioSummary &&
            runtimeType == other.runtimeType &&
            totalValue == other.totalValue &&
            monthlyChangePercentage == other.monthlyChangePercentage &&
            targetProgressPercentage == other.targetProgressPercentage &&
            listEquals(assets, other.assets) &&
            lastUpdatedAt == other.lastUpdatedAt;
  }

  @override
  int get hashCode => Object.hash(
        totalValue,
        monthlyChangePercentage,
        targetProgressPercentage,
        Object.hashAll(assets),
        lastUpdatedAt,
      );
}
