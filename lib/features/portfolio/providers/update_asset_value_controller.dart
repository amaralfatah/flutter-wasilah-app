import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  }) async {
    final assetError = validateSelectedAsset(assetId);
    if (assetError != null) {
      throw ArgumentError(assetError);
    }

    if (totalValue < 0) {
      throw ArgumentError('Nilai aset tidak boleh kurang dari nol.');
    }

    final noteError = validateNote(note);
    if (noteError != null) {
      throw ArgumentError(noteError);
    }

    state = const AsyncLoading();

    try {
      await ref.read(portfolioRepositoryProvider).updateAssetValue(
            assetId: assetId,
            totalValue: totalValue,
            recordedAt: recordedAt,
            note: note?.trim().isEmpty ?? true ? null : note?.trim(),
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
