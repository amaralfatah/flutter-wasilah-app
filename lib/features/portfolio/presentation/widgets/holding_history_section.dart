import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/utils/history_change_calculator.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/utils/history_delete.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/history_line_chart.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/history_row.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_error_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_list_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_loading.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_section_band.dart';
import 'package:flutter_wasilah_app/shared/widgets/delete_swipe_background.dart';

/// Grafik dan daftar histori snapshot satu holding; baris bisa digeser
/// untuk dihapus.
class HoldingHistorySection extends StatelessWidget {
  const HoldingHistorySection({
    required this.history,
    required this.removedIds,
    required this.showCost,
    required this.onDismissed,
    super.key,
  });

  final AsyncValue<List<AssetSnapshot>> history;

  /// Snapshot yang sudah digeser hapus tapi mungkin belum terhapus di
  /// database; disembunyikan supaya Dismissible tidak muncul lagi.
  final Set<String> removedIds;

  /// Tampilkan garis modal di grafik (bukan kas).
  final bool showCost;

  /// Dipanggil dengan id snapshot setelah baris digeser dan dikonfirmasi.
  final ValueChanged<String> onDismissed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return history.when(
      data: (fullHistory) {
        final history = fullHistory
            .where((item) => !removedIds.contains(item.id))
            .toList();

        if (history.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: AppEmptyState(
              title: l10n.commonEmptyHistoryTitle,
              message: l10n.emptyAssetHistoryMessage,
              icon: Icons.timeline_outlined,
            ),
          );
        }

        final changeMap = buildHistoryChangeMap(history);
        final firstSnapshotId = history.last.id;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: HistoryLineChart(
                history: history.reversed.toList(),
                showCost: showCost,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppSectionBand(),
            AppListCard(
              children: history
                  .map(
                    (snapshot) => Dismissible(
                      key: ValueKey(snapshot.id),
                      direction: DismissDirection.endToStart,
                      background: const DeleteSwipeBackground(),
                      confirmDismiss: (_) => confirmDeleteHistory(context),
                      onDismissed: (_) => onDismissed(snapshot.id),
                      child: HistoryRow(
                        snapshot: snapshot,
                        changeLabel: formatHistoryChange(
                          changeMap[snapshot.id],
                          isFirstSnapshot: snapshot.id == firstSnapshotId,
                          initialDataLabel: l10n.initialDataLabel,
                        ),
                        changeColor: historyChangeColor(
                          context,
                          changeMap[snapshot.id],
                          isFirstSnapshot: snapshot.id == firstSnapshotId,
                        ),
                        detail: _fxDetail(context, snapshot),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        );
      },
      loading: () => const AppLoading(),
      error: (error, stackTrace) => const AppErrorView(),
    );
  }

  String? _fxDetail(BuildContext context, AssetSnapshot snapshot) {
    final currency = snapshot.fxCurrency;
    final rate = snapshot.fxRate;
    if (currency == null || rate == null) {
      return null;
    }
    return context.l10n.fxRateHistoryLabel(currency, formatCurrency(rate));
  }
}
