import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/app/theme/app_radius.dart';
import 'package:flutter_wasilah_app/app/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/portfolio_summary.dart';

class PortfolioSummaryCard extends StatelessWidget {
  const PortfolioSummaryCard({super.key, required this.summary});

  final PortfolioSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final change = summary.monthlyChangePercentage;

    return Card(
      color: colorScheme.primaryContainer,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Portofolio',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                formatCurrency(summary.totalValue),
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    _changeIcon(change),
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _changeLabel(change),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _changeLabel(double value) {
    final formatted = value.abs().toStringAsFixed(1).replaceAll('.', ',');
    if (value > 0) {
      return 'Naik $formatted% bulan ini';
    }
    if (value < 0) {
      return 'Turun $formatted% bulan ini';
    }

    return 'Stabil bulan ini';
  }

  IconData _changeIcon(double value) {
    if (value > 0) {
      return Icons.trending_up;
    }
    if (value < 0) {
      return Icons.trending_down;
    }

    return Icons.trending_flat;
  }
}
