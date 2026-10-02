import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/utils/validators.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:uuid/uuid.dart';

final assetManagementControllerProvider =
    AsyncNotifierProvider<AssetManagementController, void>(
      AssetManagementController.new,
    );

class AssetManagementController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Membuat master aset baru dan mengembalikan id-nya. Nilai porto diisi
  /// terpisah lewat update nilai.
  Future<String> createAsset({
    required String name,
    required String code,
    required AssetCategory category,
    String? marketSymbol,
  }) async {
    _validateAssetFields(name: name, code: code);
    state = const AsyncLoading();

    try {
      final assetId = _buildAssetId(code.isEmpty ? name : code);
      await ref
          .read(assetRepositoryProvider)
          .createAsset(
            Asset(
              id: assetId,
              name: name.trim(),
              code: code.trim().toUpperCase(),
              category: category,
              marketSymbol: marketSymbol,
            ),
          );
      state = const AsyncData(null);
      return assetId;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateAsset(Asset asset) async {
    _validateAssetFields(name: asset.name, code: asset.code);
    state = const AsyncLoading();

    try {
      await ref
          .read(assetRepositoryProvider)
          .updateAsset(
            asset.copyWith(
              name: asset.name.trim(),
              code: asset.code.trim().toUpperCase(),
            ),
          );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteAsset(String assetId) async {
    state = const AsyncLoading();

    try {
      await ref.read(assetRepositoryProvider).deleteAsset(assetId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  void _validateAssetFields({required String name, required String code}) {
    if (isBlank(name)) {
      throw const ValidationException(ValidationFailure.assetNameRequired);
    }

    if (isBlank(code)) {
      throw const ValidationException(ValidationFailure.assetCodeRequired);
    }
  }
}

const _uuid = Uuid();

String _buildAssetId(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final prefix = normalized.isEmpty ? 'asset' : normalized;
  return '$prefix-${_uuid.v4()}';
}
