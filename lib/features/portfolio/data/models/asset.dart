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
    };
  }
}
