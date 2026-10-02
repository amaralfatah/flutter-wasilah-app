import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/profit_loss_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_list_card.dart';

/// Daftar metrik holding: nilai, modal, untung/rugi, harga avg, unit, dan
/// tanggal update terakhir.
class HoldingMetricsList extends StatelessWidget {
  const HoldingMetricsList({required this.position, super.key});

  final PortfolioPosition position;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final position = this.position;
    final isCash = position.asset.category == AssetCategory.cash;

    return AppListCard(
      children: [
        _MetricTile(
          label: l10n.commonCurrentValueLabel,
          value: formatCurrency(position.currentValue),
          subtitle: switch (position.marketPriceAt) {
            final priceAt? => l10n.marketValueAsOf(
              formatFullDateTime(priceAt, Localizations.localeOf(context)),
            ),
            null => null,
          },
        ),
        // Kas tak untung/rugi (modal = nilai), jadi modal & untung/rugi
        // hanya mengulang nilai.
        if (position.totalCost case final totalCost? when !isCash) ...[
          _MetricTile(
            label: l10n.totalCostLabel,
            value: formatCurrency(totalCost),
          ),
          _ProfitLossTile(position: position),
        ],
        if (position.avgBuyPrice case final avgBuyPrice?)
          _MetricTile(
            label: l10n.avgBuyPriceLabel,
            value: formatAvgPrice(
              avgBuyPrice,
              position.effectivePriceCurrency,
            ),
          ),
        if (position.quantity case final quantity?)
          _MetricTile(
            label: l10n.quantityLabel,
            value: formatQuantity(quantity),
          ),
        _MetricTile(
          label: l10n.lastUpdatedLabel,
          value: formatFullDate(
            position.lastUpdatedAt,
            Localizations.localeOf(context),
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.end,
      ),
    );
  }
}

class _ProfitLossTile extends StatelessWidget {
  const _ProfitLossTile({required this.position});

  final PortfolioPosition position;

  @override
  Widget build(BuildContext context) {
    final profitLoss = position.profitLoss ?? 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      title: Text(profitLossLabel(context, profitLoss)),
      trailing: Text(
        formatProfitLoss(profitLoss, cost: position.totalCost ?? 0),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: profitLossColorOf(context, profitLoss),
        ),
        textAlign: TextAlign.end,
      ),
    );
  }
}
