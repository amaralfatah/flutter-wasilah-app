import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/profit_loss_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/time_weighted_return.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/value_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/history_line_chart.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/history_row.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_error_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_list_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_loading.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_section_band.dart';
import 'package:flutter_wasilah_app/shared/widgets/confirm_dialog.dart';
import 'package:flutter_wasilah_app/shared/widgets/delete_swipe_background.dart';
import 'package:flutter_wasilah_app/shared/widgets/refreshable_page_body.dart';

class PortfolioHistoryPage extends ConsumerStatefulWidget {
  const PortfolioHistoryPage({super.key});

  @override
  ConsumerState<PortfolioHistoryPage> createState() =>
      _PortfolioHistoryPageState();
}

class _PortfolioHistoryPageState extends ConsumerState<PortfolioHistoryPage> {
  int? _selectedYear;
  final Set<String> _removedIds = {};

  @override
  Widget build(BuildContext context) {
    final historyValue = ref.watch(portfolioHistoryProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: historyValue.when(
        data: (history) {
          if (history.isEmpty) {
            return RefreshablePageBody(
              onRefresh: () => ref.refresh(portfolioHistoryProvider.future),
              child: AppEmptyState(
                title: l10n.commonEmptyHistoryTitle,
                message: l10n.emptyHistoryMessage,
                icon: Icons.history_toggle_off_outlined,
              ),
            );
          }

          final years =
              history.map((item) => item.recordedAt.year).toSet().toList()
                ..sort((a, b) => b.compareTo(a));
          final visibleHistory = history
              .where((item) => !_removedIds.contains(item.id))
              .toList();
          final filteredHistory = _selectedYear == null
              ? visibleHistory
              : visibleHistory
                    .where((item) => item.recordedAt.year == _selectedYear)
                    .toList();
          final changeMap = _buildChangeMap(history);
          final twr = timeWeightedReturn(visibleHistory, year: _selectedYear);
          final firstSnapshotId = history.last.id;

          return RefreshablePageBody(
            onRefresh: () => ref.refresh(portfolioHistoryProvider.future),
            // Horizontal 0: daftar riwayat full-bleed sampai tepi layar.
            // Filter/chart mengatur padding horizontalnya sendiri.
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter diletakkan di atas grafik: kalau di bawah, hasil
                // penekanan chip berubah di luar pandangan user. Full-bleed
                // (bukan Wrap) supaya tahun yang banyak bisa digeser
                // horizontal tanpa memenuhi tinggi layar.
                if (years.length > 1) ...[
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      children: [
                        ChoiceChip(
                          label: Text(l10n.allFilterLabel),
                          selected: _selectedYear == null,
                          onSelected: (_) =>
                              setState(() => _selectedYear = null),
                        ),
                        for (final year in years) ...[
                          const SizedBox(width: AppSpacing.sm),
                          ChoiceChip(
                            label: Text('$year'),
                            selected: _selectedYear == year,
                            onSelected: (_) =>
                                setState(() => _selectedYear = year),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (twr != null) ...[
                        _TwrCard(
                          label: _selectedYear == null
                              ? l10n.historyTwrSinceStartLabel
                              : l10n.historyTwrYearLabel('$_selectedYear'),
                          cumulative: twr.cumulative,
                          annualized: _selectedYear == null
                              ? twr.annualized
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      if (filteredHistory.isNotEmpty) ...[
                        HistoryLineChart(
                          history: filteredHistory.reversed.toList(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      if (filteredHistory.isEmpty)
                        AppEmptyState(
                          title: l10n.noFilteredDataTitle,
                          message: l10n.noFilteredDataMessage,
                        ),
                    ],
                  ),
                ),
                if (filteredHistory.isNotEmpty) ...[
                  const AppSectionBand(),
                  AppListCard(
                    children: filteredHistory
                        .map(
                          (item) => Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: const DeleteSwipeBackground(),
                            confirmDismiss: (_) => _confirmDelete(context),
                            onDismissed: (_) {
                              setState(() => _removedIds.add(item.id));
                              _deleteSnapshot(item.id);
                            },
                            child: HistoryRow(
                              snapshot: item,
                              changeLabel: _formatChange(
                                changeMap[item.id],
                                isFirstSnapshot: item.id == firstSnapshotId,
                                initialDataLabel: l10n.initialDataLabel,
                              ),
                              changeColor: _changeColor(
                                context,
                                changeMap[item.id],
                                isFirstSnapshot: item.id == firstSnapshotId,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
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

  Future<bool> _confirmDelete(BuildContext context) {
    final l10n = context.l10n;
    return showConfirmDialog(
      context,
      title: l10n.commonDeleteHistoryTitle,
      message: l10n.commonDeleteHistoryMessage,
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
    );
  }

  Future<void> _deleteSnapshot(String snapshotId) async {
    final l10n = context.l10n;
    try {
      await ref
          .read(portfolioRepositoryProvider)
          .deletePortfolioSnapshot(snapshotId);
      ref.invalidate(portfolioHistoryProvider);
      ref.invalidate(portfolioSummaryProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonHistoryDeletedMessage)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _removedIds.remove(snapshotId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonDeleteHistoryFailedMessage)),
      );
    }
  }

  Map<String, double> _buildChangeMap(List<ValueSnapshot> history) {
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

  String _formatChange(
    double? value, {
    required bool isFirstSnapshot,
    required String initialDataLabel,
  }) {
    if (isFirstSnapshot || value == null) {
      return initialDataLabel;
    }

    return formatSignedPercentage(value);
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
      return AppColors.positiveOf(context);
    }
    if (value < 0) {
      return AppColors.negativeOf(context);
    }

    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}

/// Kemampuan investasi dalam satu angka: time-weighted return, supaya
/// setoran bulanan tidak ikut terbaca sebagai hasil.
class _TwrCard extends StatelessWidget {
  const _TwrCard({
    required this.label,
    required this.cumulative,
    this.annualized,
  });

  final String label;
  final double cumulative;
  final double? annualized;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final annualized = this.annualized;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _TwrMetric(label: label, value: cumulative),
              ),
              if (annualized != null) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _TwrMetric(
                    label: l10n.historyTwrAnnualizedLabel,
                    value: annualized,
                    crossAxisAlignment: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.historyTwrCaption,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TwrMetric extends StatelessWidget {
  const _TwrMetric({
    required this.label,
    required this.value,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final String label;
  final double value;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          formatSignedPercentage(value),
          style: textTheme.titleSmall?.copyWith(
            color: profitLossColorOf(context, value) ?? colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
