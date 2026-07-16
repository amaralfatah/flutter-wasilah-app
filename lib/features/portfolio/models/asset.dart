import 'package:flutter/foundation.dart';

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

@immutable
class Asset {
  const Asset({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.currentValue,
    required this.allocationPercentage,
    required this.lastUpdatedAt,
  });

  final String id;
  final String name;
  final String code;
  final AssetCategory category;
  final double currentValue;
  final double allocationPercentage;
  final DateTime lastUpdatedAt;

  Asset copyWith({
    String? id,
    String? name,
    String? code,
    AssetCategory? category,
    double? currentValue,
    double? allocationPercentage,
    DateTime? lastUpdatedAt,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      category: category ?? this.category,
      currentValue: currentValue ?? this.currentValue,
      allocationPercentage: allocationPercentage ?? this.allocationPercentage,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

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

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Asset &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            name == other.name &&
            code == other.code &&
            category == other.category &&
            currentValue == other.currentValue &&
            allocationPercentage == other.allocationPercentage &&
            lastUpdatedAt == other.lastUpdatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    code,
    category,
    currentValue,
    allocationPercentage,
    lastUpdatedAt,
  );
}
