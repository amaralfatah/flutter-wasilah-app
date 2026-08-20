import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/asset_list_item.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_list_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/async_value_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/refreshable_page_body.dart';
import 'package:flutter_wasilah_app/shared/widgets/section_header.dart';
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'asset_list_create_asset_fab',
        onPressed: () => context.push(RouteNames.assetCreate),
        tooltip: 'Tambah aset',
        child: const Icon(Icons.add),
      ),
      body: AsyncValueView(
        value: assetsValue,
        onRetry: () => ref.invalidate(assetListProvider),
        data: (assets) {
          if (assets.isEmpty) {
            return RefreshablePageBody(
              onRefresh: () => ref.refresh(assetListProvider.future),
              padding: _assetListPagePadding,
              child: AppEmptyState(
                title: 'Belum ada aset',
                message: 'Tambahkan aset pertama untuk mulai mencatat nilai.',
                actionLabel: 'Tambah aset',
                onAction: () => context.push(RouteNames.assetCreate),
              ),
            );
          }

          return RefreshablePageBody(
            onRefresh: () => ref.refresh(assetListProvider.future),
            padding: _assetListPagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, entry)
                    in _groupByCategory(assets).entries.indexed) ...[
                  if (index > 0) const SizedBox(height: AppSpacing.xl),
                  SectionHeader(title: entry.key.label),
                  const SizedBox(height: AppSpacing.md),
                  AppListCard(
                    children: entry.value
                        .map(
                          (asset) => AssetListItem(
                            asset: asset,
                            showCategory: false,
                            onTap: () =>
                                context.push('${RouteNames.assets}/${asset.id}'),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Kelompokkan aset per kategori dengan urutan tetap mengikuti urutan
  /// deklarasi [AssetCategory], supaya posisi grup tidak melompat saat nilai
  /// aset berubah. Kategori tanpa aset tidak muncul.
  Map<AssetCategory, List<Asset>> _groupByCategory(List<Asset> assets) {
    final grouped = <AssetCategory, List<Asset>>{};
    for (final category in AssetCategory.values) {
      final items = assets
          .where((asset) => asset.category == category)
          .toList(growable: false);
      if (items.isNotEmpty) {
        grouped[category] = items;
      }
    }
    return grouped;
  }
}
