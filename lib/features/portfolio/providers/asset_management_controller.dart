import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/utils/validators.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';

final assetManagementControllerProvider =
    AsyncNotifierProvider<AssetManagementController, void>(
      AssetManagementController.new,
    );

class AssetManagementController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> createAsset({
    required String name,
    required String code,
    required AssetCategory category,
    required double currentValue,
    required DateTime recordedAt,
  }) async {
    _validateAssetFields(name: name, code: code, currentValue: currentValue);
    state = const AsyncLoading();

    try {
      await ref
          .read(portfolioRepositoryProvider)
          .createAsset(
            Asset(
              id: _buildAssetId(code.isEmpty ? name : code),
              name: name.trim(),
              code: code.trim().toUpperCase(),
              category: category,
              currentValue: currentValue,
              allocationPercentage: 0,
              lastUpdatedAt: recordedAt,
            ),
          );
      _invalidateAssetReads();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateAsset(Asset asset) async {
    _validateAssetFields(
      name: asset.name,
      code: asset.code,
      currentValue: asset.currentValue,
    );
    state = const AsyncLoading();

    try {
      await ref
          .read(portfolioRepositoryProvider)
          .updateAsset(
            asset.copyWith(
              name: asset.name.trim(),
              code: asset.code.trim().toUpperCase(),
            ),
          );
      _invalidateAssetReads(asset.id);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteAsset(String assetId) async {
    state = const AsyncLoading();

    try {
      await ref.read(portfolioRepositoryProvider).deleteAsset(assetId);
      _invalidateAssetReads(assetId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  void _validateAssetFields({
    required String name,
    required String code,
    required double currentValue,
  }) {
    final nameError = validateRequiredText(
      name,
      message: 'Nama aset wajib diisi.',
    );
    if (nameError != null) {
      throw ArgumentError(nameError);
    }

    final codeError = validateRequiredText(
      code,
      message: 'Kode aset wajib diisi.',
    );
    if (codeError != null) {
      throw ArgumentError(codeError);
    }

    if (currentValue < 0) {
      throw ArgumentError('Nilai aset tidak boleh kurang dari nol.');
    }
  }

  void _invalidateAssetReads([String? assetId]) {
    ref.invalidate(assetListProvider);
    ref.invalidate(portfolioSummaryProvider);
    ref.invalidate(portfolioHistoryProvider);
    if (assetId != null) {
      ref.invalidate(assetDetailProvider(assetId));
      ref.invalidate(assetHistoryProvider(assetId));
    }
  }
}

String _buildAssetId(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final prefix = normalized.isEmpty ? 'asset' : normalized;
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
}
