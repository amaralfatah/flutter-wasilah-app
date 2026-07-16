import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/app/theme/app_colors.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';

enum TargetStatus { onTrack, below, above }

class TargetAllocationData {
  const TargetAllocationData({
    required this.id,
    required this.category,
    required this.targetPercentage,
    required this.actualPercentage,
    required this.status,
  });

  final String id;
  final AssetCategory category;
  final double targetPercentage;
  final double actualPercentage;
  final TargetStatus status;
  double get differencePercentage => actualPercentage - targetPercentage;

  String get statusLabel {
    switch (status) {
      case TargetStatus.onTrack:
        return 'Sesuai target';
      case TargetStatus.below:
        return 'Di bawah target';
      case TargetStatus.above:
        return 'Di atas target';
    }
  }

  Color get statusColor {
    switch (status) {
      case TargetStatus.onTrack:
        return AppColors.positive;
      case TargetStatus.below:
        return AppColors.warning;
      case TargetStatus.above:
        return AppColors.negative;
    }
  }
}

final targetAllocationItemsProvider =
    FutureProvider<List<TargetAllocationData>>((ref) async {
      final targets = await ref.watch(allocationTargetProvider.future);
      final summary = await ref.watch(portfolioSummaryProvider.future);
      final actualByCategory = <AssetCategory, double>{};

      for (final asset in summary.assets) {
        actualByCategory.update(
          asset.category,
          (value) => value + asset.allocationPercentage,
          ifAbsent: () => asset.allocationPercentage,
        );
      }

      return targets
          .map((target) {
            final actual = actualByCategory[target.category] ?? 0;
            final difference = actual - target.targetPercentage;

            return TargetAllocationData(
              id: target.id,
              category: target.category,
              targetPercentage: target.targetPercentage,
              actualPercentage: actual,
              status: difference.abs() <= 1
                  ? TargetStatus.onTrack
                  : difference < 0
                  ? TargetStatus.below
                  : TargetStatus.above,
            );
          })
          .toList(growable: false);
    });
