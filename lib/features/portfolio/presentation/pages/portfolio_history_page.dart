import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/history_line_chart.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_error_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_loading.dart';
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HistoryLineChart(history: filteredHistory.reversed.toList()),
                if (filteredHistory.length > 1)
                  const SizedBox(height: AppSpacing.xl),
                if (years.length > 1) ...[
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ChoiceChip(
                        label: const Text('Semua'),
                        selected: _selectedYear == null,
                        onSelected: (_) => setState(() => _selectedYear = null),
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
                if (filteredHistory.isEmpty)
                  const AppEmptyState(
                    title: 'Tidak ada data pada filter ini',
                    message: 'Pilih tahun lain.',
                  )
                else
                  ...filteredHistory.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: const _DeleteBackground(),
                        confirmDismiss: (_) => _confirmDelete(context),
                        onDismissed: (_) {
                          setState(() => _removedIds.add(item.id));
                          _deleteSnapshot(item.id);
                        },
                        child: AppCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              formatMonthYear(item.recordedAt),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.xs,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatChange(
                                      changeMap[item.id],
                                      isFirstSnapshot:
                                          item.id == firstSnapshotId,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: _changeColor(
                                            context,
                                            changeMap[item.id],
                                            isFirstSnapshot:
                                                item.id == firstSnapshotId,
                                          ),
                                        ),
                                  ),
                                  if (item.note != null)
                                    Text(
                                      item.note!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                            trailing: Text(
                              formatCurrency(item.totalValue),
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.end,
                            ),
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

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus histori?'),
        content: const Text('Entri histori bulan ini akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<void> _deleteSnapshot(String snapshotId) async {
    try {
      await ref.read(portfolioRepositoryProvider).deleteSnapshot(snapshotId);
      ref.invalidate(portfolioHistoryProvider);
      ref.invalidate(portfolioSummaryProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() => _removedIds.remove(snapshotId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus histori.')),
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
      return AppColors.positiveOf(context);
    }
    if (value < 0) {
      return AppColors.negativeOf(context);
    }

    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerRight,
      child: Icon(
        Icons.delete_outline,
        color: Theme.of(context).colorScheme.onErrorContainer,
      ),
    );
  }
}
