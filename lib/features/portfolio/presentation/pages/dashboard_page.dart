import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/asset_list_item.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/portfolio_summary_card.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/target_progress_card.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_list_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/async_value_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/refreshable_page_body.dart';
import 'package:flutter_wasilah_app/shared/widgets/section_header.dart';
import 'package:go_router/go_router.dart';

// Menyisakan ruang di bawah konten supaya kartu terakhir tidak tertutup FAB.
const _dashboardPagePadding = EdgeInsets.fromLTRB(
  AppSpacing.xl,
  AppSpacing.xl,
  AppSpacing.xl,
  AppSpacing.xxxl + (kFloatingActionButtonMargin * 3),
);

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryValue = ref.watch(portfolioSummaryProvider);
    final targetsValue = ref.watch(allocationTargetProvider);

    // Tanpa aset, "update nilai" tidak punya sasaran — empty state sudah
    // menyediakan CTA-nya sendiri.
    final hasAssets = summaryValue.valueOrNull?.assets.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Wasilah')),
      // Update nilai adalah aksi paling sering dilakukan, tapi sebelumnya
      // hanya bisa dicapai lewat tab Aset -> detail aset.
      floatingActionButton: hasAssets
          ? FloatingActionButton.extended(
              heroTag: 'dashboard_update_value_fab',
              onPressed: () => context.push(RouteNames.assetUpdate),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Update nilai'),
            )
          : null,
      body: AsyncValueView(
        value: summaryValue,
        onRetry: () => ref.invalidate(portfolioSummaryProvider),
        data: (summary) {
          if (summary.assets.isEmpty) {
            return RefreshablePageBody(
              onRefresh: () => ref.refresh(portfolioSummaryProvider.future),
              child: AppEmptyState(
                title: 'Belum ada aset',
                message: 'Catat aset pertama untuk melihat ringkasan.',
                actionLabel: 'Tambah aset',
                onAction: () => context.push(RouteNames.assetCreate),
              ),
            );
          }

          return RefreshablePageBody(
            onRefresh: () => ref.refresh(portfolioSummaryProvider.future),
            padding: _dashboardPagePadding,
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
                              'Buat target alokasi dulu agar progres '
                              'portofolio bisa dihitung dengan benar.',
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
                AppListCard(
                  children: summary.assets
                      .take(4)
                      .map(
                        (asset) => AssetListItem(
                          asset: asset,
                          showUpdatedAt: false,
                          onTap: () =>
                              context.push('${RouteNames.assets}/${asset.id}'),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}
