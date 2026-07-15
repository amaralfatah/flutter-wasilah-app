import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/app/router/route_names.dart';
import 'package:flutter_wasilah_app/app/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/core/widgets/app_card.dart';
import 'package:flutter_wasilah_app/core/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/core/widgets/app_error_view.dart';
import 'package:flutter_wasilah_app/core/widgets/app_loading.dart';
import 'package:flutter_wasilah_app/core/widgets/app_primary_button.dart';
import 'package:flutter_wasilah_app/core/widgets/section_header.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/widgets/asset_category_icon.dart';
import 'package:go_router/go_router.dart';

class AssetDetailPage extends ConsumerWidget {
  const AssetDetailPage({super.key, required this.assetId});

  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetValue = ref.watch(assetDetailProvider(assetId));
    final historyValue = ref.watch(assetHistoryProvider(assetId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Aset')),
      body: assetValue.when(
        data: (asset) {
          if (asset == null) {
            return const AppEmptyState(
              title: 'Aset tidak ditemukan',
              message: 'Data aset yang Anda buka tidak tersedia.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AssetCategoryIcon(category: asset.category),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${asset.code} - ${asset.category.label}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetricRow(
                      label: 'Nilai saat ini',
                      value: formatCurrency(asset.currentValue),
                    ),
                    const Divider(height: AppSpacing.xl),
                    _MetricRow(
                      label: 'Alokasi portofolio',
                      value:
                          '${asset.allocationPercentage.toStringAsFixed(0)}%',
                    ),
                    const Divider(height: AppSpacing.xl),
                    _MetricRow(
                      label: 'Terakhir diperbarui',
                      value: formatFullDate(asset.lastUpdatedAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: 'Update Nilai ${asset.name}',
                onPressed: () =>
                    context.push('${RouteNames.assets}/${asset.id}/update'),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Histori Nilai'),
              const SizedBox(height: AppSpacing.md),
              historyValue.when(
                data: (history) {
                  if (history.isEmpty) {
                    return const AppEmptyState(
                      title: 'Belum ada histori',
                      message: 'Histori muncul setelah nilai diperbarui.',
                      icon: Icons.timeline_outlined,
                    );
                  }

                  return Column(
                    children: history.take(4).map((snapshot) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(formatFullDate(snapshot.recordedAt)),
                        trailing: Text(
                          formatCurrency(snapshot.totalValue),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const AppLoading(),
                error: (error, stackTrace) => const AppErrorView(),
              ),
            ],
          );
        },
        loading: () => const AppLoading(),
        error: (error, stackTrace) => AppErrorView(
          onRetry: () => ref.invalidate(assetDetailProvider(assetId)),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
