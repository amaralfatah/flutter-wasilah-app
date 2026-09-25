import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/holding.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'portfolio_position.freezed.dart';

/// Gabungan satu [Asset] (master) dengan [Holding]-nya (porto), plus
/// [allocationPercentage] yang dihitung repository saat baca (bukan
/// disimpan). Dipakai di layar yang menampilkan nilai/PnL sebuah
/// kepemilikan, sebagai pengganti `Asset` gabungan lama.
///
/// Getter-getter di bawah meneruskan ke [asset]/[holding] supaya kode UI
/// yang tadinya membaca field gabungan di `Asset` (mis. `position.code`,
/// `position.currentValue`) tetap jalan tanpa perlu tahu field itu kini
/// tersebar di dua model.
@freezed
abstract class PortfolioPosition with _$PortfolioPosition {
  const factory PortfolioPosition({
    required Asset asset,
    required Holding holding,
    required double allocationPercentage,
  }) = _PortfolioPosition;
  const PortfolioPosition._();

  /// Master aset yang belum punya holding, diwakili posisi bernilai nol.
  factory PortfolioPosition.empty(Asset asset) {
    return PortfolioPosition(
      asset: asset,
      holding: Holding(
        assetId: asset.id,
        currentValue: 0,
        lastUpdatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      allocationPercentage: 0,
    );
  }

  factory PortfolioPosition.fromJson(Map<String, dynamic> json) {
    return PortfolioPosition(
      asset: Asset.fromJson(json['asset'] as Map<String, dynamic>),
      holding: Holding.fromJson(json['holding'] as Map<String, dynamic>),
      allocationPercentage: (json['allocationPercentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asset': asset.toJson(),
      'holding': holding.toJson(),
      'allocationPercentage': allocationPercentage,
    };
  }

  String get id => asset.id;
  String get name => asset.name;
  String get code => asset.code;
  AssetCategory get category => asset.category;
  String? get marketSymbol => asset.marketSymbol;

  double get currentValue => holding.currentValue;
  double? get totalCost => holding.totalCost;
  double? get quantity => holding.quantity;
  double? get avgBuyPrice => holding.avgBuyPrice;
  String? get priceCurrency => holding.priceCurrency;
  String get effectivePriceCurrency => holding.effectivePriceCurrency;
  DateTime get lastUpdatedAt => holding.lastUpdatedAt;
  double? get profitLoss => holding.profitLoss;
  double? get profitLossPercentage => holding.profitLossPercentage;
}
