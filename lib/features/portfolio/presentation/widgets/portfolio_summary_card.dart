import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/profit_loss_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_summary.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';

/// Ringkasan portofolio ala kartu akun aplikasi sekuritas: grid 3x2 supaya
/// nilai, modal, dan PnL semuanya terlihat sekaligus tanpa scroll atau
/// membuka detail, ditutup baris pintasan ke histori.
class PortfolioSummaryCard extends StatelessWidget {
  const PortfolioSummaryCard({
    required this.summary,
    super.key,
    this.onViewHistory,
  });

  final PortfolioSummary summary;
  final VoidCallback? onViewHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final change = summary.monthlyChangePercentage;
    // Aset bernilai 0 sudah nonaktif/diarsipkan; historinya tetap tersimpan
    // tapi tidak lagi ikut dihitung sebagai kepemilikan aktif.
    final activeAssets = summary.assets
        .where((asset) => asset.currentValue != 0)
        .toList(growable: false);
    final profitLoss = _totalProfitLoss(activeAssets);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Semantics(
        label: _semanticLabel(context, l10n, change, profitLoss),
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryMetric(
                          label: l10n.dashboardPortfolioValueLabel,
                          value: formatNumber(summary.totalValue),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _SummaryMetric(
                          label: l10n.dashboardCapitalLabel,
                          value: profitLoss == null
                              ? '-'
                              : formatNumber(profitLoss.cost),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _SummaryMetric(
                          label: l10n.dashboardAssetCountLabel,
                          value: '${activeAssets.length}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryMetric(
                          label: profitLoss == null
                              ? l10n.dashboardProfitLossFallbackLabel
                              : profitLossLabel(context, profitLoss.amount),
                          value: profitLoss == null
                              ? '-'
                              : formatSignedNumber(profitLoss.amount),
                          valueColor: profitLoss == null
                              ? null
                              : profitLossColorOf(context, profitLoss.amount),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _SummaryMetric(
                          label: l10n.commonReturnLabel,
                          value: profitLoss?.percentage == null
                              ? '-'
                              : formatSignedPercentage(
                                  profitLoss!.percentage!,
                                ),
                          valueColor: profitLoss == null
                              ? null
                              : profitLossColorOf(context, profitLoss.amount),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _SummaryMetric(
                          label: l10n.dashboardThisMonthLabel,
                          value: formatSignedPercentage(change),
                          valueColor: profitLossColorOf(context, change),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onViewHistory != null) ...[
              const Divider(height: 1),
              InkWell(
                onTap: onViewHistory,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.show_chart_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.dashboardViewHistoryLabel,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Untung/rugi gabungan dari [activeAssets]; `null` bila belum ada aset
  /// yang punya modal. Aset tanpa modal dianggap impas (modal = nilai)
  /// supaya tidak terbaca sebagai untung — sama dengan perhitungan histori
  /// portofolio.
  ({double amount, double cost, double? percentage})? _totalProfitLoss(
    List<Asset> activeAssets,
  ) {
    if (activeAssets.every((asset) => asset.totalCost == null)) {
      return null;
    }

    var value = 0.0;
    var cost = 0.0;
    for (final asset in activeAssets) {
      value += asset.currentValue;
      cost += asset.totalCost ?? asset.currentValue;
    }

    return (
      amount: value - cost,
      cost: cost,
      percentage: cost == 0 ? null : (value - cost) / cost * 100,
    );
  }

  String _semanticLabel(
    BuildContext context,
    AppLocalizations l10n,
    double change,
    ({double amount, double cost, double? percentage})? profitLoss,
  ) {
    final buffer = StringBuffer(
      '${l10n.dashboardTotalPortfolioSemantic(
        formatCurrency(summary.totalValue),
        _changeLabel(l10n, change),
      )}.',
    );
    if (profitLoss != null) {
      final percentage = profitLoss.percentage;
      final suffix = percentage == null
          ? ''
          : ' (${formatSignedPercentage(percentage)})';
      buffer.write(
        ' ${l10n.dashboardProfitLossSemantic(
          formatCurrency(profitLoss.cost),
          profitLossLabel(context, profitLoss.amount),
          '${formatCurrency(profitLoss.amount.abs())}$suffix',
        )}.',
      );
    }
    return buffer.toString();
  }

  String _changeLabel(AppLocalizations l10n, double value) {
    final formatted = value.abs().toStringAsFixed(1).replaceAll('.', ',');
    if (value > 0) {
      return l10n.dashboardChangeUpLabel(formatted);
    }
    if (value < 0) {
      return l10n.dashboardChangeDownLabel(formatted);
    }

    return l10n.dashboardChangeStableLabel;
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: textTheme.titleMedium?.copyWith(
              color: valueColor ?? colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
