import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/app/router/route_names.dart';
import 'package:flutter_wasilah_app/app/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/core/widgets/app_card.dart';
import 'package:flutter_wasilah_app/core/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/core/widgets/app_error_view.dart';
import 'package:flutter_wasilah_app/core/widgets/app_loading.dart';
import 'package:flutter_wasilah_app/core/widgets/refreshable_page_body.dart';
import 'package:flutter_wasilah_app/core/widgets/section_header.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/widgets/asset_category_icon.dart';
import 'package:flutter_wasilah_app/features/portfolio/widgets/history_line_chart.dart';
import 'package:go_router/go_router.dart';

class AssetDetailPage extends ConsumerWidget {
  const AssetDetailPage({super.key, required this.assetId});

  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetValue = ref.watch(assetDetailProvider(assetId));
    final historyValue = ref.watch(assetHistoryProvider(assetId));

    return assetValue.when(
      data: (asset) {
        if (asset == null) {
          return const Scaffold(
            appBar: _AssetDetailAppBar(),
            body: AppEmptyState(
              title: 'Aset tidak ditemukan',
              message: 'Data aset yang Anda buka tidak tersedia.',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AssetHeader(asset: asset),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _MetricTile(
                        label: 'Nilai saat ini',
                        value: formatCurrency(asset.currentValue),
                      ),
                      const Divider(height: 1),
                      _MetricTile(
                        label: 'Alokasi portofolio',
                        value:
                            '${asset.allocationPercentage.toStringAsFixed(0)}%',
                      ),
                      const Divider(height: 1),
                      _MetricTile(
                        label: 'Terakhir diperbarui',
                        value: formatFullDate(asset.lastUpdatedAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () =>
                      context.push('${RouteNames.assets}/${asset.id}/update'),
                  child: const Text('Update nilai'),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Histori nilai'),
                const SizedBox(height: AppSpacing.md),
                historyValue.when(
                  data: (history) {
                    if (history.isEmpty) {
                      return const AppEmptyState(
                        title: 'Belum ada histori',
                        message: 'Histori muncul setelah nilai diperbarui.',
                        icon: Icons.timeline_outlined,
                      );
                    }

                    return Column(
                      children: [
                        HistoryLineChart(history: history.reversed.toList()),
                        if (history.length > 1)
                          const SizedBox(height: AppSpacing.lg),
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (
                                var index = 0;
                                index < history.length;
                                index++
                              ) ...[
                                Dismissible(
                                  key: ValueKey(history[index].id),
                                  direction: DismissDirection.endToStart,
                                  background: const _DeleteBackground(),
                                  confirmDismiss: (_) =>
                                      _confirmDeleteSnapshot(context),
                                  onDismissed: (_) => _deleteSnapshot(
                                    ref,
                                    assetId,
                                    history[index].id,
                                  ),
                                  child: _HistoryTile(
                                    snapshot: history[index],
                                  ),
                                ),
                                if (index < history.length - 1)
                                  const Divider(height: 1),
                              ],
                            ],
                          ),
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
}

Future<bool> _confirmDeleteSnapshot(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Hapus histori?'),
      content: const Text('Entri histori bulan ini akan dihapus.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}

Future<void> _deleteSnapshot(
  WidgetRef ref,
  String assetId,
  String snapshotId,
) async {
  await ref.read(portfolioRepositoryProvider).deleteSnapshot(snapshotId);
  ref.invalidate(assetHistoryProvider(assetId));
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      alignment: Alignment.centerRight,
      child: Icon(
        Icons.delete_outline,
        color: Theme.of(context).colorScheme.onErrorContainer,
      ),
    );
  }
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

    return AppBar(
      title: const Text('Detail aset'),
      actions: [
        if (asset != null)
          IconButton(
            tooltip: 'Edit aset',
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
      crossAxisAlignment: CrossAxisAlignment.center,
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
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.snapshot});

  final AssetSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.event_note_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(formatMonthYear(snapshot.recordedAt)),
      subtitle: snapshot.note == null ? null : Text(snapshot.note!),
      trailing: Text(
        formatCurrency(snapshot.totalValue),
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.end,
      ),
    );
  }
}
