import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/app/router/route_names.dart';
import 'package:flutter_wasilah_app/app/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/core/widgets/app_card.dart';
import 'package:flutter_wasilah_app/core/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/core/widgets/async_value_view.dart';
import 'package:flutter_wasilah_app/core/widgets/refreshable_page_body.dart';
import 'package:flutter_wasilah_app/core/widgets/section_header.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/widgets/asset_list_item.dart';
import 'package:go_router/go_router.dart';

const _assetListPagePadding = EdgeInsets.fromLTRB(
  AppSpacing.xl,
  AppSpacing.xl,
  AppSpacing.xl,
  AppSpacing.xxxl + (kFloatingActionButtonMargin * 3),
);

class AssetListPage extends ConsumerWidget {
  const AssetListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsValue = ref.watch(assetListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Aset')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'asset_list_create_asset_fab',
        onPressed: () => context.push(RouteNames.assetCreate),
        icon: const Icon(Icons.add_outlined),
        label: const Text('Tambah aset'),
        tooltip: 'Tambah aset',
      ),
      body: AsyncValueView(
        value: assetsValue,
        onRetry: () => ref.invalidate(assetListProvider),
        data: (assets) {
          if (assets.isEmpty) {
            return RefreshablePageBody(
              onRefresh: () => ref.refresh(assetListProvider.future),
              padding: _assetListPagePadding,
              child: const AppEmptyState(
                title: 'Belum ada aset',
                message: 'Tambahkan aset pertama untuk mulai mencatat nilai.',
              ),
            );
          }

          final latestUpdate = assets
              .map((asset) => asset.lastUpdatedAt)
              .reduce((latest, next) => latest.isAfter(next) ? latest : next);

          return RefreshablePageBody(
            onRefresh: () => ref.refresh(assetListProvider.future),
            padding: _assetListPagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lihat semua aset beserta nilai terkini dan proporsinya di portofolio.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${assets.length} aset aktif',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Terakhir diperbarui ${formatFullDate(latestUpdate)}.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Daftar aset'),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    children: _assetItems(
                      assets
                          .map(
                            (asset) => AssetListItem(
                              asset: asset,
                              onTap: () => context.push(
                                '${RouteNames.assets}/${asset.id}',
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _assetItems(List<Widget> items) {
    final widgets = <Widget>[];

    for (var index = 0; index < items.length; index++) {
      widgets.add(items[index]);
      if (index < items.length - 1) {
        widgets.add(const Divider(height: AppSpacing.xl));
      }
    }

    return widgets;
  }
}
