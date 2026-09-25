import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/profit_loss_formatter.dart';
import 'package:flutter_wasilah_app/features/market/providers/market_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/utils/history_change_calculator.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/asset_category_icon.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/history_line_chart.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/history_row.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/update_value_bar.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/update_asset_value_controller.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_error_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_list_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_loading.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_section_band.dart';
import 'package:flutter_wasilah_app/shared/widgets/confirm_dialog.dart';
import 'package:flutter_wasilah_app/shared/widgets/delete_swipe_background.dart';
import 'package:flutter_wasilah_app/shared/widgets/refreshable_page_body.dart';
import 'package:go_router/go_router.dart';

/// Detail satu holding portofolio: nilai, modal, PnL, dan histori. Identitas
/// aset (nama, kategori, simbol) hanya ditampilkan; diubah di master aset.
class HoldingDetailPage extends ConsumerStatefulWidget {
  const HoldingDetailPage({required this.assetId, super.key});

  final String assetId;

  @override
  ConsumerState<HoldingDetailPage> createState() => _HoldingDetailPageState();
}

class _HoldingDetailPageState extends ConsumerState<HoldingDetailPage> {
  final Set<String> _removedIds = {};

  String get assetId => widget.assetId;

  @override
  Widget build(BuildContext context) {
    final positionValue = ref.watch(positionDetailProvider(assetId));
    final historyValue = ref.watch(assetHistoryProvider(assetId));
    final l10n = context.l10n;

    return positionValue.when(
      data: (position) {
        if (position == null) {
          return Scaffold(
            appBar: const _HoldingDetailAppBar(),
            body: AppEmptyState(
              title: l10n.assetNotFoundTitle,
              message: l10n.assetNotFoundMessage,
            ),
          );
        }

        final asset = position.asset;
        final isCash = asset.category == AssetCategory.cash;

        return Scaffold(
          appBar: _HoldingDetailAppBar(
            asset: asset,
            onRemoveFromPortfolio: () => _removeFromPortfolio(asset),
          ),
          bottomNavigationBar: UpdateValueBar(assetId: asset.id),
          body: RefreshablePageBody(
            onRefresh: () {
              ref.invalidate(assetHistoryProvider(assetId));
              if (asset.marketSymbol case final marketSymbol?) {
                ref.invalidate(marketQuoteProvider(marketSymbol));
              }
              return ref.refresh(positionDetailProvider(assetId).future);
            },
            // Horizontal 0: AppListCard (metrik & riwayat) full-bleed sampai
            // tepi layar. Konten lain mengatur padding horizontalnya sendiri.
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    onTap: asset.marketSymbol == null
                        ? null
                        : () => context.push(
                            '${RouteNames.portfolio}/${asset.id}/'
                            '${RouteNames.portfolioMarketSegment}',
                          ),
                    child: _AssetHeader(asset: asset),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const AppSectionBand(),
                AppListCard(
                  children: [
                    _MetricTile(
                      label: l10n.commonCurrentValueLabel,
                      value: formatCurrency(position.currentValue),
                    ),
                    // Kas tak untung/rugi (modal = nilai), jadi modal &
                    // untung/rugi hanya mengulang nilai.
                    if (position.totalCost case final totalCost?
                        when !isCash) ...[
                      _MetricTile(
                        label: l10n.totalCostLabel,
                        value: formatCurrency(totalCost),
                      ),
                      _ProfitLossTile(position: position),
                    ],
                    if (position.avgBuyPrice case final avgBuyPrice?)
                      _MetricTile(
                        label: l10n.avgBuyPriceLabel,
                        value: formatAvgPrice(
                          avgBuyPrice,
                          position.effectivePriceCurrency,
                        ),
                      ),
                    if (position.quantity case final quantity?)
                      _MetricTile(
                        label: l10n.quantityLabel,
                        value: formatQuantity(quantity),
                      ),
                    _MetricTile(
                      label: l10n.lastUpdatedLabel,
                      value: formatFullDate(
                        position.lastUpdatedAt,
                        Localizations.localeOf(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const AppSectionBand(),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: _AllocationRow(
                      label: l10n.allocationLabel,
                      percentage: position.allocationPercentage,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSectionBand(label: l10n.historySectionTitle),
                const SizedBox(height: AppSpacing.lg),
                historyValue.when(
                  data: (fullHistory) {
                    final history = fullHistory
                        .where((item) => !_removedIds.contains(item.id))
                        .toList();

                    if (history.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: AppEmptyState(
                          title: l10n.commonEmptyHistoryTitle,
                          message: l10n.emptyAssetHistoryMessage,
                          icon: Icons.timeline_outlined,
                        ),
                      );
                    }

                    final changeMap = buildHistoryChangeMap(history);
                    final firstSnapshotId = history.last.id;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: HistoryLineChart(
                            history: history.reversed.toList(),
                            showCost: !isCash,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const AppSectionBand(),
                        AppListCard(
                          children: history
                              .map(
                                (snapshot) => Dismissible(
                                  key: ValueKey(snapshot.id),
                                  direction: DismissDirection.endToStart,
                                  background: const DeleteSwipeBackground(),
                                  confirmDismiss: (_) =>
                                      _confirmDeleteSnapshot(context),
                                  onDismissed: (_) {
                                    setState(
                                      () => _removedIds.add(snapshot.id),
                                    );
                                    _deleteSnapshot(assetId, snapshot.id);
                                  },
                                  child: HistoryRow(
                                    snapshot: snapshot,
                                    changeLabel: formatHistoryChange(
                                      changeMap[snapshot.id],
                                      isFirstSnapshot:
                                          snapshot.id == firstSnapshotId,
                                      initialDataLabel: l10n.initialDataLabel,
                                    ),
                                    changeColor: historyChangeColor(
                                      context,
                                      changeMap[snapshot.id],
                                      isFirstSnapshot:
                                          snapshot.id == firstSnapshotId,
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    );
                  },
                  loading: () => const AppLoading(),
                  error: (error, stackTrace) => const AppErrorView(),
                ),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(appBar: _HoldingDetailAppBar(), body: AppLoading()),
      error: (error, stackTrace) => Scaffold(
        appBar: const _HoldingDetailAppBar(),
        body: AppErrorView(
          onRetry: () => ref.invalidate(positionDetailProvider(assetId)),
        ),
      ),
    );
  }

  Future<void> _removeFromPortfolio(Asset asset) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.removeFromPortfolioTitle,
      message: l10n.removeFromPortfolioMessage(asset.name),
      confirmLabel: l10n.removeFromPortfolioButton,
      isDestructive: true,
    );
    if (!confirmed) {
      return;
    }

    try {
      await ref
          .read(updateAssetValueControllerProvider.notifier)
          .removeFromPortfolio(asset.id);
      if (!mounted) return;
      context.pop();
    } on Exception catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.updateAssetValueFailedMessage)),
      );
    }
  }

  Future<void> _deleteSnapshot(String assetId, String snapshotId) async {
    final l10n = context.l10n;
    try {
      await ref
          .read(portfolioRepositoryProvider)
          .deleteAssetSnapshot(snapshotId);
      ref
        ..invalidate(assetHistoryProvider(assetId))
        ..invalidate(positionDetailProvider(assetId))
        ..invalidate(positionListProvider)
        ..invalidate(portfolioSummaryProvider)
        ..invalidate(portfolioHistoryProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonHistoryDeletedMessage)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _removedIds.remove(snapshotId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonDeleteHistoryFailedMessage)),
      );
    }
  }
}

Future<bool> _confirmDeleteSnapshot(BuildContext context) {
  final l10n = context.l10n;
  return showConfirmDialog(
    context,
    title: l10n.commonDeleteHistoryTitle,
    message: l10n.commonDeleteHistoryMessage,
    confirmLabel: l10n.commonDelete,
    isDestructive: true,
  );
}

class _HoldingDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _HoldingDetailAppBar({this.asset, this.onRemoveFromPortfolio});

  final Asset? asset;
  final VoidCallback? onRemoveFromPortfolio;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final asset = this.asset;
    final l10n = context.l10n;

    return AppBar(
      // Pakai nama aset supaya konteks tidak hilang saat halaman di-scroll
      // dan header di body sudah keluar dari layar.
      title: Text(
        asset?.name ?? l10n.defaultAssetDetailTitle,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        if (onRemoveFromPortfolio case final onRemove?)
          PopupMenuButton<String>(
            onSelected: (_) => onRemove(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'remove',
                child: Text(l10n.removeFromPortfolioButton),
              ),
            ],
          ),
      ],
    );
  }
}

class _AssetHeader extends StatelessWidget {
  const _AssetHeader({required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        AssetCategoryIcon(
          category: asset.category,
          marketSymbol: asset.marketSymbol,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      asset.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _CategoryBadge(category: asset.category),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                asset.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (asset.marketSymbol != null)
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final AssetCategory category;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColorOf(context, category.index);

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
        category.label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

/// Baris alokasi porsi aset ala Stockbit: label di kiri, cincin persentase
/// di kanan — beda dari _MetricTile teks biasa supaya alokasi lebih mudah
/// dipindai saat portofolio berisi banyak aset.
class _AllocationRow extends StatelessWidget {
  const _AllocationRow({required this.label, required this.percentage});

  final String label;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(child: Text(label, style: textTheme.bodyMedium)),
        SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: (percentage / 100).clamp(0, 1),
                strokeWidth: 3,
                backgroundColor: colorScheme.outlineVariant,
                color: colorScheme.primary,
              ),
              FittedBox(
                child: Text(
                  formatPercentage(percentage),
                  style: textTheme.labelSmall?.copyWith(fontSize: 9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.end,
      ),
    );
  }
}

class _ProfitLossTile extends StatelessWidget {
  const _ProfitLossTile({required this.position});

  final PortfolioPosition position;

  @override
  Widget build(BuildContext context) {
    final profitLoss = position.profitLoss ?? 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      title: Text(profitLossLabel(context, profitLoss)),
      trailing: Text(
        formatProfitLoss(profitLoss, cost: position.totalCost ?? 0),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: profitLossColorOf(context, profitLoss),
        ),
        textAlign: TextAlign.end,
      ),
    );
  }
}
