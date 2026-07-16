import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/app/theme/app_colors.dart';
import 'package:flutter_wasilah_app/app/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/core/widgets/app_card.dart';
import 'package:flutter_wasilah_app/core/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/core/widgets/app_error_view.dart';
import 'package:flutter_wasilah_app/core/widgets/app_loading.dart';
import 'package:flutter_wasilah_app/core/widgets/refreshable_page_body.dart';
import 'package:flutter_wasilah_app/core/widgets/section_header.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/target/providers/target_providers.dart';

class PortfolioHistoryPage extends ConsumerStatefulWidget {
  const PortfolioHistoryPage({super.key});

  @override
  ConsumerState<PortfolioHistoryPage> createState() =>
      _PortfolioHistoryPageState();
}

class _PortfolioHistoryPageState extends ConsumerState<PortfolioHistoryPage> {
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    final historyValue = ref.watch(portfolioHistoryProvider);
    final targetItems = ref.watch(targetAllocationItemsProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Histori')),
      body: historyValue.when(
        data: (history) {
          if (history.isEmpty) {
            return RefreshablePageBody(
              onRefresh: () => ref.refresh(portfolioHistoryProvider.future),
              child: const AppEmptyState(
                title: 'Belum ada histori',
                message: 'Histori muncul setelah nilai aset dicatat.',
                icon: Icons.history_toggle_off_outlined,
              ),
            );
          }

          final years =
              history.map((item) => item.recordedAt.year).toSet().toList()
                ..sort((a, b) => b.compareTo(a));
          final filteredHistory = _selectedYear == null
              ? history
              : history
                    .where((item) => item.recordedAt.year == _selectedYear)
                    .toList();
          final changeMap = _buildChangeMap(history);
          final firstSnapshotId = history.last.id;

          return RefreshablePageBody(
            onRefresh: () => ref.refresh(portfolioHistoryProvider.future),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lihat perubahan total portofolio dari waktu ke waktu dan fokuskan ke tahun tertentu bila diperlukan.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter tahun',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          ChoiceChip(
                            label: const Text('Semua'),
                            selected: _selectedYear == null,
                            onSelected: (_) =>
                                setState(() => _selectedYear = null),
                          ),
                          ...years.map(
                            (year) => ChoiceChip(
                              label: Text('$year'),
                              selected: _selectedYear == year,
                              onSelected: (_) =>
                                  setState(() => _selectedYear = year),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (targetItems != null) ...[
                  _HistoryInsightCard(items: targetItems),
                  const SizedBox(height: AppSpacing.xl),
                ],
                const SectionHeader(title: 'Pergerakan nilai'),
                const SizedBox(height: AppSpacing.md),
                if (filteredHistory.isEmpty)
                  const AppEmptyState(
                    title: 'Tidak ada data pada filter ini',
                    message: 'Pilih tahun lain.',
                  )
                else
                  ...filteredHistory.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            formatMonthYear(item.recordedAt),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              _formatChange(
                                changeMap[item.id],
                                isFirstSnapshot: item.id == firstSnapshotId,
                              ),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: _changeColor(
                                      context,
                                      changeMap[item.id],
                                      isFirstSnapshot:
                                          item.id == firstSnapshotId,
                                    ),
                                  ),
                            ),
                          ),
                          trailing: Text(
                            formatCurrency(item.totalValue),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const AppLoading(),
        error: (error, stackTrace) => AppErrorView(
          onRetry: () => ref.invalidate(portfolioHistoryProvider),
        ),
      ),
    );
  }

  Map<String, double> _buildChangeMap(List<AssetSnapshot> history) {
    final map = <String, double>{};
    for (var index = 0; index < history.length; index++) {
      final current = history[index];
      final next = index + 1 < history.length ? history[index + 1] : null;
      if (next == null || next.totalValue == 0) {
        map[current.id] = 0;
        continue;
      }

      map[current.id] =
          ((current.totalValue - next.totalValue) / next.totalValue) * 100;
    }

    return map;
  }

  String _formatChange(double? value, {required bool isFirstSnapshot}) {
    if (isFirstSnapshot || value == null) {
      return 'Data awal';
    }

    final prefix = value >= 0 ? 'Naik' : 'Turun';
    return '$prefix ${value.abs().toStringAsFixed(1).replaceAll('.', ',')}%';
  }

  Color _changeColor(
    BuildContext context,
    double? value, {
    required bool isFirstSnapshot,
  }) {
    if (isFirstSnapshot || value == null) {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }

    if (value > 0) {
      return AppColors.positive;
    }
    if (value < 0) {
      return AppColors.negative;
    }

    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}

class _HistoryInsightCard extends StatelessWidget {
  const _HistoryInsightCard({required this.items});

  final List<TargetAllocationData> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final insight = _buildInsight();

    return AppCard(
      backgroundColor: colorScheme.secondaryContainer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(insight.icon, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insight saat ini',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  insight.message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _HistoryInsight _buildInsight() {
    if (items.isEmpty) {
      return const _HistoryInsight(
        icon: Icons.insights_outlined,
        message: 'Belum ada data target untuk disorot pada histori portofolio.',
      );
    }

    final sortedItems = [...items]
      ..sort(
        (left, right) => right.differencePercentage.abs().compareTo(
          left.differencePercentage.abs(),
        ),
      );

    final topItem = sortedItems.first;
    final difference = topItem.differencePercentage.abs().toStringAsFixed(0);

    switch (topItem.status) {
      case TargetStatus.onTrack:
        return const _HistoryInsight(
          icon: Icons.check_circle_outline,
          message:
              'Komposisi portofolio saat ini sudah paling dekat dengan target. Lanjutkan pencatatan rutin untuk memantau perubahan berikutnya.',
        );
      case TargetStatus.below:
        return _HistoryInsight(
          icon: Icons.trending_up,
          message:
              '${topItem.category.label} masih $difference% di bawah target. Pertimbangkan penambahan pada kategori ini agar alokasi kembali seimbang.',
        );
      case TargetStatus.above:
        return _HistoryInsight(
          icon: Icons.balance_outlined,
          message:
              '${topItem.category.label} berada $difference% di atas target. Pertimbangkan penambahan pada kategori lain agar komposisi kembali seimbang.',
        );
    }
  }
}

class _HistoryInsight {
  const _HistoryInsight({required this.icon, required this.message});

  final IconData icon;
  final String message;
}
