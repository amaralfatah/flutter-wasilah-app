import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'portfolio_summary.freezed.dart';

@freezed
abstract class PortfolioSummary with _$PortfolioSummary {
  const factory PortfolioSummary({
    required double totalValue,
    required double monthlyChangePercentage,
    required double targetProgressPercentage,
    required List<Asset> assets,
    required DateTime lastUpdatedAt,
  }) = _PortfolioSummary;
  const PortfolioSummary._();

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioSummary(
      totalValue: (json['totalValue'] as num).toDouble(),
      monthlyChangePercentage: (json['monthlyChangePercentage'] as num)
          .toDouble(),
      targetProgressPercentage: (json['targetProgressPercentage'] as num)
          .toDouble(),
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
}
