import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/profit_loss_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_summary.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';

/// Ringkasan portofolio ala kartu akun Stockbit: grid 3x2 dengan kas di kiri
/// atas (padanan Trading Balance) dan total nilai di kanan bawah (padanan
/// Total Equity), ditutup baris pintasan ke histori. Beda dengan Stockbit,
/// modal dan return ikut menghitung kas karena kas di sini dana serok yang
/// jadi bagian strategi, bukan saldo menganggur.
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
    // Aset bernilai 0 sudah nonaktif/diarsipkan; historinya tetap tersimpan
    // tapi tidak lagi ikut dihitung sebagai kepemilikan aktif.
    final activeAssets = summary.positions
        .where((asset) => asset.currentValue != 0)
        .toList(growable: false);
    final cash = activeAssets
        .where((asset) => asset.category == AssetCategory.cash)
        .fold<double>(0, (sum, asset) => sum + asset.currentValue);
    final profitLoss = _totalProfitLoss(activeAssets);
    // Modal yang ditampilkan di kartu ringkasan sengaja beda dari modal yang
    // dipakai hitung return (profitLoss.cost): di sini kas dikeluarkan
    // supaya angka "Modal" merepresentasikan aset investasi murni.
    final nonCashAssets = activeAssets
        .where((asset) => asset.category != AssetCategory.cash)
        .toList(growable: false);
    final capital = nonCashAssets.isEmpty
        ? null
        : nonCashAssets.fold<double>(
            0,
            (sum, asset) => sum + (asset.totalCost ?? asset.currentValue),
          );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Semantics(
        label: _semanticLabel(context, l10n, cash, profitLoss),
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryMetric(
                          label: l10n.dashboardCashLabel,
                          value: formatNumber(cash),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _SummaryMetric(
                          label: l10n.dashboardCapitalLabel,
                          alignment: _MetricAlignment.center,
                          value: capital == null ? '-' : formatNumber(capital),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _SummaryMetric(
                          label: l10n.dashboardAssetCountLabel,
                          alignment: _MetricAlignment.end,
                          value: '${activeAssets.length}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryMetric(
                          label: l10n.dashboardProfitLossLabel,
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
                          alignment: _MetricAlignment.center,
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
                          label: l10n.dashboardPortfolioValueLabel,
                          alignment: _MetricAlignment.end,
                          value: formatNumber(summary.totalValue),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onViewHistory != null) ...[
              const Divider(),
              InkWell(
                onTap: onViewHistory,
                child: Padding(
                  // Diukur dari "View Performance" Stockbit: ikon lebih
                  // dekat ke tepi kiri, chevron lebih dekat ke tepi kanan,
                  // dan baris lebih pendek dari metrik di atasnya.
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    10,
                    AppSpacing.sm,
                    10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.dashboardViewHistoryLabel,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
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

  /// Untung/rugi gabungan dari [activeAssets], termasuk kas; `null` bila
  /// belum ada aset yang punya modal. Aset tanpa modal dianggap impas
  /// (modal = nilai) supaya tidak terbaca sebagai untung — sama dengan
  /// perhitungan histori portofolio.
  ({double amount, double cost, double? percentage})? _totalProfitLoss(
    List<PortfolioPosition> activeAssets,
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
    double cash,
    ({double amount, double cost, double? percentage})? profitLoss,
  ) {
    final buffer = StringBuffer(
      '${l10n.dashboardTotalPortfolioSemantic(
        formatCurrency(summary.totalValue),
        formatCurrency(cash),
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
}

/// Kolom kiri rata kiri, tengah rata tengah, kanan rata kanan — pola kartu
/// akun Stockbit supaya tiga angka sebaris terbaca sebagai tiga kolom.
enum _MetricAlignment {
  start(CrossAxisAlignment.start, Alignment.centerLeft, TextAlign.start),
  center(CrossAxisAlignment.center, Alignment.center, TextAlign.center),
  end(CrossAxisAlignment.end, Alignment.centerRight, TextAlign.end);

  const _MetricAlignment(this.cross, this.fit, this.text);

  final CrossAxisAlignment cross;
  final Alignment fit;
  final TextAlign text;
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.valueColor,
    this.alignment = _MetricAlignment.start,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final _MetricAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: alignment.cross,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment.fit,
          child: Text(
            value,
            maxLines: 1,
            style: textTheme.titleSmall?.copyWith(
              color: valueColor ?? colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 2),
        // Mengecil, bukan terpotong: label seperti "Portfolio Value" harus
        // tetap terbaca utuh di kolom sempit.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment.fit,
          child: Text(
            label,
            maxLines: 1,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
