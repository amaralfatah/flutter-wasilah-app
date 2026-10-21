import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';

/// Rebalancing band per the industry "5/25 rule" (Swedroe): drift is
/// acceptable up to the lesser of 5 percentage points absolute or 25%
/// relative to the target, so small targets get a proportionally fair band.
double _rebalanceTolerance(double targetPercentage) {
  const absoluteBand = 5.0;
  final relativeBand = targetPercentage * 0.25;
  return relativeBand < absoluteBand ? relativeBand : absoluteBand;
}

enum TargetStatus { onTrack, below, above }

class TargetAllocationData {
  const TargetAllocationData({
    required this.id,
    required this.category,
    required this.targetPercentage,
    required this.actualPercentage,
    required this.targetValue,
    required this.actualValue,
    required this.portfolioValue,
    required this.status,
  });

  final String id;
  final AssetCategory category;
  final double targetPercentage;
  final double actualPercentage;
  final double targetValue;
  final double actualValue;

  /// Total nilai portofolio, basis konversi persen ke rupiah.
  final double portfolioValue;
  final TargetStatus status;
  double get differencePercentage => actualPercentage - targetPercentage;

  /// Positif = kelebihan dari target, negatif = kekurangan.
  double get differenceValue => actualValue - targetValue;

  double get tolerance => _rebalanceTolerance(targetPercentage);
  double get lowerBound => (targetPercentage - tolerance).clamp(0, 100);
  double get upperBound => (targetPercentage + tolerance).clamp(0, 100);
  double get lowerBoundValue => portfolioValue * lowerBound / 100;
  double get upperBoundValue => portfolioValue * upperBound / 100;

  Color statusColor(BuildContext context) {
    switch (status) {
      case TargetStatus.onTrack:
        return AppColors.positiveOf(context);
      // Seperti angka lain di Stockbit: warna mengikuti tanda selisih.
      case TargetStatus.below:
        return AppColors.negativeOf(context);
      case TargetStatus.above:
        return AppColors.positiveOf(context);
    }
  }
}

final targetAllocationItemsProvider =
    FutureProvider<List<TargetAllocationData>>((ref) async {
      final targets = await ref.watch(allocationTargetProvider.future);
      final summary = await ref.watch(portfolioSummaryProvider.future);
      final actualByCategory = <AssetCategory, double>{};
      final actualValueByCategory = <AssetCategory, double>{};

      for (final asset in summary.positions) {
        actualByCategory.update(
          asset.category,
          (value) => value + asset.allocationPercentage,
          ifAbsent: () => asset.allocationPercentage,
        );
        actualValueByCategory.update(
          asset.category,
          (value) => value + asset.currentValue,
          ifAbsent: () => asset.currentValue,
        );
      }

      return targets
          .map((target) {
            final actual = actualByCategory[target.category] ?? 0;
            final actualValue = actualValueByCategory[target.category] ?? 0;
            final targetValue =
                summary.totalValue * (target.targetPercentage / 100);
            final difference = actual - target.targetPercentage;

            return TargetAllocationData(
              id: target.id,
              category: target.category,
              targetPercentage: target.targetPercentage,
              actualPercentage: actual,
              targetValue: targetValue,
              actualValue: actualValue,
              portfolioValue: summary.totalValue,
              status:
                  difference.abs() <=
                      _rebalanceTolerance(target.targetPercentage)
                  ? TargetStatus.onTrack
                  : difference < 0
                  ? TargetStatus.below
                  : TargetStatus.above,
            );
          })
          .toList(growable: false);
    });
