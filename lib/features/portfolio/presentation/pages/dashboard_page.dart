import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/asset_list_item.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/portfolio_summary_card.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/target_progress_card.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_list_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_section_band.dart';
import 'package:flutter_wasilah_app/shared/widgets/async_value_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/refreshable_page_body.dart';
import 'package:flutter_wasilah_app/shared/widgets/section_header.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryValue = ref.watch(portfolioSummaryProvider);
    final targetsValue = ref.watch(allocationTargetProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: const Text('Wasilah')),
      body: AsyncValueView(
        value: summaryValue,
        onRetry: () => ref.invalidate(portfolioSummaryProvider),
        data: (summary) {
          if (summary.assets.isEmpty) {
            return RefreshablePageBody(
              onRefresh: () => ref.refresh(portfolioSummaryProvider.future),
              child: AppEmptyState(
                title: l10n.commonEmptyAssetsTitle,
                message: l10n.emptyAssetsDashboardMessage,
                actionLabel: l10n.commonAddAssetLabel,
                onAction: () => context.push(RouteNames.assetCreate),
              ),
            );
          }

          // Aset bernilai 0 sudah nonaktif/diarsipkan (lihat tab Aset);
          // beranda hanya menonjolkan kepemilikan yang masih aktif.
          final activeAssets = summary.assets
              .where((asset) => asset.currentValue != 0)
              .toList(growable: false);

          return RefreshablePageBody(
            onRefresh: () => ref.refresh(portfolioSummaryProvider.future),
            // Horizontal 0: daftar "Aset utama" full-bleed sampai tepi layar.
            // Konten lain (kartu ringkasan, target) mengatur padding
            // horizontalnya sendiri lewat Padding di bawah.
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PortfolioSummaryCard(
                        summary: summary,
                        onViewHistory: () => context.push(RouteNames.history),
                      ),
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
                                    l10n.commonEmptyTargetsTitle,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    l10n.noTargetsCardMessage,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
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
                    ],
                  ),
                ),
                if (activeAssets.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const AppSectionBand(),
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: SectionHeader(
                      title: l10n.mainAssetsTitle,
                      actionLabel: l10n.viewAllLabel,
                      onAction: () => context.go(RouteNames.assets),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppListCard(
                    children: [
                      const AssetTableHeader(),
                      ...activeAssets
                          .take(4)
                          .map(
                            (asset) => AssetListItem(
                              asset: asset,
                              onTap: () => context.push(
                                '${RouteNames.assets}/${asset.id}',
                              ),
                            ),
                          ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
