import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/allocation_target.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/target/providers/target_providers.dart';

final targetManagementControllerProvider =
    AsyncNotifierProvider<TargetManagementController, void>(
      TargetManagementController.new,
    );

class TargetManagementController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> saveTarget({
    required AssetCategory category,
    required double targetPercentage,
    String? id,
  }) async {
    if (targetPercentage < 0 || targetPercentage > 100) {
      throw ArgumentError('Target alokasi harus di antara 0 sampai 100%.');
    }

    final existingTargets = await ref.read(allocationTargetProvider.future);
    final otherTotal = existingTargets
        .where((target) => target.id != id && target.category != category)
        .fold<double>(0, (sum, target) => sum + target.targetPercentage);
    if (otherTotal + targetPercentage > 100) {
      throw ArgumentError('Total target alokasi tidak boleh lebih dari 100%.');
    }

    state = const AsyncLoading();

    try {
      await ref
          .read(portfolioRepositoryProvider)
          .saveAllocationTarget(
            AllocationTarget(
              id: id ?? 'target-${category.name}',
              category: category,
              targetPercentage: targetPercentage,
            ),
          );
      _invalidateTargetReads();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteTarget(String targetId) async {
    state = const AsyncLoading();

    try {
      await ref
          .read(portfolioRepositoryProvider)
          .deleteAllocationTarget(targetId);
      _invalidateTargetReads();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  void _invalidateTargetReads() {
    ref.invalidate(allocationTargetProvider);
    ref.invalidate(portfolioSummaryProvider);
    ref.invalidate(targetAllocationItemsProvider);
  }
}
