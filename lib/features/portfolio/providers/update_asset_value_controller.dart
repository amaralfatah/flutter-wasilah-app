import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/core/utils/validators.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';

final updateAssetValueControllerProvider =
    AsyncNotifierProvider<UpdateAssetValueController, void>(
      UpdateAssetValueController.new,
    );

class UpdateAssetValueController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required String assetId,
    required double totalValue,
    required DateTime recordedAt,
    String? note,
    double? totalCost,
    double? quantity,
    double? avgBuyPrice,
    String? priceCurrency,
  }) async {
    final assetError = validateSelectedAsset(assetId);
    if (assetError != null) {
      throw ArgumentError(assetError);
    }

    if (totalValue < 0) {
      throw const InvalidCurrentValueException();
    }

    if (totalCost != null && totalCost < 0) {
      throw const InvalidTotalCostException();
    }

    final noteError = validateNote(note);
    if (noteError != null) {
      throw ArgumentError(noteError);
    }

    state = const AsyncLoading();

    try {
      await ref
          .read(portfolioRepositoryProvider)
          .updateAssetValue(
            assetId: assetId,
            totalValue: totalValue,
            recordedAt: recordedAt,
            note: note?.trim().isEmpty ?? true ? null : note?.trim(),
            totalCost: totalCost,
            quantity: quantity,
            avgBuyPrice: avgBuyPrice,
            priceCurrency: priceCurrency,
          );

      ref.invalidate(portfolioSummaryProvider);
      ref.invalidate(assetListProvider);
      ref.invalidate(portfolioHistoryProvider);
      ref.invalidate(assetDetailProvider(assetId));
      ref.invalidate(assetHistoryProvider(assetId));

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
