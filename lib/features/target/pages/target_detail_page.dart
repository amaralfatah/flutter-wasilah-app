import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/app/router/route_names.dart';
import 'package:flutter_wasilah_app/app/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/widgets/app_card.dart';
import 'package:flutter_wasilah_app/core/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/core/widgets/async_value_view.dart';
import 'package:flutter_wasilah_app/core/widgets/refreshable_page_body.dart';
import 'package:flutter_wasilah_app/core/widgets/section_header.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/widgets/asset_list_item.dart';
import 'package:flutter_wasilah_app/features/target/providers/target_providers.dart';
import 'package:flutter_wasilah_app/features/target/widgets/target_allocation_item.dart';
import 'package:go_router/go_router.dart';

class TargetDetailPage extends ConsumerWidget {
  const TargetDetailPage({super.key, required this.targetId});

  final String targetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetItemsValue = ref.watch(targetAllocationItemsProvider);
    final assetsValue = ref.watch(assetListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail target'),
        actions: [
          IconButton(
            tooltip: 'Edit target',
            onPressed: () =>
                context.push('${RouteNames.target}/$targetId/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: AsyncValueView(
        value: targetItemsValue,
        onRetry: () => ref.invalidate(targetAllocationItemsProvider),
        data: (items) {
          final item = items.where((item) => item.id == targetId).firstOrNull;
          if (item == null) {
            return const AppEmptyState(
              title: 'Target tidak ditemukan',
              message: 'Data target yang Anda buka tidak tersedia.',
            );
          }

          final categoryAssets =
              assetsValue.asData?.value
                  .where((asset) => asset.category == item.category)
                  .toList(growable: false) ??
              [];

          return RefreshablePageBody(
            onRefresh: () {
              ref.invalidate(assetListProvider);
              return ref.refresh(targetAllocationItemsProvider.future);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(child: TargetAllocationItem(item: item)),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(title: 'Aset ${item.category.label}'),
                const SizedBox(height: AppSpacing.md),
                if (categoryAssets.isEmpty)
                  const AppEmptyState(
                    title: 'Belum ada aset',
                    message: 'Belum ada aset pada kategori ini.',
                  )
                else
                  AppCard(
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < categoryAssets.length;
                          index++
                        ) ...[
                          AssetListItem(
                            asset: categoryAssets[index],
                            showCategory: false,
                            onTap: () => context.push(
                              '${RouteNames.assets}/${categoryAssets[index].id}',
                            ),
                          ),
                          if (index < categoryAssets.length - 1)
                            const Divider(height: AppSpacing.xl),
                        ],
                      ],
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
