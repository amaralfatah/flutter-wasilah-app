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
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_list_card.dart';
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
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.targetDetailTitle),
        actions: [
          IconButton(
            tooltip: l10n.editTargetTooltip,
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
            return AppEmptyState(
              title: l10n.targetNotFoundTitle,
              message: l10n.targetNotFoundDetailMessage,
            );
          }

          final assets = assetsValue.asData?.value ?? const <Asset>[];
          // Aset bernilai 0 sudah nonaktif/diarsipkan, sama seperti
          // perlakuan di Dashboard: tidak ikut dihitung sebagai kepemilikan
          // aktif dalam kategori ini.
          final categoryAssets = assets
              .where(
                (asset) =>
                    asset.category == item.category &&
                    asset.currentValue != 0,
              )
              .toList(growable: false);
          return RefreshablePageBody(
            onRefresh: () {
              ref.invalidate(assetListProvider);
              return ref.refresh(targetAllocationItemsProvider.future);
            },
            // Horizontal 0: AppListCard full-bleed sampai tepi layar. Konten
            // lain mengatur padding horizontalnya sendiri.
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: AppCard(child: TargetAllocationItem(item: item)),
                ),
                const SizedBox(height: AppSpacing.md),
                AppListCard(
                  children: [
                    _TargetValueTile(
                      label: l10n.actualValueLabel,
                      value: formatCurrency(item.actualValue),
                    ),
                    _TargetValueTile(
                      label: l10n.targetValueLabel,
                      value: formatCurrency(item.targetValue),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: SectionHeader(
                    title: l10n.assetsInCategoryTitle(item.category.label),
                    onInfoTap: () => _showToleranceInfo(context, item),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (categoryAssets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: AppEmptyState(
                      title: l10n.commonEmptyAssetsTitle,
                      message: l10n.emptyAssetsInCategoryMessage,
                    ),
                  )
                else
                  AppListCard(
                    children: [
                      const AssetTableHeader(),
                      ...categoryAssets.map(
                        (asset) => AssetListItem(
                          asset: asset,
                          onTap: () =>
                              context.push('${RouteNames.assets}/${asset.id}'),
                        ),
                      ),
                    ],
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
        horizontal: AppSpacing.xl,
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
    builder: (context) {
      final l10n = context.l10n;
      return AlertDialog(
        title: Text(l10n.reasonableRangeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.toleranceInfoText(
                _formatPercent(item.lowerBound),
                _formatPercent(item.upperBound),
                _formatPercent(item.tolerance),
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.toleranceRuleExplanation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonClose),
          ),
        ],
      );
    },
  );
}
