import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/app/router/route_names.dart';
import 'package:flutter_wasilah_app/app/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/widgets/app_card.dart';
import 'package:flutter_wasilah_app/core/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/core/widgets/async_value_view.dart';
import 'package:flutter_wasilah_app/core/widgets/refreshable_page_body.dart';
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
              child: const AppEmptyState(
                title: 'Belum ada aset',
                message: 'Tambahkan aset pertama untuk mulai mencatat nilai.',
              ),
            );
          }

          return RefreshablePageBody(
            onRefresh: () => ref.refresh(assetListProvider.future),
            padding: _assetListPagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
