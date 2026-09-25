import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/features/market/data/models/chart_range.dart';
import 'package:flutter_wasilah_app/features/market/data/models/market_quote.dart';
import 'package:flutter_wasilah_app/features/market/data/models/price_series.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/asset_category_icon.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';

String periodLabelFor(BuildContext context, ChartRange range) {
  final l10n = context.l10n;
  return switch (range) {
    ChartRange.oneDay => l10n.chartPeriodToday,
    ChartRange.oneWeek => l10n.chartPeriodPastWeek,
    ChartRange.oneMonth => l10n.chartPeriodPastMonth,
    ChartRange.threeMonths => l10n.chartPeriodPastThreeMonths,
    ChartRange.yearToDate => l10n.chartPeriodYearToDate,
    ChartRange.oneYear => l10n.chartPeriodPastYear,
    ChartRange.threeYears => l10n.chartPeriodPastThreeYears,
    ChartRange.fiveYears => l10n.chartPeriodPastFiveYears,
  };
}

/// Header halaman Detail Pasar ala Stockbit: kode, nama, harga besar, dan
/// baris perubahan, dengan ikon kategori di kanan (pengganti logo emiten).
/// Saat [scrubPoint] terisi (jari sedang menekan chart), harga dan label
/// periode diganti dengan titik yang di-scrub itu.
class MarketQuoteHeader extends StatelessWidget {
  const MarketQuoteHeader({
    required this.asset,
    required this.quote,
    required this.isStale,
    required this.range,
    required this.referencePrice,
    super.key,
    this.scrubPoint,
  });

  final Asset asset;
  final MarketQuote quote;
  final bool isStale;
  final ChartRange range;

  /// Acuan perhitungan perubahan: penutupan kemarin (1D) atau titik
  /// pertama seri (range lain); `null` bila belum ada acuan.
  final double? referencePrice;
  final PricePoint? scrubPoint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);

    final scrub = scrubPoint;
    final displayPrice = scrub?.close ?? quote.price;
    final reference = referencePrice;
    final change = reference == null ? null : displayPrice - reference;
    final changePercent = (reference == null || reference == 0)
        ? null
        : (displayPrice - reference) / reference * 100;
    final isPositive = (change ?? 0) >= 0;
    final changeColor = change == null
        ? colorScheme.onSurfaceVariant
        : isPositive
        ? AppColors.positiveOf(context)
        : AppColors.negativeOf(context);
    final changeStyle = textTheme.bodyMedium?.copyWith(color: changeColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(asset.code, style: textTheme.titleMedium),
                  Text(
                    asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    formatPrice(displayPrice, quote.currency),
                    style: textTheme.headlineSmall,
                  ),
                  // Tinggi baris dijaga tetap walau perubahan belum ada,
                  // supaya chart di bawahnya tidak melompat saat data masuk.
                  SizedBox(
                    height: 20,
                    child: change == null || changePercent == null
                        ? null
                        : Row(
                            children: [
                              Icon(
                                isPositive
                                    ? Icons.north_east
                                    : Icons.south_east,
                                size: 14,
                                color: changeColor,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                _changeLabel(change, changePercent),
                                style: changeStyle,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  scrub != null
                                      ? _scrubTimeLabel(
                                          scrub.time,
                                          range,
                                          locale,
                                        )
                                      : periodLabelFor(context, range),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AssetCategoryIcon(
              category: asset.category,
              marketSymbol: asset.marketSymbol,
              radius: 22,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            _Tag(label: asset.category.label, color: colorScheme.primary),
            if (isStale)
              _Tag(
                label: l10n.marketOfflineChip,
                color: colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ],
    );
  }

  /// Mis. `-120 (-2,86%)`.
  String _changeLabel(double change, double changePercent) {
    return '${formatSignedPrice(change, quote.currency)} '
        '(${formatSignedChangePercentage(changePercent)})';
  }

  String _scrubTimeLabel(DateTime time, ChartRange range, Locale locale) {
    final isIntraday =
        range == ChartRange.oneDay ||
        range == ChartRange.oneWeek ||
        range == ChartRange.oneMonth;
    if (!isIntraday) {
      return formatShortDate(time, locale);
    }
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '${formatDayMonth(time, locale)} $hour.$minute';
  }
}

/// Tag bergaris tipis seperti "Bank"/"Day Trade" di Stockbit; lebih pendek
/// dari `Chip` M3 yang minimal 32dp.
class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
