import 'package:freezed_annotation/freezed_annotation.dart';

part 'asset.freezed.dart';

enum AssetCategory {
  crypto,
  stock,
  mutualFund,
  indexEtf,
  preciousMetal,
  cash,
  other,
}

extension AssetCategoryX on AssetCategory {
  String get label {
    switch (this) {
      case AssetCategory.crypto:
        return 'Kripto';
      case AssetCategory.stock:
        return 'Saham';
      case AssetCategory.mutualFund:
        return 'Reksa Dana';
      case AssetCategory.indexEtf:
        return 'Indeks / ETF';
      case AssetCategory.preciousMetal:
        return 'Logam Mulia';
      case AssetCategory.cash:
        return 'Kas';
      case AssetCategory.other:
        return 'Lainnya';
    }
  }
}

@freezed
abstract class Asset with _$Asset {
  const factory Asset({
    required String id,
    required String name,
    required String code,
    required AssetCategory category,
    required double currentValue,
    required double allocationPercentage,
    required DateTime lastUpdatedAt,

    /// Total modal yang disetor ke aset ini; `null` bila belum diisi.
    double? totalCost,

    /// Simbol Yahoo Finance (mis. `BMRI.JK`, `BTC-USD`); `null` bila aset
    /// tidak punya harga pasar.
    String? marketSymbol,

    /// Jumlah unit yang dimiliki (lot, lembar, koin, gram); `null` bila belum
    /// diisi.
    double? quantity,

    /// Harga rata-rata beli per unit, dalam [priceCurrency]. Nilai display
    /// murni; tidak dipakai untuk menghitung PnL (PnL selalu IDR).
    double? avgBuyPrice,

    /// Mata uang [avgBuyPrice] (mis. `IDR`, `USD`). `null` dianggap `IDR`.
    /// Tidak ditebak dari kategori: BTC bisa dibeli dalam IDR atau USD.
    String? priceCurrency,
  }) = _Asset;
  const Asset._();

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      category: AssetCategory.values.byName(json['category'] as String),
      currentValue: (json['currentValue'] as num).toDouble(),
      allocationPercentage: (json['allocationPercentage'] as num).toDouble(),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      totalCost: (json['totalCost'] as num?)?.toDouble(),
      marketSymbol: json['marketSymbol'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      avgBuyPrice: (json['avgBuyPrice'] as num?)?.toDouble(),
      priceCurrency: json['priceCurrency'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'category': category.name,
      'currentValue': currentValue,
      'allocationPercentage': allocationPercentage,
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'totalCost': totalCost,
      'marketSymbol': marketSymbol,
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
