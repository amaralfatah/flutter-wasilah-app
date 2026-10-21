import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/features/market/providers/market_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/utils/asset_category_l10n.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/asset_category_icon.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/history_row.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/holding_metrics_list.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/record_purchase_sheet.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/update_value_bar.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/update_asset_value_controller.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_error_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_loading.dart';
import 'package:flutter_wasilah_app/shared/widgets/confirm_dialog.dart';
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

        return Scaffold(
          // Keluarkan menghapus nilai & histori, jadi tidak disejajarkan
          // dengan aksi harian di bar bawah (mudah dikira tombol jual).
          appBar: _HoldingDetailAppBar(
            onRemoveFromPortfolio: () => unawaited(_removeFromPortfolio(asset)),
          ),
          bottomNavigationBar: UpdateValueBar(
            assetId: asset.id,
            // Kas tak punya harga beli; nilainya ditambah lewat Catat nilai.
            onRecordPurchase: asset.category == AssetCategory.cash
                ? null
                : () => unawaited(showRecordPurchaseSheet(context, position)),
          ),
          body: RefreshablePageBody(
            onRefresh: () {
              ref.invalidate(assetHistoryProvider(assetId));
              if (asset.marketSymbol case final marketSymbol?) {
                ref
                  ..invalidate(marketQuoteProvider(marketSymbol))
                  ..invalidate(holdingQuotesProvider);
              }
              return ref.refresh(positionDetailProvider(assetId).future);
            },
            // Horizontal 0: AppListCard (metrik & riwayat) full-bleed sampai
            // tepi layar. Konten lain mengatur padding horizontalnya sendiri.
            padding: const EdgeInsets.all(AppSpacing.lg),
            // Susunan "Portfolio Detail" Stockbit: kartu identitas, kartu
            // metrik, kartu alokasi, lalu kartu histori.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  onTap: asset.marketSymbol == null
                      ? null
                      : () => context.push(
                          '${RouteNames.portfolio}/${asset.id}/'
                          '${RouteNames.portfolioMarketSegment}',
                        ),
                  child: _AssetHeader(asset: asset),
                ),
                const SizedBox(height: AppSpacing.md),
                HoldingMetricsList(position: position),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _AllocationRow(
                    label: l10n.allocationLabel,
                    percentage: position.allocationPercentage,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _HistoryCard(
                  history: historyValue,
                  onViewAll: () => context.push(
                    '${RouteNames.portfolio}/${asset.id}/'
                    '${RouteNames.portfolioHistorySegment}',
                  ),
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
}

class _HoldingDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _HoldingDetailAppBar({this.onRemoveFromPortfolio});

  final VoidCallback? onRemoveFromPortfolio;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onRemove = onRemoveFromPortfolio;

    return AppBar(
      title: Text(l10n.holdingDetailTitle),
      actions: [
        if (onRemove != null)
          PopupMenuButton<VoidCallback>(
            tooltip: l10n.moreActionsTooltip,
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => action(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: onRemove,
                child: Text(
                  l10n.removeFromPortfolioButton,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Kartu identitas Stockbit: logo, kode tebal + badge, nama abu, dan
/// chevron ke halaman harga pasar bila aset punya simbol pasar.
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
          radius: 24,
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
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
                style: textTheme.bodySmall?.copyWith(
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
    final color = Theme.of(context).colorScheme.primary;

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
        category.localizedLabel(context.l10n),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

/// Baris "Portfolio Allocation" Stockbit: label di kiri, cincin kecil dan
/// persentase tebal di kanan.
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
        SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(
            value: (percentage / 100).clamp(0, 1),
            strokeWidth: 2.5,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          formatPercentage(percentage),
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Kartu "History  See All ›" Stockbit: judul, tautan hijau ke histori
/// lengkap, dan tiga pencatatan terakhir.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.history, required this.onViewAll});

  final AsyncValue<List<AssetSnapshot>> history;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final items = history.asData?.value ?? const <AssetSnapshot>[];
    final latest = items.take(3).toList();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onViewAll,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.historySectionTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    l10n.viewAllShortLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (latest.isNotEmpty) ...[
            const Divider(),
            const HistoryTableHeader(horizontalPadding: AppSpacing.lg),
            const Divider(),
            for (var i = 0; i < latest.length; i++)
              HistoryRow(
                snapshot: latest[i],
                previous: i + 1 < items.length ? items[i + 1] : null,
                horizontalPadding: AppSpacing.lg,
              ),
          ],
        ],
      ),
    );
  }
}
