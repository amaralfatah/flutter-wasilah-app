import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/features/market/data/market_repository.dart';
import 'package:flutter_wasilah_app/features/market/data/models/chart_range.dart';
import 'package:flutter_wasilah_app/features/market/data/models/market_quote.dart';
import 'package:flutter_wasilah_app/features/market/data/models/price_series.dart';
import 'package:flutter_wasilah_app/features/market/presentation/chart_math.dart';
import 'package:flutter_wasilah_app/features/market/presentation/widgets/chart_range_tabs.dart';
import 'package:flutter_wasilah_app/features/market/presentation/widgets/market_quote_header.dart';
import 'package:flutter_wasilah_app/features/market/presentation/widgets/market_stats_grid.dart';
import 'package:flutter_wasilah_app/features/market/presentation/widgets/price_line_chart.dart';
import 'package:flutter_wasilah_app/features/market/providers/market_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_error_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_loading.dart';
import 'package:flutter_wasilah_app/shared/widgets/refreshable_page_body.dart';
import 'package:go_router/go_router.dart';

/// Halaman Detail Pasar ala Stockbit: harga, perubahan, dan chart Yahoo
/// Finance untuk simbol pasar sebuah aset. Dibuka dari kartu "Harga Pasar"
/// di halaman detail aset.
class MarketDetailPage extends ConsumerStatefulWidget {
  const MarketDetailPage({required this.assetId, super.key});

  final String assetId;

  @override
  ConsumerState<MarketDetailPage> createState() => _MarketDetailPageState();
}

class _MarketDetailPageState extends ConsumerState<MarketDetailPage> {
  ChartRange _range = ChartRange.oneDay;
  PricePoint? _scrubPoint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final assetValue = ref.watch(assetDetailProvider(widget.assetId));

    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            tooltip: l10n.editAssetTooltip,
            onSelected: (value) {
              if (value == 'edit') {
                context.push('${RouteNames.assets}/${widget.assetId}/edit');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Text(l10n.editAssetTooltip),
              ),
            ],
          ),
        ],
      ),
      body: assetValue.when(
        data: (asset) {
          final symbol = asset?.marketSymbol;
          if (asset == null || symbol == null) {
            return AppEmptyState(
              title: l10n.assetNotFoundTitle,
              message: l10n.assetNotFoundMessage,
            );
          }
          return _MarketDetailBody(
            asset: asset,
            symbol: symbol,
            range: _range,
            scrubPoint: _scrubPoint,
            onRangeChanged: (range) => setState(() {
              _range = range;
              _scrubPoint = null;
            }),
            onScrub: (point) => setState(() => _scrubPoint = point),
          );
        },
        loading: () => const AppLoading(),
        error: (error, stackTrace) =>
            AppErrorView(message: l10n.marketUnavailable),
      ),
    );
  }
}

class _MarketDetailBody extends ConsumerWidget {
  const _MarketDetailBody({
    required this.asset,
    required this.symbol,
    required this.range,
    required this.scrubPoint,
    required this.onRangeChanged,
    required this.onScrub,
  });

  final Asset asset;
  final String symbol;
  final ChartRange range;
  final PricePoint? scrubPoint;
  final ValueChanged<ChartRange> onRangeChanged;
  final ValueChanged<PricePoint?> onScrub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final quoteAsync = ref.watch(marketQuoteProvider(symbol));

    final updateButton = _UpdateValueButton(assetId: asset.id);

    return RefreshablePageBody(
      onRefresh: () async {
        ref
          ..invalidate(marketQuoteProvider(symbol))
          ..invalidate(priceChartProvider);
      },
      // Padding samping 16dp dan atas tipis, seperti Stockbit.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: quoteAsync.when(
        data: (quoteResult) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildChartSection(context, ref, quoteResult),
            const SizedBox(height: AppSpacing.lg),
            if (quoteResult.quote.hasTradingStats) ...[
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.lg),
              MarketStatsGrid(quote: quoteResult.quote),
              const SizedBox(height: AppSpacing.lg),
            ],
            updateButton,
          ],
        ),
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(asset.code, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xl),
            const AppLoading(),
            const SizedBox(height: AppSpacing.xl),
            updateButton,
          ],
        ),
        error: (error, stackTrace) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error is MarketSymbolNotFoundException)
              AppEmptyState(
                title: l10n.marketPriceTitle,
                message: l10n.marketSymbolNotFound(symbol),
                actionLabel: l10n.editAssetButton,
                onAction: () => GoRouter.of(
                  context,
                ).push('${RouteNames.assets}/${asset.id}/edit'),
              )
            else
              AppErrorView(message: l10n.marketUnavailable),
            const SizedBox(height: AppSpacing.xl),
            updateButton,
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(
    BuildContext context,
    WidgetRef ref,
    QuoteResult quoteResult,
  ) {
    final chartAsync = ref.watch(
      priceChartProvider((symbol: symbol, range: range)),
    );

    return chartAsync.when(
      data: (series) {
        final reference = referencePrice(range, quoteResult.quote, series);
        return _MarketDetailContent(
          asset: asset,
          quote: quoteResult.quote,
          isStale: quoteResult.isStale,
          range: range,
          referencePrice: reference,
          scrubPoint: scrubPoint,
          points: series.points,
          onRangeChanged: onRangeChanged,
          onScrub: onScrub,
        );
      },
      loading: () => _MarketDetailContent(
        asset: asset,
        quote: quoteResult.quote,
        isStale: quoteResult.isStale,
        range: range,
        referencePrice: referencePrice(range, quoteResult.quote, null),
        scrubPoint: scrubPoint,
        points: const [],
        isChartLoading: true,
        onRangeChanged: onRangeChanged,
        onScrub: onScrub,
      ),
      error: (error, stackTrace) => _MarketDetailContent(
        asset: asset,
        quote: quoteResult.quote,
        isStale: quoteResult.isStale,
        range: range,
        referencePrice: referencePrice(range, quoteResult.quote, null),
        scrubPoint: scrubPoint,
        points: const [],
        onRangeChanged: onRangeChanged,
        onScrub: onScrub,
      ),
    );
  }
}

class _MarketDetailContent extends StatelessWidget {
  const _MarketDetailContent({
    required this.asset,
    required this.quote,
    required this.isStale,
    required this.range,
    required this.referencePrice,
    required this.scrubPoint,
    required this.points,
    required this.onRangeChanged,
    required this.onScrub,
    this.isChartLoading = false,
  });

  final Asset asset;
  final MarketQuote quote;
  final bool isStale;
  final ChartRange range;
  final double? referencePrice;
  final PricePoint? scrubPoint;
  final List<PricePoint> points;
  final bool isChartLoading;
  final ValueChanged<ChartRange> onRangeChanged;
  final ValueChanged<PricePoint?> onScrub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MarketQuoteHeader(
          asset: asset,
          quote: quote,
          isStale: isStale,
          range: range,
          referencePrice: referencePrice,
          scrubPoint: scrubPoint,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (isChartLoading)
          const SizedBox(height: 200, child: AppLoading())
        else
          PriceLineChart(
            points: points,
            referencePrice: referencePrice,
            currency: quote.currency,
            onScrub: onScrub,
          ),
        const SizedBox(height: AppSpacing.sm),
        ChartRangeTabs(selected: range, onSelected: onRangeChanged),
      ],
    );
  }
}

/// Satu-satunya tombol aksi (pengganti Jual/Beli Stockbit), setinggi 48dp.
class _UpdateValueButton extends StatelessWidget {
  const _UpdateValueButton({required this.assetId});

  final String assetId;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      onPressed: () =>
          GoRouter.of(context).push('${RouteNames.assets}/$assetId/update'),
      child: Text(
        context.l10n.updateValueButton,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}
