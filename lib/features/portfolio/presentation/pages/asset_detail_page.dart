import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/profit_loss_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/asset_category_icon.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/history_line_chart.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/history_row.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_error_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_list_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_loading.dart';
import 'package:flutter_wasilah_app/shared/widgets/confirm_dialog.dart';
import 'package:flutter_wasilah_app/shared/widgets/delete_swipe_background.dart';
import 'package:flutter_wasilah_app/shared/widgets/refreshable_page_body.dart';
import 'package:flutter_wasilah_app/shared/widgets/section_header.dart';
import 'package:go_router/go_router.dart';

class AssetDetailPage extends ConsumerStatefulWidget {
  const AssetDetailPage({required this.assetId, super.key});

  final String assetId;

  @override
  ConsumerState<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends ConsumerState<AssetDetailPage> {
  final Set<String> _removedIds = {};

  String get assetId => widget.assetId;

  @override
  Widget build(BuildContext context) {
    final assetValue = ref.watch(assetDetailProvider(assetId));
    final historyValue = ref.watch(assetHistoryProvider(assetId));
    final l10n = context.l10n;

    return assetValue.when(
      data: (asset) {
        if (asset == null) {
          return Scaffold(
            appBar: const _AssetDetailAppBar(),
            body: AppEmptyState(
              title: l10n.assetNotFoundTitle,
              message: l10n.assetNotFoundMessage,
            ),
          );
        }

        return Scaffold(
          appBar: _AssetDetailAppBar(asset: asset),
          body: RefreshablePageBody(
            onRefresh: () {
              ref.invalidate(assetHistoryProvider(assetId));
              return ref.refresh(assetDetailProvider(assetId).future);
            },
            // Horizontal 0: AppListCard (metrik & riwayat) full-bleed sampai
            // tepi layar. Konten lain mengatur padding horizontalnya sendiri.
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: _AssetHeader(asset: asset),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppListCard(
                  children: [
                    _MetricTile(
                      label: l10n.commonCurrentValueLabel,
                      value: formatCurrency(asset.currentValue),
                    ),
                    if (asset.totalCost case final totalCost?) ...[
                      _MetricTile(
                        label: l10n.totalCostLabel,
                        value: formatCurrency(totalCost),
                      ),
                      _ProfitLossTile(asset: asset),
                    ],
                    _MetricTile(
                      label: l10n.allocationLabel,
                      value: formatPercentage(asset.allocationPercentage),
                    ),
                    _MetricTile(
                      label: l10n.lastUpdatedLabel,
                      value: formatFullDate(
                        asset.lastUpdatedAt,
                        Localizations.localeOf(context),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        onPressed: () => context.push(
                          '${RouteNames.assets}/${asset.id}/update',
                        ),
                        child: Text(l10n.updateValueButton),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SectionHeader(title: l10n.historySectionTitle),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                historyValue.when(
                  data: (fullHistory) {
                    final history = fullHistory
                        .where((item) => !_removedIds.contains(item.id))
                        .toList();

                    if (history.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: AppEmptyState(
                          title: l10n.commonEmptyHistoryTitle,
                          message: l10n.emptyAssetHistoryMessage,
                          icon: Icons.timeline_outlined,
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                          ),
                          child: HistoryLineChart(
                            history: history.reversed.toList(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
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
                                  child: HistoryRow(snapshot: snapshot),
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
          const Scaffold(appBar: _AssetDetailAppBar(), body: AppLoading()),
      error: (error, stackTrace) => Scaffold(
        appBar: const _AssetDetailAppBar(),
        body: AppErrorView(
          onRetry: () => ref.invalidate(assetDetailProvider(assetId)),
        ),
      ),
    );
  }

  Future<void> _deleteSnapshot(String assetId, String snapshotId) async {
    final l10n = context.l10n;
    try {
      await ref.read(portfolioRepositoryProvider).deleteSnapshot(snapshotId);
      ref.invalidate(assetHistoryProvider(assetId));
      ref.invalidate(assetDetailProvider(assetId));
      ref.invalidate(portfolioSummaryProvider);
      ref.invalidate(portfolioHistoryProvider);
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

class _AssetDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _AssetDetailAppBar({this.asset});

  final Asset? asset;

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
        if (asset != null)
          IconButton(
            tooltip: l10n.editAssetTooltip,
            onPressed: () =>
                context.push('${RouteNames.assets}/${asset.id}/edit'),
            icon: const Icon(Icons.edit_outlined),
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
        AssetCategoryIcon(category: asset.category),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                asset.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${asset.code} - ${asset.category.label}',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
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
  const _ProfitLossTile({required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final profitLoss = asset.profitLoss ?? 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      title: Text(profitLossLabel(context, profitLoss)),
      trailing: Text(
        formatProfitLoss(profitLoss, cost: asset.totalCost ?? 0),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: profitLossColorOf(context, profitLoss),
        ),
        textAlign: TextAlign.end,
      ),
    );
  }
}
