import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/features/market/providers/market_providers.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';
import 'package:go_router/go_router.dart';

/// Kartu ringkas harga pasar di halaman detail aset. Tap membuka halaman
/// Detail Pasar (`.../market`) untuk chart & rincian lengkap.
class MarketPriceTile extends ConsumerWidget {
  const MarketPriceTile({
    required this.assetId,
    required this.symbol,
    super.key,
  });

  final String assetId;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final quoteValue = ref.watch(marketQuoteProvider(symbol));
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: () => context.push(
        '${RouteNames.portfolio}/$assetId/${RouteNames.portfolioMarketSegment}',
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.marketPriceTitle} · $symbol',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                quoteValue.when(
                  data: (result) => _PriceRow(
                    price: formatPrice(
                      result.quote.price,
                      result.quote.currency,
                    ),
                    change: result.quote.change,
                    changePercent: result.quote.changePercent,
                    isStale: result.isStale,
                  ),
                  loading: () => Text(
                    l10n.marketLoading,
                    style: textTheme.bodyMedium,
                  ),
                  error: (error, stackTrace) => Text(
                    l10n.marketUnavailableShort,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.price,
    required this.change,
    required this.changePercent,
    required this.isStale,
  });

  final String price;
  final double? change;
  final double? changePercent;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final change = this.change;
    final changePercent = this.changePercent;
    final isPositive = (change ?? 0) >= 0;
    final changeColor = change == null
        ? colorScheme.onSurfaceVariant
        : isPositive
        ? AppColors.positiveOf(context)
        : AppColors.negativeOf(context);

    return Row(
      children: [
        Text(price, style: textTheme.titleMedium),
        if (change != null && changePercent != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(
            isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            color: changeColor,
          ),
          Text(
            '${formatSignedNumber(change)} '
            '(${formatSignedChangePercentage(changePercent)})',
            style: textTheme.bodyMedium?.copyWith(color: changeColor),
          ),
        ],
        if (isStale) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n.marketOfflineChip,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
