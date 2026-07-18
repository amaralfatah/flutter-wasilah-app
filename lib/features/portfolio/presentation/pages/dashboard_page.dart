import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/async_value_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/refreshable_page_body.dart';
import 'package:flutter_wasilah_app/shared/widgets/section_header.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/asset_list_item.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/portfolio_summary_card.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/target_progress_card.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryValue = ref.watch(portfolioSummaryProvider);
    final targetsValue = ref.watch(allocationTargetProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wasilah')),
      body: AsyncValueView(
        value: summaryValue,
        onRetry: () => ref.invalidate(portfolioSummaryProvider),
        data: (summary) {
          if (summary.assets.isEmpty) {
            return RefreshablePageBody(
              onRefresh: () => ref.refresh(portfolioSummaryProvider.future),
              child: const AppEmptyState(
                title: 'Belum ada aset',
                message: 'Catat aset pertama untuk melihat ringkasan.',
              ),
            );
          }

          return RefreshablePageBody(
            onRefresh: () => ref.refresh(portfolioSummaryProvider.future),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PortfolioSummaryCard(summary: summary),
                const SizedBox(height: AppSpacing.lg),
                targetsValue.maybeWhen(
                  data: (targets) {
                    if (targets.isEmpty) {
                      return AppCard(
                        onTap: () => context.go(RouteNames.target),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Belum ada target alokasi',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Buat target alokasi dulu agar progres portofolio bisa dihitung dengan benar.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }

                    return TargetProgressCard(
                      percentage: summary.targetProgressPercentage,
                      onTap: () => context.go(RouteNames.target),
                    );
                  },
                  orElse: () => TargetProgressCard(
                    percentage: summary.targetProgressPercentage,
                    onTap: () => context.go(RouteNames.target),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(
                  title: 'Aset utama',
                  actionLabel: 'Lihat semua',
                  onAction: () => context.go(RouteNames.assets),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    children: _assetPreviewItems(
                      summary.assets
                          .take(4)
                          .map((asset) {
                            return AssetListItem(
                              asset: asset,
                              showUpdatedAt: false,
                              onTap: () => context.push(
                                '${RouteNames.assets}/${asset.id}',
                              ),
                            );
                          })
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

  List<Widget> _assetPreviewItems(List<Widget> items) {
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
