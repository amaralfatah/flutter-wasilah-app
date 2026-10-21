import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/profit_loss_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/time_weighted_return.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/value_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/utils/history_delete.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/history_line_chart.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/history_row.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_error_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_list_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_loading.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_section_band.dart';
import 'package:flutter_wasilah_app/shared/widgets/delete_swipe_background.dart';
import 'package:flutter_wasilah_app/shared/widgets/period_tabs.dart';
import 'package:flutter_wasilah_app/shared/widgets/refreshable_page_body.dart';
import 'package:flutter_wasilah_app/shared/widgets/summary_metric.dart';

class PortfolioHistoryPage extends ConsumerStatefulWidget {
  const PortfolioHistoryPage({super.key});

  @override
  ConsumerState<PortfolioHistoryPage> createState() =>
      _PortfolioHistoryPageState();
}

/// Periode chart ala Stockbit (1W 1M 3M YTD 1Y All), disesuaikan dengan
/// histori bulanan: periode di bawah 3 bulan tidak bermakna.
enum _HistoryPeriod {
  threeMonths(3),
  sixMonths(6),
  yearToDate(null),
  oneYear(12),
  threeYears(36),
  all(null);

  const _HistoryPeriod(this.months);

  final int? months;

  /// Batas awal periode; `null` untuk semua histori.
  DateTime? startFrom(DateTime now) => switch (this) {
    _HistoryPeriod.all => null,
    _HistoryPeriod.yearToDate => DateTime(now.year),
    _ => DateTime(now.year, now.month - months!, now.day),
  };
}

class _PortfolioHistoryPageState extends ConsumerState<PortfolioHistoryPage> {
  _HistoryPeriod _period = _HistoryPeriod.all;
  bool _yearly = false;
  ValueSnapshot? _scrubbed;
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

          // Terbaru dulu, seperti dari provider.
          final visibleHistory = history
              .where((item) => !_removedIds.contains(item.id))
              .toList();
          if (visibleHistory.isEmpty) {
            return AppEmptyState(
              title: l10n.commonEmptyHistoryTitle,
              message: l10n.emptyHistoryMessage,
              icon: Icons.history_toggle_off_outlined,
            );
          }
          final from = _period.startFrom(DateTime.now());
          final filteredHistory = from == null
              ? visibleHistory
              : visibleHistory
                    .where((item) => !item.recordedAt.isBefore(from))
                    .toList();
          final twr = timeWeightedReturn(visibleHistory, from: from);
          // Terlama ke terbaru, untuk chart.
          final chronological = filteredHistory.reversed.toList();

          return RefreshablePageBody(
            onRefresh: () => ref.refresh(portfolioHistoryProvider.future),
            // Horizontal 0: chart dan tabel full-bleed sampai tepi layar.
            padding: const EdgeInsets.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EquityHero(
                  current: _scrubbed ?? visibleHistory.first,
                  isScrubbing: _scrubbed != null,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (chronological.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: AppEmptyState(
                      title: l10n.noFilteredDataTitle,
                      message: l10n.noFilteredDataMessage,
                    ),
                  )
                else
                  HistoryLineChart(
                    history: chronological,
                    valueLabel: l10n.historyPortfolioLegend,
                    valueReturn: twr?.cumulative,
                    costReturn: _costReturn(chronological),
                    onScrub: (snapshot) => setState(() => _scrubbed = snapshot),
                  ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: PeriodTabs<_HistoryPeriod>(
                    options: _HistoryPeriod.values,
                    selected: _period,
                    labelOf: (period) => _periodLabel(l10n, period),
                    onSelected: (period) => setState(() {
                      _period = period;
                      _scrubbed = null;
                    }),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const AppSectionBand(),
                const SizedBox(height: AppSpacing.lg),
                // "Total Equity Return ⓘ" Stockbit: judul + info, chip
                // Daily/Monthly (di sini Bulanan/Tahunan), lalu tabel.
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xl),
                  child: Row(
                    children: [
                      Text(
                        l10n.historyReturnSectionTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showReturnInfo(context, twr),
                        tooltip: l10n.sectionHeaderInfoTooltip,
                        icon: const Icon(Icons.info_outline, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text(l10n.historyMonthlyLabel),
                        selected: !_yearly,
                        onSelected: (_) => setState(() => _yearly = false),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ChoiceChip(
                        label: Text(l10n.historyYearlyLabel),
                        selected: _yearly,
                        onSelected: (_) => setState(() => _yearly = true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppListCard(
                  children: [
                    const HistoryTableHeader(),
                    if (_yearly)
                      ..._yearlyRows(visibleHistory)
                    else
                      for (final item in filteredHistory)
                        _dismissibleRow(
                          item,
                          _previousOf(visibleHistory, item),
                        ),
                  ],
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

  String _periodLabel(AppLocalizations l10n, _HistoryPeriod period) =>
      switch (period) {
        _HistoryPeriod.threeMonths => l10n.chartRange3M,
        _HistoryPeriod.sixMonths => l10n.chartRange6M,
        _HistoryPeriod.yearToDate => l10n.chartRangeYTD,
        _HistoryPeriod.oneYear => l10n.chartRange1Y,
        _HistoryPeriod.threeYears => l10n.chartRange3Y,
        _HistoryPeriod.all => l10n.allFilterLabel,
      };

  /// Pertumbuhan modal sepanjang periode, untuk kotak legenda "Modal".
  double? _costReturn(List<ValueSnapshot> chronological) {
    final costs = chronological.map((item) => item.totalCost).nonNulls;
    if (costs.length < 2 || costs.first == 0) {
      return null;
    }
    return (costs.last - costs.first) / costs.first * 100;
  }

  /// Satu baris per tahun: snapshot terakhir tahun itu dibanding snapshot
  /// terakhir tahun sebelumnya.
  List<Widget> _yearlyRows(List<ValueSnapshot> newestFirst) {
    final lastOfYear = <int, ValueSnapshot>{};
    for (final item in newestFirst) {
      lastOfYear.putIfAbsent(item.recordedAt.year, () => item);
    }
    final years = lastOfYear.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (var i = 0; i < years.length; i++)
        HistoryRow(
          snapshot: lastOfYear[years[i]]!,
          previous: i + 1 < years.length ? lastOfYear[years[i + 1]] : null,
          dateLabel: '${years[i]}',
        ),
    ];
  }

  Future<void> _showReturnInfo(
    BuildContext context,
    ({double cumulative, double? annualized})? twr,
  ) {
    final l10n = context.l10n;
    return showDialog<void>(
      context: context,
      builder: (context) {
        final annualized = twr?.annualized;
        return AlertDialog(
          title: Text(l10n.historyReturnSectionTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (twr != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: SummaryMetric(
                        label: l10n.historyTwrSinceStartLabel,
                        value: formatSignedPercentage(twr.cumulative),
                        valueColor: profitLossColorOf(context, twr.cumulative),
                      ),
                    ),
                    if (annualized != null)
                      Expanded(
                        child: SummaryMetric(
                          label: l10n.historyTwrAnnualizedLabel,
                          value: formatSignedPercentage(annualized),
                          valueColor: profitLossColorOf(context, annualized),
                          alignment: MetricAlignment.end,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text(
                l10n.historyTwrCaption,
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

  /// Snapshot satu langkah lebih lama dari [item] di histori lengkap
  /// (bukan yang terfilter), supaya awal periode tetap dibandingkan dengan
  /// bulan sebelumnya.
  ValueSnapshot? _previousOf(
    List<ValueSnapshot> newestFirst,
    ValueSnapshot item,
  ) {
    final index = newestFirst.indexOf(item);
    return index < 0 || index + 1 >= newestFirst.length
        ? null
        : newestFirst[index + 1];
  }

  Widget _dismissibleRow(ValueSnapshot item, ValueSnapshot? previous) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: const DeleteSwipeBackground(),
      confirmDismiss: (_) => confirmDeleteHistory(context),
      onDismissed: (_) {
        setState(() => _removedIds.add(item.id));
        unawaited(_deleteSnapshot(item.id));
      },
      child: HistoryRow(snapshot: item, previous: previous),
    );
  }

  Future<void> _deleteSnapshot(String snapshotId) {
    return deleteHistoryEntry(
      context,
      delete: () => ref
          .read(portfolioRepositoryProvider)
          .deletePortfolioSnapshot(snapshotId),
      onFailed: () => setState(() => _removedIds.remove(snapshotId)),
    );
  }
}

/// Hero "Total Equity" Stockbit: label kecil tebal dan nominal besar. Saat
/// chart di-scrub, menampilkan titik yang disentuh beserta bulannya.
class _EquityHero extends StatelessWidget {
  const _EquityHero({required this.current, required this.isScrubbing});

  final ValueSnapshot current;
  final bool isScrubbing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardPortfolioValueLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatCurrency(current.totalValue),
              style: theme.textTheme.headlineSmall,
            ),
          ),
          if (isScrubbing)
            Text(
              formatMonthYear(
                current.recordedAt,
                Localizations.localeOf(context),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
