import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/core/utils/validators.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/market_valuation.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/purchase_math.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/portfolio_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/sale_math.dart';
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
    String? fxCurrency,
    double? fxRate,
    bool clearQuantity = false,
    bool clearAvgBuyPrice = false,
  }) async {
    if (checkSelectedAsset(assetId) case final failure?) {
      throw ValidationException(failure);
    }

    if (totalValue < 0) {
      throw const InvalidCurrentValueException();
    }

    if (totalCost != null && totalCost < 0) {
      throw const InvalidTotalCostException();
    }

    if (checkNote(note) case final failure?) {
      throw ValidationException(failure);
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
            fxCurrency: fxCurrency,
            fxRate: fxRate,
            clearQuantity: clearQuantity,
            clearAvgBuyPrice: clearAvgBuyPrice,
          );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Mencatat satu pembelian [position] pada [recordedAt]: jumlah unit, avg,
  /// dan modal dihitung ulang dengan [applyPurchase]. Nilai posisi yang
  /// dinilai harga pasar diskalakan ke jumlah unit baru (harga per unit
  /// sama); selain itu bertambah sebesar yang dibayar. [paid] dalam mata
  /// uang harga beli aset, dan catatan bulan itu dipertahankan.
  Future<void> recordPurchase({
    required PortfolioPosition position,
    required double boughtQuantity,
    required double paid,
    required double rateToIdr,
    required DateTime recordedAt,
  }) async {
    final result = applyPurchase(
      quantity: position.quantity,
      avgBuyPrice: position.avgBuyPrice,
      totalCost: position.totalCost,
      boughtQuantity: boughtQuantity,
      paid: paid,
      rateToIdr: rateToIdr,
      lotFactor: lotToShareFactor(position.marketSymbol),
    );
    if (result == null) {
      throw const InvalidPurchaseException();
    }

    state = const AsyncLoading();

    try {
      final repository = ref.read(portfolioRepositoryProvider);
      final monthNote = await _monthNote(position.id, recordedAt);
      final currency = position.effectivePriceCurrency;
      final oldQuantity = position.quantity;
      final totalValue =
          position.isMarketValued && oldQuantity != null && oldQuantity > 0
          ? position.currentValue / oldQuantity * result.quantity
          : position.currentValue + paid * rateToIdr;
      await repository.updateAssetValue(
        assetId: position.id,
        totalValue: totalValue,
        recordedAt: recordedAt,
        note: monthNote,
        totalCost: result.totalCost,
        quantity: result.quantity,
        avgBuyPrice: result.avgBuyPrice,
        priceCurrency: currency,
        fxCurrency: currency == 'IDR' ? null : currency,
        fxRate: currency == 'IDR' ? null : rateToIdr,
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Mencatat satu penjualan: jumlah unit dan modal berkurang proporsional
  /// (lihat [applySale]), nilai ikut porsi unit yang tersisa. Jual semua
  /// membuat nilainya 0 sehingga holding pindah ke "Aset nonaktif".
  Future<void> recordSale({
    required PortfolioPosition position,
    required double soldQuantity,
    required double received,
    required double rateToIdr,
    required DateTime recordedAt,
  }) async {
    final oldQuantity = position.quantity;
    final result = applySale(
      quantity: oldQuantity,
      avgBuyPrice: position.avgBuyPrice,
      totalCost: position.totalCost,
      soldQuantity: soldQuantity,
      received: received,
      rateToIdr: rateToIdr,
      lotFactor: lotToShareFactor(position.marketSymbol),
    );
    if (result == null || oldQuantity == null) {
      throw const InvalidSaleException();
    }

    state = const AsyncLoading();

    try {
      final repository = ref.read(portfolioRepositoryProvider);
      final monthNote = await _monthNote(position.id, recordedAt);
      final currency = position.effectivePriceCurrency;
      await repository.updateAssetValue(
        assetId: position.id,
        totalValue: position.currentValue / oldQuantity * result.quantity,
        recordedAt: recordedAt,
        note: monthNote,
        totalCost: result.totalCost,
        quantity: result.quantity,
        // Harga rata-rata tidak berubah oleh penjualan; ditulis ulang supaya
        // posisi tersimpan tetap lengkap.
        avgBuyPrice: position.avgBuyPrice,
        priceCurrency: currency,
        fxCurrency: currency == 'IDR' ? null : currency,
        fxRate: currency == 'IDR' ? null : rateToIdr,
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Catatan snapshot bulan [recordedAt], supaya pencatatan beli/jual tidak
  /// menghapus catatan yang sudah ditulis untuk bulan itu.
  Future<String?> _monthNote(String assetId, DateTime recordedAt) async {
    final history = await ref
        .read(portfolioRepositoryProvider)
        .getAssetHistory(assetId);
    return history
        .where(
          (snapshot) =>
              snapshot.recordedAt.year == recordedAt.year &&
              snapshot.recordedAt.month == recordedAt.month,
        )
        .firstOrNull
        ?.note;
  }

  /// Mencatat nilai pasar [records] ke histori bulan ini.
  Future<void> recordMarketValues(List<AssetValueRecord> records) async {
    state = const AsyncLoading();

    try {
      await ref
          .read(portfolioRepositoryProvider)
          .recordAssetValues(records, recordedAt: DateTime.now());
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Mengeluarkan aset dari portofolio; master aset tetap ada.
  Future<void> removeFromPortfolio(String assetId) async {
    state = const AsyncLoading();

    try {
      await ref.read(portfolioRepositoryProvider).removeFromPortfolio(assetId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
