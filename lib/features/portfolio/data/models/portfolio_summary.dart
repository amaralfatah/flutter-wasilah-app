import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'portfolio_summary.freezed.dart';

@freezed
abstract class PortfolioSummary with _$PortfolioSummary {
  const factory PortfolioSummary({
    required double totalValue,
    required double monthlyChangePercentage,
    required double targetProgressPercentage,
    required List<PortfolioPosition> positions,
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
      positions: (json['positions'] as List<dynamic>)
          .map(
            (item) => PortfolioPosition.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalValue': totalValue,
      'monthlyChangePercentage': monthlyChangePercentage,
      'targetProgressPercentage': targetProgressPercentage,
      'positions': positions
          .map((position) => position.toJson())
          .toList(growable: false),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }
}
