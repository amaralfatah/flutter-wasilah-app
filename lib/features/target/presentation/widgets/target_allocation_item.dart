import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/asset_category_icon.dart';
import 'package:flutter_wasilah_app/features/target/providers/target_providers.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';

class TargetAllocationItem extends StatelessWidget {
  const TargetAllocationItem({required this.item, super.key});

  final TargetAllocationData item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = AppColors.categoryColorOf(
      context,
      item.category.index,
    );
    final actualOfTarget = l10n.targetAllocationActualOfTarget(
      formatPercentage(item.actualPercentage),
      formatPercentage(item.targetPercentage),
    );

    return Row(
      children: [
        AssetCategoryIcon(category: item.category, color: categoryColor),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: item.category.label,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: '  ${formatCurrency(item.actualValue)}',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    formatPercentage(item.actualPercentage),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                label: l10n.targetAllocationProgressSemanticLabel(
                  item.category.label,
                ),
                value: actualOfTarget,
                child: LinearProgressIndicator(
                  value: (item.actualPercentage / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                  color: categoryColor,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      actualOfTarget,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    formatSignedPercentage(item.differencePercentage),
                    style: textTheme.bodySmall?.copyWith(
                      color: item.statusColor(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
