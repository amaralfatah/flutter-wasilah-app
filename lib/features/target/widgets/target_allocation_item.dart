import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/app/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset.dart';
import 'package:flutter_wasilah_app/features/target/providers/target_providers.dart';

class TargetAllocationItem extends StatelessWidget {
  const TargetAllocationItem({super.key, required this.item});

  final TargetAllocationData item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progressValue = item.targetPercentage == 0
        ? 0.0
        : (item.actualPercentage / item.targetPercentage).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category.label,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Aktual ${_formatPercentage(item.actualPercentage)} dari target ${_formatPercentage(item.targetPercentage)}',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(item: item),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatDifference(item.differencePercentage),
                    style: textTheme.bodySmall?.copyWith(
                      color: item.statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: 'Progres alokasi ${item.category.label}',
            value:
                'Aktual ${_formatPercentage(item.actualPercentage)} dari target ${_formatPercentage(item.targetPercentage)}',
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
              color: item.statusColor,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPercentage(double value) {
    return '${value.toStringAsFixed(0)}%';
  }

  String _formatDifference(double value) {
    if (value == 0) {
      return '0%';
    }

    final prefix = value > 0 ? '+' : '-';
    return '$prefix${value.abs().toStringAsFixed(0)}%';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.item});

  final TargetAllocationData item;

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: item.statusColor.withValues(alpha: 0.12),
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      label: Text(
        item.statusLabel,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: item.statusColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
