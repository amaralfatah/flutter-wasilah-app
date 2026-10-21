import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/profit_loss_formatter.dart';
import 'package:flutter_wasilah_app/features/market/providers/market_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';

/// Kartu metrik holding ala "Portfolio Detail" Stockbit: baris label di
/// kiri dan angka di kanan tanpa garis pemisah — unit, harga rata-rata,
/// harga kini, modal, nilai pasar, potensi untung/rugi, dan persentasenya.
class HoldingMetricsList extends ConsumerWidget {
  const HoldingMetricsList({required this.position, super.key});

  final PortfolioPosition position;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final position = this.position;
    final isCash = position.asset.category == AssetCategory.cash;
    final quote = switch (position.asset.marketSymbol) {
      final symbol? => ref.watch(marketQuoteProvider(symbol)).valueOrNull,
      null => null,
    }?.quote;
    final totalCost = position.totalCost;
    final profitLoss = position.profitLoss;
    final profitColor = profitLoss == null
        ? null
        : profitLossColorOf(context, profitLoss);

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          if (position.quantity case final quantity?)
            _MetricRow(
              label: l10n.quantityLabel,
              value: formatQuantity(quantity),
            ),
          if (position.avgBuyPrice case final avgBuyPrice?)
            _MetricRow(
              label: l10n.avgBuyPriceLabel,
              value: formatAvgPrice(
                avgBuyPrice,
                position.effectivePriceCurrency,
              ),
            ),
          if (quote != null)
            _MetricRow(
              label: l10n.assetTableCurrentPriceHeader,
              value: formatPrice(quote.price, quote.currency),
              valueColor: switch (quote.change) {
                final change? when change != 0 => profitLossColorOf(
                  context,
                  change,
                ),
                _ => null,
              },
            ),
          // Kas tak untung/rugi (modal = nilai), jadi modal & untung/rugi
          // hanya mengulang nilai.
          if (totalCost != null && !isCash)
            _MetricRow(
              label: l10n.totalCostLabel,
              value: formatNumber(totalCost),
            ),
          _MetricRow(
            label: l10n.commonCurrentValueLabel,
            value: formatNumber(position.currentValue),
          ),
          if (profitLoss != null && totalCost != null && !isCash) ...[
            _MetricRow(
              label: profitLossLabel(context, profitLoss),
              value: formatSignedNumber(profitLoss),
              valueColor: profitColor,
            ),
            if (position.profitLossPercentage case final percentage?)
              _MetricRow(
                label: l10n.commonReturnLabel,
                value: formatSignedPercentage(percentage),
                valueColor: profitColor,
              ),
          ],
          _MetricRow(
            label: l10n.lastUpdatedLabel,
            value: formatShortDate(
              position.marketPriceAt ?? position.lastUpdatedAt,
              Localizations.localeOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          const SizedBox(width: AppSpacing.md),
          Text(
            value,
            textAlign: TextAlign.end,
            style: textTheme.bodyMedium?.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
