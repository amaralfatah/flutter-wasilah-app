import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/features/market/data/models/market_quote.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';

/// Section "Data Perdagangan" ala Stockbit: grid dua kolom berisi statistik
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.marketStatsTitle,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        // Dua kolom rata; tiap sel: label kecil di atas, nilai tebal di bawah.
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.lg,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 3.4,
          children: [
            for (final (label, value) in entries)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
