import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_summary.dart';

class PortfolioSummaryCard extends StatelessWidget {
  const PortfolioSummaryCard({required this.summary, super.key});

  final PortfolioSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final change = summary.monthlyChangePercentage;
    final profitLoss = _totalProfitLoss();
    final profitLossLabel = profitLoss == null
        ? null
        : _profitLossLabel(profitLoss);

    return Card(
      color: colorScheme.primaryContainer,
      margin: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Semantics(
            label:
                'Total portofolio ${formatCurrency(summary.totalValue)}. '
                '${_changeLabel(change)}.'
                '${profitLossLabel == null ? '' : ' $profitLossLabel.'}',
            excludeSemantics: true,
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
                // Angka terpenting di aplikasi; sebelumnya sebesar nominal
                // per-aset di daftar sehingga hierarkinya hilang. FittedBox
                // menjaga nominal panjang tetap muat dalam satu baris.
                Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatCurrency(summary.totalValue),
                      style: textTheme.displaySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                    ),
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
                      ),
                    ),
                  ],
                ),
                if (profitLossLabel != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          profitLossLabel,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Untung/rugi gabungan; `null` bila belum ada aset yang punya modal.
  /// Aset tanpa modal dianggap impas (modal = nilai) supaya tidak terbaca
  /// sebagai untung — sama dengan perhitungan histori portofolio.
  ({double amount, double? percentage})? _totalProfitLoss() {
    if (summary.assets.every((asset) => asset.totalCost == null)) {
      return null;
    }

    var value = 0.0;
    var cost = 0.0;
    for (final asset in summary.assets) {
      value += asset.currentValue;
      cost += asset.totalCost ?? asset.currentValue;
    }

    return (
      amount: value - cost,
      percentage: cost == 0 ? null : (value - cost) / cost * 100,
    );
  }

  String _profitLossLabel(({double amount, double? percentage}) profitLoss) {
    final amount = profitLoss.amount;
    final verb = amount < 0 ? 'Rugi' : 'Untung';
    final percentage = profitLoss.percentage;
    final suffix = percentage == null
        ? ''
        : ' (${formatSignedPercentage(percentage)})';
    return '$verb ${formatCurrency(amount.abs())}$suffix';
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
