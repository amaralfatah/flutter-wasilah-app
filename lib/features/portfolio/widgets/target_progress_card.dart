import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/app/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/widgets/app_card.dart';

class TargetProgressCard extends StatelessWidget {
  const TargetProgressCard({
    super.key,
    required this.percentage,
    this.label = 'Target Alokasi',
    this.subtitle = 'Alokasi portofolio ideal',
  });

  final double percentage;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final progressValue = (percentage / 100).clamp(0.0, 1.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(value: progressValue),
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
