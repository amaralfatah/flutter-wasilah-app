import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/profit_loss_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_summary.dart';
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
        label: _semanticLabel(change, profitLoss),
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
                          label: 'Nilai Portofolio',
                          value: formatNumber(summary.totalValue),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _SummaryMetric(
                          label: 'Modal',
                          value: profitLoss == null
                              ? '-'
                              : formatNumber(profitLoss.cost),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _SummaryMetric(
                          label: 'Jumlah Aset',
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
                              ? 'Untung/Rugi'
                              : profitLossLabel(profitLoss.amount),
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
                          label: 'Return',
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
                          label: 'Bulan Ini',
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
                          'Lihat histori',
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
    double change,
    ({double amount, double cost, double? percentage})? profitLoss,
  ) {
    final buffer = StringBuffer(
      'Total portofolio ${formatCurrency(summary.totalValue)}. '
      '${_changeLabel(change)}.',
    );
    if (profitLoss != null) {
      final percentage = profitLoss.percentage;
      final suffix = percentage == null
          ? ''
          : ' (${formatSignedPercentage(percentage)})';
      buffer.write(
        ' Modal ${formatCurrency(profitLoss.cost)}. '
        '${profitLossLabel(profitLoss.amount)} '
        '${formatCurrency(profitLoss.amount.abs())}$suffix.',
      );
    }
    return buffer.toString();
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
