import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
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

    return AppCard(
      onTap: onTap,
      child: Semantics(
        label: l10n.targetProgressSemanticLabel(
          resolvedLabel,
          percentage.toStringAsFixed(0),
          resolvedSubtitle,
        ),
        excludeSemantics: true,
        button: onTap != null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resolvedLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(value: progressValue),
            const SizedBox(height: AppSpacing.sm),
            Text(
              resolvedSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
