import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/profit_loss_formatter.dart';
import 'package:flutter_wasilah_app/features/market/data/models/price_series.dart';
import 'package:flutter_wasilah_app/features/market/presentation/widgets/price_line_chart.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/value_snapshot.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';

/// Chart nilai histori ala "Performance" Stockbit: garis hijau/merah
/// berisian gradasi, acuan putus-putus di nilai awal, sumbu Y kanan, dan
/// garis modal sebagai pembanding (seperti garis IHSG di Stockbit).
class HistoryLineChart extends StatelessWidget {
  const HistoryLineChart({
    required this.history,
    super.key,
    this.showCost = true,
    this.onScrub,
    this.horizontalPadding = AppSpacing.xl,
    this.valueLabel,
    this.valueReturn,
    this.costReturn,
  });

  /// Snapshots ordered oldest to newest.
  final List<ValueSnapshot> history;

  /// `false` untuk aset yang modalnya selalu sama dengan nilai (kas),
  /// supaya garis modal tidak menimpa garis nilai.
  final bool showCost;

  /// Snapshot yang sedang di-scrub, atau `null` saat jari dilepas.
  final ValueChanged<ValueSnapshot?>? onScrub;

  /// Jarak kiri legenda/plot; lebih kecil saat chart berada di dalam kartu.
  final double horizontalPadding;

  /// Label garis nilai di legenda; default "Nilai".
  final String? valueLabel;

  /// Return garis nilai & modal selama periode, ditampilkan di kotak
  /// legenda seperti kotak "Portfolio -8,81% | IHSG -38,95%" Stockbit.
  final double? valueReturn;
  final double? costReturn;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Satu titik tidak bisa digambar sebagai garis. Tampilkan penjelasan,
    // jangan menghilang begitu saja — kalau tidak, grafik akan lenyap tanpa
    // sebab saat user memfilter periode yang hanya punya satu pencatatan.
    if (history.length < 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Text(
          l10n.historyChartPlaceholderMessage,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final locale = Localizations.localeOf(context);
    final points = [
      for (final item in history)
        PricePoint(time: item.recordedAt, close: item.totalValue),
    ];
    // Satu titik modal tidak membentuk garis, jadi garis modal baru
    // digambar mulai dua pencatatan.
    final costs = history.map((item) => item.totalCost).toList();
    final hasCost = showCost && costs.nonNulls.length >= 2;
    final costColor = colorScheme.brightness == Brightness.dark
        ? const Color(0xFFA07CFF)
        : const Color(0xFF7C4DFF);
    final axisStyle = textTheme.bodySmall?.copyWith(
      fontSize: 11,
      color: colorScheme.onSurfaceVariant,
    );
    // Lima tanggal merata seperti sumbu X Stockbit (2 Jan … 21 Okt).
    final axisDates = history.length <= 5
        ? history
        : [
            for (var i = 0; i < 5; i++)
              history[(i * (history.length - 1) / 4).round()],
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasCost)
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _LegendItem(
                    color: colorScheme.primary,
                    label: valueLabel ?? l10n.assetTableValueHeader,
                    value: valueReturn,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _LegendItem(
                    color: costColor,
                    label: l10n.dashboardCapitalLabel,
                    value: costReturn,
                  ),
                ),
              ],
            ),
          ),
        Semantics(
          label: l10n.historyChartSemanticLabelValueOnly(
            formatMonthYear(history.first.recordedAt, locale),
            formatMonthYear(history.last.recordedAt, locale),
            formatCurrency(
              points.map((p) => p.close).reduce((a, b) => a < b ? a : b),
            ),
            formatCurrency(
              points.map((p) => p.close).reduce((a, b) => a > b ? a : b),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: AppSpacing.sm,
            ),
            child: PriceLineChart(
              points: points,
              referencePrice: history.first.totalValue,
              currency: 'IDR',
              tickTarget: 5,
              formatValue: formatNumber,
              formatAxis: formatAxisCompact,
              showExtremeLabels: false,
              secondaryValues: hasCost ? costs : null,
              secondaryColor: costColor,
              onScrub: onScrub == null
                  ? null
                  : (point) => onScrub!(
                      point == null
                          ? null
                          : history.firstWhere(
                              (item) => item.recordedAt == point.time,
                            ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: EdgeInsets.only(
            left: horizontalPadding,
            // Sejajar ujung kanan plot, bukan kolom sumbu Y.
            right: AppSpacing.sm + 56,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final item in axisDates)
                Text(
                  formatShortMonthYear(item.recordedAt, locale),
                  style: axisStyle,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Kotak legenda ala "Portfolio | IHSG" Stockbit: garis warna, label, dan
/// return periode di kanan.
class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label, this.value});

  final Color color;
  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final value = this.value;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline, width: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        child: Row(
          children: [
            Container(width: 3, height: 14, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall,
              ),
            ),
            if (value != null)
              Text(
                formatSignedPercentage(value),
                style: textTheme.bodySmall?.copyWith(
                  color: profitLossColorOf(context, value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
