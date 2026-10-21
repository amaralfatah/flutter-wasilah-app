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
import 'package:go_router/go_router.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryValue = ref.watch(portfolioSummaryProvider);
    final targetsValue = ref.watch(allocationTargetProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: const Text('Sararia Portfolio')),
      body: AsyncValueView(
        value: summaryValue,
        onRetry: () => ref.invalidate(portfolioSummaryProvider),
        data: (summary) {
          if (summary.positions.isEmpty) {
            return RefreshablePageBody(
              onRefresh: () {
                ref.invalidate(holdingQuotesProvider);
                return ref.refresh(portfolioSummaryProvider.future);
              },
              child: AppEmptyState(
                title: l10n.emptyPortfolioTitle,
                message: l10n.emptyAssetsDashboardMessage,
                actionLabel: l10n.addToPortfolioLabel,
                // Langsung ke form: tombolnya berjanji "Catat nilai aset",
                // bukan sekadar pindah tab.
                onAction: () => context.push(RouteNames.portfolioUpdate),
              ),
            );
          }

          // Aset bernilai 0 sudah nonaktif/diarsipkan (lihat tab Portofolio);
          // beranda hanya menonjolkan kepemilikan yang masih aktif.
          final activeAssets = summary.positions
              .where((asset) => asset.currentValue != 0)
              .toList(growable: false);

          return RefreshablePageBody(
            onRefresh: () {
              ref.invalidate(holdingQuotesProvider);
              return ref.refresh(portfolioSummaryProvider.future);
            },
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
                        onViewHistory: () => context.go(RouteNames.history),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      targetsValue.maybeWhen(
                        data: (targets) {
                          if (targets.isEmpty) {
                            // Chevron menandai kartu bisa diketuk, sama
                            // dengan kartu lain yang membuka halaman.
                            return AppCard(
                              onTap: () => context.go(RouteNames.target),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
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
                  // Stockbit memisahkan kartu ringkasan dan tabel dengan
                  // pita jeda tanpa judul; daftar lengkap ada di tab
                  // Portofolio.
                  const AppSectionBand(),
                  const SizedBox(height: AppSpacing.sm),
                  AppListCard(
                    children: [
                      const AssetTableHeader(),
                      ...activeAssets
                          .take(4)
                          .map(
                            (asset) => AssetListItem(
                              asset: asset,
                              onTap: () => context.push(
                                '${RouteNames.portfolio}/${asset.id}',
                              ),
                            ),
                          ),
                      // Beranda hanya memuat 4 teratas; tanpa tautan ini
                      // pengguna tak tahu masih ada holding lain.
                      if (activeAssets.length > 4)
                        _ViewAllRow(
                          onTap: () => context.go(RouteNames.portfolio),
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

/// Baris "Lihat semua ›" di ujung daftar, gaya tautan hijau Stockbit.
class _ViewAllRow extends StatelessWidget {
  const _ViewAllRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.l10n.viewAllShortLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
