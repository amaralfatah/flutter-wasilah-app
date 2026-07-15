import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/app/router/route_names.dart';
import 'package:flutter_wasilah_app/app/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/core/widgets/async_value_view.dart';
import 'package:flutter_wasilah_app/core/widgets/refreshable_page_body.dart';
import 'package:flutter_wasilah_app/core/widgets/section_header.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/widgets/asset_list_item.dart';
import 'package:flutter_wasilah_app/features/portfolio/widgets/portfolio_summary_card.dart';
import 'package:flutter_wasilah_app/features/portfolio/widgets/target_progress_card.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryValue = ref.watch(portfolioSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.assetUpdate),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Update nilai'),
        tooltip: 'Update nilai aset',
      ),
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
                Text(
                  'Pantau nilai portofolio, progres target, dan aset utama dalam satu tampilan.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                PortfolioSummaryCard(summary: summary),
                const SizedBox(height: AppSpacing.lg),
                TargetProgressCard(
                  percentage: summary.targetProgressPercentage,
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(
                  title: 'Aset utama',
                  actionLabel: 'Lihat semua',
                  onAction: () => context.go(RouteNames.assets),
                ),
                const SizedBox(height: AppSpacing.md),
                ..._assetPreviewItems(
                  summary.assets
                      .take(4)
                      .map((asset) {
                        return AssetListItem(
                          asset: asset,
                          onTap: () =>
                              context.push('${RouteNames.assets}/${asset.id}'),
                        );
                      })
                      .toList(growable: false),
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
