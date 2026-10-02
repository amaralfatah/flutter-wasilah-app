import 'package:flutter_wasilah_app/features/portfolio/data/models/allocation_target.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
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

  /// Ringkasan dari [positions] dan [targets]: total, progres target, dan
  /// waktu update terakhir dihitung di sini supaya repository dan provider
  /// (yang memakai nilai pasar) tidak menghitungnya masing-masing.
  factory PortfolioSummary.fromPositions(
    List<PortfolioPosition> positions,
    List<AllocationTarget> targets, {
    double monthlyChangePercentage = 0,
  }) {
    return PortfolioSummary(
      totalValue: positions.fold<double>(
        0,
        (sum, position) => sum + position.currentValue,
      ),
      monthlyChangePercentage: monthlyChangePercentage,
      targetProgressPercentage: calculateTargetProgress(positions, targets),
      positions: positions,
      lastUpdatedAt: positions.isEmpty
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : positions
                .map((position) => position.lastUpdatedAt)
                .reduce((latest, next) => latest.isAfter(next) ? latest : next),
    );
  }

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

/// Seberapa dekat alokasi aktual per kategori dengan [targets], 0-100:
/// 100 dikurangi separuh total selisih persentase.
double calculateTargetProgress(
  List<PortfolioPosition> positions,
  List<AllocationTarget> targets,
) {
  if (positions.isEmpty || targets.isEmpty) {
    return 0;
  }

  final actualByCategory = <AssetCategory, double>{};
  for (final position in positions) {
    actualByCategory.update(
      position.category,
      (value) => value + position.allocationPercentage,
      ifAbsent: () => position.allocationPercentage,
    );
  }

  var totalDifference = 0.0;
  for (final target in targets) {
    totalDifference +=
        ((actualByCategory[target.category] ?? 0) - target.targetPercentage)
            .abs();
  }

  return (100 - (totalDifference / 2)).clamp(0, 100).toDouble();
}
