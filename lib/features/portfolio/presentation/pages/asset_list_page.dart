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

          // Aset bernilai 0 sudah dijual/habis tapi belum dihapus; pisahkan
          // supaya tidak menyesaki list aktif tapi datanya tetap tersimpan.
          final activeAssets = assets
              .where((asset) => asset.currentValue != 0)
              .toList(growable: false);
          final archivedAssets = assets
              .where((asset) => asset.currentValue == 0)
              .toList(growable: false);

          return RefreshablePageBody(
            onRefresh: () => ref.refresh(assetListProvider.future),
            padding: _assetListPagePadding,
            // Aset sudah datang terurut dari nilai terbesar (lihat
            // getAssets di repository), jadi satu list tanpa pengelompokan
            // kategori sudah cukup jelas.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (activeAssets.isNotEmpty)
                  AppListCard(
                    children: [
                      const AssetTableHeader(),
                      ...activeAssets.map(
                        (asset) => AssetListItem(
                          asset: asset,
                          onTap: () =>
                              context.push('${RouteNames.assets}/${asset.id}'),
                        ),
                      ),
                    ],
                  ),
                if (archivedAssets.isNotEmpty) ...[
                  if (activeAssets.isNotEmpty)
                    const SizedBox(height: AppSpacing.xl),
                  _ArchivedAssetsSection(
                    assets: archivedAssets,
                    onTapAsset: (asset) =>
                        context.push('${RouteNames.assets}/${asset.id}'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Bagian "Aset nonaktif" bisa dibuka/tutup: aset bernilai 0 bukan hal yang
/// perlu dilihat tiap buka tab, tapi tetap bisa dicari saat dibutuhkan.
class _ArchivedAssetsSection extends StatelessWidget {
  const _ArchivedAssetsSection({
    required this.assets,
    required this.onTapAsset,
  });

  final List<Asset> assets;
  final ValueChanged<Asset> onTapAsset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mutedColor = colorScheme.onSurfaceVariant;

    // Sengaja tanpa Card/elevasi: dulu section ini sama menonjolnya dengan
    // daftar aset aktif, padahal isinya cuma arsip yang jarang dilihat.
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTileTheme(
          data: ExpansionTileThemeData(
            iconColor: mutedColor,
            collapsedIconColor: mutedColor,
          ),
          child: ExpansionTile(
            title: Text(
              'Aset nonaktif',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: mutedColor),
            ),
            childrenPadding: EdgeInsets.zero,
            children: [
              const Divider(height: 1),
              const AssetTableHeader(),
              ...assets.map(
                (asset) => AssetListItem(
                  asset: asset,
                  onTap: () => onTapAsset(asset),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
