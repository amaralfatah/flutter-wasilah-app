import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/history_line_chart.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/history_row.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_error_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_list_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_loading.dart';
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
          final firstSnapshotId = history.last.id;

          return RefreshablePageBody(
            onRefresh: () => ref.refresh(portfolioHistoryProvider.future),
            // Horizontal 0: daftar riwayat full-bleed sampai tepi layar.
            // Filter/chart mengatur padding horizontalnya sendiri.
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
                      // Filter diletakkan di atas grafik: kalau di bawah,
                      // hasil penekanan chip berubah di luar pandangan user.
                      if (years.length > 1) ...[
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            ChoiceChip(
                              label: Text(l10n.allFilterLabel),
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
                        const SizedBox(height: AppSpacing.lg),
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
                if (filteredHistory.isNotEmpty)
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
      await ref.read(portfolioRepositoryProvider).deleteSnapshot(snapshotId);
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
