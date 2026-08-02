import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/target/providers/target_providers.dart';

class TargetAllocationItem extends StatelessWidget {
  const TargetAllocationItem({required this.item, super.key});

  final TargetAllocationData item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusColor = item.statusColor(context);
    final progressValue = item.targetPercentage == 0
        ? 0.0
        : (item.actualPercentage / item.targetPercentage).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.category.label, style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Aktual ${formatPercentage(item.actualPercentage)} '
                    'dari target ${formatPercentage(item.targetPercentage)}',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              formatSignedPercentage(item.differencePercentage),
              style: textTheme.titleMedium?.copyWith(color: statusColor),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          label: 'Progres alokasi ${item.category.label}',
          value:
              'Aktual ${formatPercentage(item.actualPercentage)} '
              'dari target ${formatPercentage(item.targetPercentage)}',
          child: LinearProgressIndicator(
            value: progressValue,
            color: statusColor,
          ),
        ),
      ],
    );
  }
}
