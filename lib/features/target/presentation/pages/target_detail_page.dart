import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/utils/asset_category_l10n.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/asset_category_icon.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/asset_list_item.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/target/presentation/widgets/target_allocation_item.dart';
import 'package:flutter_wasilah_app/features/target/providers/target_providers.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_list_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_section_band.dart';
import 'package:flutter_wasilah_app/shared/widgets/async_value_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/refreshable_page_body.dart';
import 'package:flutter_wasilah_app/shared/widgets/summary_metric.dart';
import 'package:go_router/go_router.dart';

class TargetDetailPage extends ConsumerWidget {
  const TargetDetailPage({required this.targetId, super.key});

  final String targetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetItemsValue = ref.watch(targetAllocationItemsProvider);
    final assetsValue = ref.watch(positionListProvider);
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
      body: SafeArea(
        child: AsyncValueView(
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

            final assets =
                assetsValue.asData?.value ?? const <PortfolioPosition>[];
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
                ref.invalidate(positionListProvider);
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
                    child: _TargetHero(item: item),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: _TargetSummaryCard(item: item),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppListCard(
                    children: [
                      _TargetValueTile(
                        label: l10n.targetStatusLabel,
                        value: item.status.localizedLabel(l10n),
                        valueColor: item.statusColor(context),
                      ),
                      if (item.differenceValue.round() != 0)
                        _TargetValueTile(
                          label: item.differenceValue < 0
                              ? l10n.targetSummaryToAdd
                              : l10n.targetSummaryToTrim,
                          value: formatCurrency(item.differenceValue.abs()),
                        ),
                      _TargetValueTile(
                        label: l10n.reasonableRangeTitle,
                        value:
                            '${formatCompactCurrency(item.lowerBoundValue)}'
                            ' – ${formatCompactCurrency(item.upperBoundValue)}',
                        subtitle:
                            '${_formatPercent(item.lowerBound)}'
                            ' – ${_formatPercent(item.upperBound)}',
                        onInfoTap: () => _showToleranceInfo(context, item),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppSectionBand(
                    label: l10n.assetsInCategoryTitle(
                      item.category.localizedLabel(l10n),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                            onTap: () => context.push(
                              '${RouteNames.portfolio}/${asset.id}',
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Kepala halaman ala detail saham Stockbit: nama tebal, keterangan abu,
/// nominal besar, dan baris perubahan berwarna dengan panah; ikon di kanan.
class _TargetHero extends StatelessWidget {
  const _TargetHero({required this.item});

  final TargetAllocationData item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final color = item.status == TargetStatus.onTrack
        ? theme.colorScheme.onSurfaceVariant
        : item.statusColor(context);
    final difference = item.differenceValue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.category.localizedLabel(l10n),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                l10n.targetAllocationTargetValue(
                  formatPercentage(item.targetPercentage),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatCurrency(item.actualValue),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  if (difference.round() != 0)
                    Icon(
                      difference > 0 ? Icons.north_east : Icons.south_east,
                      size: 14,
                      color: color,
                    ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text:
                                '${formatSignedNumber(difference)} '
                                '(${formatSignedPercentage(
                                  item.differencePercentage,
                                )})',
                            style: TextStyle(color: color),
                          ),
                          TextSpan(
                            text: '  ${l10n.targetHeroFromTarget}',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        AssetCategoryIcon(
          category: item.category,
          radius: 26,
        ),
      ],
    );
  }
}

/// Ringkasan ala kartu akun Stockbit: nilai target, alokasi aktual, dan
/// selisih alokasi.
class _TargetSummaryCard extends StatelessWidget {
  const _TargetSummaryCard({required this.item});

  final TargetAllocationData item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final differenceColor = item.status == TargetStatus.onTrack
        ? null
        : item.statusColor(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Row(
        children: [
          Expanded(
            child: SummaryMetric(
              label: l10n.targetValueLabel,
              value: formatNumber(item.targetValue),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SummaryMetric(
              label: l10n.targetActualAllocationLabel,
              alignment: MetricAlignment.center,
              value: formatPercentage(item.actualPercentage),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SummaryMetric(
              label: l10n.targetDifferencePercentLabel,
              alignment: MetricAlignment.end,
              value: formatSignedPercentage(item.differencePercentage),
              valueColor: differenceColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetValueTile extends StatelessWidget {
  const _TargetValueTile({
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
    this.onInfoTap,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;
  final VoidCallback? onInfoTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final onInfoTap = this.onInfoTap;
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xs,
      ),
      title: onInfoTap == null
          ? Text(label, style: labelStyle)
          : Row(
              children: [
                Flexible(child: Text(label, style: labelStyle)),
                IconButton(
                  onPressed: onInfoTap,
                  tooltip: context.l10n.sectionHeaderInfoTooltip,
                  icon: const Icon(Icons.info_outline, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: valueColor,
          fontWeight: FontWeight.w600,
        ),
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
