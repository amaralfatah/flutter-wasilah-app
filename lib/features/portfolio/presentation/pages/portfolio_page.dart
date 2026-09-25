import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/asset_list_item.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_list_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_section_band.dart';
import 'package:flutter_wasilah_app/shared/widgets/async_value_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/refreshable_page_body.dart';
import 'package:go_router/go_router.dart';

// Horizontal 0: daftar holding (AppListCard/_ArchivedAssetsSection) full-bleed
// sampai tepi layar. Widget lain yang butuh jarak (mis. AppEmptyState)
// mengatur padding horizontalnya sendiri.
const _portfolioPagePadding = EdgeInsets.fromLTRB(
  0,
  AppSpacing.xl,
  0,
  AppSpacing.xxxl + (kFloatingActionButtonMargin * 3),
);

/// Daftar holding portofolio: aset yang sudah punya nilai. Master aset
/// (identitas) dikelola terpisah di Pengaturan, lihat `MasterAssetListPage`.
class PortfolioPage extends ConsumerStatefulWidget {
  const PortfolioPage({super.key});

  @override
  ConsumerState<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends ConsumerState<PortfolioPage> {
  AssetCategory? _selectedCategory;

  Future<void> _refresh() => ref.refresh(positionListProvider.future);

  @override
  Widget build(BuildContext context) {
    final assetsValue = ref.watch(positionListProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.portfolioTitle)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'portfolio_update_value_fab',
        onPressed: () => context.push(RouteNames.portfolioUpdate),
        tooltip: l10n.addToPortfolioLabel,
        child: const Icon(Icons.edit_note),
      ),
      body: AsyncValueView(
        value: assetsValue,
        onRetry: () => ref.invalidate(positionListProvider),
        data: (assets) {
          if (assets.isEmpty) {
            return RefreshablePageBody(
              onRefresh: _refresh,
              padding: _portfolioPagePadding,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: _EmptyPortfolio(),
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

          // Holding bernilai 0 (sudah dijual/habis) dipisah supaya tidak
          // menyesaki list aktif, tapi datanya tetap tersimpan.
          final activeAssets = filteredAssets
              .where((asset) => asset.currentValue != 0)
              .toList(growable: false);
          final archivedAssets = filteredAssets
              .where((asset) => asset.currentValue == 0)
              .toList(growable: false);

          return RefreshablePageBody(
            onRefresh: _refresh,
            padding: _portfolioPagePadding,
            // Aset sudah datang terurut dari nilai terbesar (lihat
            // getPositions di repository), jadi satu list tanpa pengelompokan
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
                          onTap: () => context.push(
                            '${RouteNames.portfolio}/${asset.id}',
                          ),
                        ),
                      ),
                    ],
                  ),
                if (archivedAssets.isNotEmpty) ...[
                  if (activeAssets.isNotEmpty) const AppSectionBand(),
                  _ArchivedAssetsSection(
                    assets: archivedAssets,
                    onTapAsset: (asset) =>
                        context.push('${RouteNames.portfolio}/${asset.id}'),
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

  final List<PortfolioPosition> assets;
  final ValueChanged<PortfolioPosition> onTapAsset;

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

/// Portofolio kosong: arahkan ke catat nilai, atau ke master aset bila
/// belum ada aset sama sekali.
class _EmptyPortfolio extends ConsumerWidget {
  const _EmptyPortfolio();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final hasMasterAssets =
        ref.watch(assetListProvider).asData?.value.isNotEmpty ?? false;

    return AppEmptyState(
      title: l10n.emptyPortfolioTitle,
      message: hasMasterAssets
          ? l10n.emptyPortfolioMessage
          : l10n.emptyPortfolioNoMasterMessage,
      actionLabel: hasMasterAssets
          ? l10n.addToPortfolioLabel
          : l10n.openMasterAssetsLabel,
      onAction: () => context.push(
        hasMasterAssets ? RouteNames.portfolioUpdate : RouteNames.masterAssets,
      ),
    );
  }
}
