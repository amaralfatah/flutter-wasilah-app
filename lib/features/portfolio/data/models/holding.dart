import 'package:freezed_annotation/freezed_annotation.dart';

part 'holding.freezed.dart';

/// Data porto satu aset: nilai terkini, modal, jumlah unit, dan kapan
/// terakhir diupdate. Terpisah dari `Asset` (master data) sejak refaktor
/// pemisahan master aset & portofolio.
@freezed
abstract class Holding with _$Holding {
  const factory Holding({
    required String assetId,
    required double currentValue,
    required DateTime lastUpdatedAt,

    /// Total modal yang disetor ke aset ini; `null` bila belum diisi.
    double? totalCost,

    /// Jumlah unit yang dimiliki (lot, lembar, koin, gram); `null` bila belum
    /// diisi.
    double? quantity,

    /// Harga rata-rata beli per unit, dalam [priceCurrency]. Nilai display
    /// murni; tidak dipakai untuk menghitung PnL (PnL selalu IDR).
    double? avgBuyPrice,

    /// Mata uang [avgBuyPrice] (mis. `IDR`, `USD`). `null` dianggap `IDR`.
    /// Tidak ditebak dari kategori: BTC bisa dibeli dalam IDR atau USD.
    String? priceCurrency,
  }) = _Holding;
  const Holding._();

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      assetId: json['assetId'] as String,
      currentValue: (json['currentValue'] as num).toDouble(),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      totalCost: (json['totalCost'] as num?)?.toDouble(),
      quantity: (json['quantity'] as num?)?.toDouble(),
      avgBuyPrice: (json['avgBuyPrice'] as num?)?.toDouble(),
      priceCurrency: json['priceCurrency'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assetId': assetId,
      'currentValue': currentValue,
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'totalCost': totalCost,
      'quantity': quantity,
      'avgBuyPrice': avgBuyPrice,
      'priceCurrency': priceCurrency,
    };
  }

  /// Mata uang harga beli efektif; `IDR` bila belum diisi.
  String get effectivePriceCurrency => priceCurrency ?? 'IDR';

  /// Untung/rugi terhadap [totalCost]; `null` bila modal belum diisi.
  double? get profitLoss {
    final cost = totalCost;
    return cost == null ? null : currentValue - cost;
  }

  /// [profitLoss] dalam persen modal; `null` bila modal kosong atau nol.
  double? get profitLossPercentage {
    final cost = totalCost;
    if (cost == null || cost == 0) {
      return null;
    }
    return (currentValue - cost) / cost * 100;
  }
}
