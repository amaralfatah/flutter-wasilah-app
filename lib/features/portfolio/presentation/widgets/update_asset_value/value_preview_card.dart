import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/profit_loss_formatter.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';

/// Pratinjau nilai (dan modal) sebelum/sesudah update.
class ValuePreviewCard extends StatelessWidget {
  const ValuePreviewCard({
    required this.previousValue,
    required this.latestValue,
    super.key,
    this.addedValue,
    this.previousCost,
    this.latestCost,
  });

  final double previousValue;
  final double latestValue;

  /// Penambahan nilai (mode tambah); `null` di mode timpa.
  final double? addedValue;

  final double? previousCost;

  /// Modal baru; `null` menyembunyikan bagian modal & untung/rugi.
  final double? latestCost;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final addedValue = this.addedValue;
    final latestCost = this.latestCost;
    final previousCost = this.previousCost;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.previewLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _PreviewRow(
            label: l10n.recordedValueLabel,
            value: formatCurrency(previousValue),
          ),
          if (addedValue != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _PreviewRow(
              label: l10n.addedValueLabel,
              value: '+ ${formatCurrency(addedValue)}',
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _PreviewRow(
            label: l10n.latestValueLabel,
            value: formatCurrency(latestValue),
          ),
          if (latestCost != null) ...[
            const Divider(height: AppSpacing.xl),
            _PreviewRow(
              label: l10n.currentCostLabel,
              value: previousCost == null ? '-' : formatCurrency(previousCost),
            ),
            const SizedBox(height: AppSpacing.sm),
            _PreviewRow(
              label: l10n.latestCostLabel,
              value: formatCurrency(latestCost),
            ),
            const SizedBox(height: AppSpacing.sm),
            _PreviewRow(
              label: profitLossLabel(context, latestValue - latestCost),
              value: formatProfitLoss(
                latestValue - latestCost,
                cost: latestCost,
              ),
              valueColor: profitLossColorOf(context, latestValue - latestCost),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: valueColor),
        ),
      ],
    );
  }
}
