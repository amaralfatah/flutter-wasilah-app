import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';

class AssetCategoryIcon extends StatelessWidget {
  const AssetCategoryIcon({required this.category, super.key, this.color});

  final AssetCategory category;

  /// Warna latar; default `secondaryContainer`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = color ?? colorScheme.secondaryContainer;
    final foreground = color == null
        ? colorScheme.onSecondaryContainer
        : ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return CircleAvatar(
      radius: 20,
      backgroundColor: background,
      foregroundColor: foreground,
      child: Icon(_iconForCategory(category), size: 20),
    );
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
