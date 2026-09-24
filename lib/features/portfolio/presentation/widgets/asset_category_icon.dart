import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';

/// Logo per simbol pasar (prefix sebelum `.`, mis. `BMRI.JK` -> `bmri`).
/// Ditambah manual seiring aset baru; di luar daftar ini jatuh ke
/// [AssetCategoryIcon] biasa (icon kategori).
const Map<String, String> _logoAssetBySymbol = {
  'BMRI': 'assets/logos/bmri.svg',
  'BTC': 'assets/logos/btc.svg',
  'SPY': 'assets/logos/spy.svg',
};

class AssetCategoryIcon extends StatelessWidget {
  const AssetCategoryIcon({
    required this.category,
    super.key,
    this.marketSymbol,
    this.color,
    this.radius = 20,
  });

  final AssetCategory category;

  /// Simbol Yahoo Finance aset (mis. `BMRI.JK`, `BTC-USD`); dipakai mencari
  /// logo di [_logoAssetBySymbol] sebelum jatuh ke icon kategori.
  final String? marketSymbol;

  /// Warna latar; default `secondaryContainer`.
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = color ?? colorScheme.secondaryContainer;
    final foreground = color == null
        ? colorScheme.onSecondaryContainer
        : ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    final logoAsset = _logoAssetForSymbol(marketSymbol);

    // Logo brand didesain untuk latar putih; paksa putih terlepas dari tema
    // agar warna aslinya (mis. biru Mandiri, oranye BTC) tidak bentrok.
    return CircleAvatar(
      radius: radius,
      backgroundColor: logoAsset != null ? Colors.white : background,
      foregroundColor: foreground,
      child: logoAsset != null
          ? Padding(
              padding: EdgeInsets.all(radius * 0.2),
              child: SvgPicture.asset(logoAsset),
            )
          : Icon(_iconForCategory(category), size: radius),
    );
  }

  static String? _logoAssetForSymbol(String? marketSymbol) {
    if (marketSymbol == null) return null;
    final ticker = marketSymbol.split('.').first.split('-').first;
    return _logoAssetBySymbol[ticker.toUpperCase()];
  }

  IconData _iconForCategory(AssetCategory category) {
    switch (category) {
      case AssetCategory.crypto:
        return Icons.currency_bitcoin;
      case AssetCategory.stock:
        return Icons.show_chart;
      case AssetCategory.mutualFund:
        return Icons.pie_chart_outline;
      case AssetCategory.indexEtf:
        return Icons.stacked_line_chart;
      case AssetCategory.preciousMetal:
        return Icons.diamond_outlined;
      case AssetCategory.cash:
        return Icons.account_balance_wallet_outlined;
      case AssetCategory.other:
        return Icons.category_outlined;
    }
  }
}
