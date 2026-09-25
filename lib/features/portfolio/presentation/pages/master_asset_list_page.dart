import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/features/market/presentation/widgets/market_sparkline.dart';
import 'package:flutter_wasilah_app/features/market/providers/market_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/asset_category_icon.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/async_value_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/refreshable_page_body.dart';
import 'package:go_router/go_router.dart';

/// Daftar master aset: identitas aset saja (nama, kode, kategori, simbol
/// pasar), tanpa nilai. Nilai dicatat di halaman Portofolio.
class MasterAssetListPage extends ConsumerWidget {
  const MasterAssetListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsValue = ref.watch(assetListProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.masterAssetsTitle)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'master_asset_create_fab',
        onPressed: () => context.push(RouteNames.masterAssetCreate),
        tooltip: l10n.addAssetTooltip,
        child: const Icon(Icons.add),
      ),
      body: AsyncValueView(
        value: assetsValue,
        onRetry: () => ref.invalidate(assetListProvider),
        data: (assets) {
          return RefreshablePageBody(
            onRefresh: () => ref.refresh(assetListProvider.future),
            // Horizontal 0: baris full-bleed sampai tepi layar.
            padding: const EdgeInsets.fromLTRB(
              0,
              AppSpacing.sm,
              0,
              AppSpacing.xxxl + (kFloatingActionButtonMargin * 3),
            ),
            child: assets.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: AppEmptyState(
                      title: l10n.commonEmptyAssetsTitle,
                      message: l10n.emptyMasterAssetsMessage,
                      actionLabel: l10n.commonAddAssetLabel,
                      onAction: () =>
                          context.push(RouteNames.masterAssetCreate),
                    ),
                  )
                : Column(
                    children: [
                      for (final (index, asset) in assets.indexed) ...[
                        if (index > 0) const Divider(height: 1),
                        _MasterAssetTile(asset),
                      ],
                    ],
                  ),
          );
        },
      ),
    );
  }
}

/// Baris gaya watchlist Stockbit: logo, kode + nama, sparkline intraday,
/// lalu harga terkini dan perubahan harian. Aset tanpa simbol pasar (mis.
/// kas) hanya menampilkan kategorinya di kanan.
class _MasterAssetTile extends ConsumerWidget {
  const _MasterAssetTile(this.asset);

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final symbol = asset.marketSymbol;

    return InkWell(
      onTap: () => context.push('${RouteNames.masterAssets}/${asset.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            AssetCategoryIcon(
              category: asset.category,
              marketSymbol: symbol,
              radius: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: mutedColor),
                  ),
                ],
              ),
            ),
            if (symbol == null)
              Text(
                asset.category.label,
                style: textTheme.bodySmall?.copyWith(color: mutedColor),
              )
            else
              _MarketColumns(symbol: symbol),
          ],
        ),
      ),
    );
  }
}

class _MarketColumns extends ConsumerWidget {
  const _MarketColumns({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final l10n = context.l10n;

    return ref
        .watch(marketQuoteProvider(symbol))
        .when(
          data: (result) {
            final quote = result.quote;
            final change = quote.change;
            final changePercent = quote.changePercent;
            final changeColor = change == null || change == 0
                ? mutedColor
                : change > 0
                ? AppColors.positiveOf(context)
                : AppColors.negativeOf(context);
            final series = result.oneDaySeries?.points
                .map((point) => point.close)
                .toList(growable: false);
            final isIdr = quote.currency == 'IDR';
            String signed(double value) => isIdr
                ? formatSignedNumber(value)
                : formatSignedPrice(value, quote.currency);
            final changeText =
                result.isStale || change == null || changePercent == null
                ? l10n.marketOfflineChip
                : '${signed(change)} '
                      '(${formatSignedChangePercentage(changePercent)})';

            return Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 32,
                  child: series == null
                      ? null
                      : MarketSparkline(
                          values: series,
                          baseline: quote.previousClose,
                          color: changeColor,
                        ),
                ),
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  width: 112,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isIdr
                              ? formatNumber(quote.price)
                              : formatPrice(quote.price, quote.currency),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          changeText,
                          style: textTheme.bodySmall?.copyWith(
                            color: result.isStale ? mutedColor : changeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (error, stackTrace) => Text(
            l10n.marketUnavailableShort,
            style: textTheme.bodySmall?.copyWith(color: mutedColor),
          ),
        );
  }
}
