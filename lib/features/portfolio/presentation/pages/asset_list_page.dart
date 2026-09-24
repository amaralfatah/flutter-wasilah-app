import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/asset_list_item.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_list_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_section_band.dart';
import 'package:flutter_wasilah_app/shared/widgets/async_value_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/refreshable_page_body.dart';
import 'package:go_router/go_router.dart';

// Horizontal 0: daftar aset (AppListCard/_ArchivedAssetsSection) full-bleed
// sampai tepi layar. Widget lain yang butuh jarak (mis. AppEmptyState)
// mengatur padding horizontalnya sendiri.
const _assetListPagePadding = EdgeInsets.fromLTRB(
  0,
  AppSpacing.xl,
  0,
  AppSpacing.xxxl + (kFloatingActionButtonMargin * 3),
);

class AssetListPage extends ConsumerStatefulWidget {
  const AssetListPage({super.key});

  @override
  ConsumerState<AssetListPage> createState() => _AssetListPageState();
}

class _AssetListPageState extends ConsumerState<AssetListPage> {
  AssetCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final assetsValue = ref.watch(assetListProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.assetsTitle)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'asset_list_create_asset_fab',
        onPressed: () => context.push(RouteNames.assetCreate),
        tooltip: l10n.addAssetTooltip,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: AppEmptyState(
                  title: l10n.commonEmptyAssetsTitle,
                  message: l10n.emptyAssetsListMessage,
                  actionLabel: l10n.commonAddAssetLabel,
                  onAction: () => context.push(RouteNames.assetCreate),
                ),
              ),
            );
          }

          // Chip kategori hanya untuk kategori yang benar-benar dipakai,
          // supaya tidak menampilkan filter yang pasti kosong.
          final categories = {for (final asset in assets) asset.category};
          final filteredAssets = _selectedCategory == null
              ? assets
              : assets
                    .where((asset) => asset.category == _selectedCategory)
                    .toList(growable: false);

          // Aset bernilai 0 sudah dijual/habis tapi belum dihapus; pisahkan
          // supaya tidak menyesaki list aktif tapi datanya tetap tersimpan.
          final activeAssets = filteredAssets
              .where((asset) => asset.currentValue != 0)
              .toList(growable: false);
          final archivedAssets = filteredAssets
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
                if (categories.length > 1) ...[
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      children: [
                        ChoiceChip(
                          label: Text(l10n.allFilterLabel),
                          selected: _selectedCategory == null,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = null),
                        ),
                        for (final category in categories) ...[
                          const SizedBox(width: AppSpacing.sm),
                          ChoiceChip(
                            label: Text(category.label),
                            selected: _selectedCategory == category,
                            onSelected: (_) =>
                                setState(() => _selectedCategory = category),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
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
                  if (activeAssets.isNotEmpty) const AppSectionBand(),
                  _ArchivedAssetsSection(
                    assets: archivedAssets,
                    onTapAsset: (asset) =>
                        context.push('${RouteNames.assets}/${asset.id}'),
                  ),
                ],
                if (activeAssets.isEmpty && archivedAssets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: AppEmptyState(
                      title: l10n.commonEmptyAssetsTitle,
                      message: l10n.emptyAssetsInCategoryMessage,
                    ),
                  ),
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
    final l10n = context.l10n;

    // Sengaja tanpa Card/elevasi: dulu section ini sama menonjolnya dengan
    // daftar aset aktif, padahal isinya cuma arsip yang jarang dilihat.
    // Full-bleed (halaman sudah tanpa padding horizontal) supaya konsisten
    // dengan daftar aktif.
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTileTheme(
        data: ExpansionTileThemeData(
          iconColor: mutedColor,
          collapsedIconColor: mutedColor,
        ),
        child: ExpansionTile(
          title: Text(
            l10n.inactiveAssetsLabel,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: mutedColor),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          childrenPadding: EdgeInsets.zero,
          children: [
            AppListCard(
              children: [
                const AssetTableHeader(),
                ...assets.map(
                  (asset) => AssetListItem(
                    asset: asset,
                    onTap: () => onTapAsset(asset),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
