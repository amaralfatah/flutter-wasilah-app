import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset.dart';

class AssetCategoryIcon extends StatelessWidget {
  const AssetCategoryIcon({super.key, required this.category});

  final AssetCategory category;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: 20,
      backgroundColor: colorScheme.secondaryContainer,
      foregroundColor: colorScheme.onSecondaryContainer,
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
