import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';

class TargetProgressCard extends StatelessWidget {
  const TargetProgressCard({
    required this.percentage,
    super.key,
    this.label,
    this.subtitle,
    this.onTap,
  });

  final double percentage;
  final String? label;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progressValue = (percentage / 100).clamp(0.0, 1.0);
    final resolvedLabel = label ?? l10n.targetProgressDefaultLabel;
    final resolvedSubtitle = subtitle ?? l10n.targetProgressDefaultSubtitle;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Semantics(
        label: l10n.targetProgressSemanticLabel(
          resolvedLabel,
          percentage.toStringAsFixed(2),
          resolvedSubtitle,
        ),
        excludeSemantics: true,
        button: onTap != null,
        // Pola kartu Stockbit: label kecil tebal + chevron, angka besar
        // tebal, bar hijau tipis, keterangan abu kecil.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    resolvedLabel,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              formatPercentage(percentage),
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(
              value: progressValue,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              resolvedSubtitle,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
