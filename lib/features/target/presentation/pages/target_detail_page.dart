import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/asset_list_item.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/target/presentation/widgets/target_allocation_item.dart';
import 'package:flutter_wasilah_app/features/target/providers/target_providers.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/async_value_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/refreshable_page_body.dart';
import 'package:flutter_wasilah_app/shared/widgets/section_header.dart';
import 'package:go_router/go_router.dart';

class TargetDetailPage extends ConsumerWidget {
  const TargetDetailPage({required this.targetId, super.key});

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

          final assets = assetsValue.asData?.value ?? const <Asset>[];
          final categoryAssets = assets
              .where((asset) => asset.category == item.category)
              .toList(growable: false);
          return RefreshablePageBody(
            onRefresh: () {
              ref.invalidate(assetListProvider);
              return ref.refresh(targetAllocationItemsProvider.future);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(child: TargetAllocationItem(item: item)),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _TargetValueTile(
                        label: 'Nilai aktual',
                        value: formatCurrency(item.actualValue),
                      ),
                      const Divider(height: 1),
                      _TargetValueTile(
                        label: 'Nilai target',
                        value: formatCurrency(item.targetValue),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(
                  title: 'Aset ${item.category.label}',
                  onInfoTap: () => _showToleranceInfo(context, item),
                ),
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

class _TargetValueTile extends StatelessWidget {
  const _TargetValueTile({required this.label, required this.value});

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

String _formatPercent(double value) {
  final text = value
      .toStringAsFixed(1)
      .replaceAll('.0', '')
      .replaceAll('.', ',');

  return '$text%';
}

Future<void> _showToleranceInfo(
  BuildContext context,
  TargetAllocationData item,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Batas wajar'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_formatPercent(item.lowerBound)} - '
            '${_formatPercent(item.upperBound)} '
            '(toleransi ±${_formatPercent(item.tolerance)})',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Mengikuti aturan 5/25: penyesuaian baru diperlukan saat alokasi '
            'melewati 5 poin persen atau 25% dari target, mana yang lebih '
            'kecil.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}
