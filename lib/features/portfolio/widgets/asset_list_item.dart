import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/app/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/widgets/allocation_badge.dart';
import 'package:flutter_wasilah_app/features/portfolio/widgets/asset_category_icon.dart';

class AssetListItem extends StatelessWidget {
  const AssetListItem({
    super.key,
    required this.asset,
    this.onTap,
    this.showCategory = true,
    this.showUpdatedAt = true,
  });

  final Asset asset;
  final VoidCallback? onTap;
  final bool showCategory;
  final bool showUpdatedAt;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: AssetCategoryIcon(category: asset.category),
      title: Text(
        asset.name,
        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCategory) Text(asset.category.label),
            if (showUpdatedAt) Text('Diperbarui ${formatFullDate(asset.lastUpdatedAt)}'),
          ],
        ),
      ),
      trailing: Wrap(
        spacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatCurrency(asset.currentValue),
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AllocationBadge(percentage: asset.allocationPercentage),
            ],
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
