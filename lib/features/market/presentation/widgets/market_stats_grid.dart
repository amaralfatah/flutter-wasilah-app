import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/features/market/data/models/market_quote.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';

/// Section "Data Perdagangan" ala Stockbit: kotak bergaris berisi statistik
/// perdagangan dari `meta` Yahoo (tertinggi/terendah hari, 52 minggu, volume,
/// penutupan sebelumnya). Hanya statistik yang ada nilainya yang tampil;
/// bila quote datang dari cache (semua null), section tidak dirender.
class MarketStatsGrid extends StatelessWidget {
  const MarketStatsGrid({required this.quote, super.key});

  final MarketQuote quote;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = quote.currency;

    final entries = <(String, String)>[
      if (quote.previousClose case final value?)
        (l10n.statPrevClose, formatPrice(value, currency)),
      if (quote.dayHigh case final value?)
        (l10n.statDayHigh, formatPrice(value, currency)),
      if (quote.dayLow case final value?)
        (l10n.statDayLow, formatPrice(value, currency)),
      if (quote.fiftyTwoWeekHigh case final value?)
        (l10n.statFiftyTwoWeekHigh, formatPrice(value, currency)),
      if (quote.fiftyTwoWeekLow case final value?)
        (l10n.statFiftyTwoWeekLow, formatPrice(value, currency)),
      if (quote.volume case final value?)
        (l10n.statVolume, formatQuantity(value)),
    ];

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Kotak bergaris ala "Intraday" Stockbit: judul kecil tebal, lalu baris
    // label di kiri dan angka di kanan.
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.marketStatsTitle,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final (label, value) in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(value, style: textTheme.bodyMedium),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
