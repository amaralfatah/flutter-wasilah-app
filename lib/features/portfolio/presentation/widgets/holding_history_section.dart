import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/utils/history_delete.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/history_line_chart.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/history_row.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_error_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_list_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_loading.dart';
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
    this.horizontalPadding = AppSpacing.lg,
  });

  /// Jarak kiri-kanan chart dan tabel.
  final double horizontalPadding;

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
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: AppEmptyState(
              title: l10n.commonEmptyHistoryTitle,
              message: l10n.emptyAssetHistoryMessage,
              icon: Icons.timeline_outlined,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HistoryLineChart(
              history: history.reversed.toList(),
              showCost: showCost,
              horizontalPadding: horizontalPadding,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppListCard(
              children: [
                HistoryTableHeader(horizontalPadding: horizontalPadding),
                for (var index = 0; index < history.length; index++)
                  Dismissible(
                    key: ValueKey(history[index].id),
                    direction: DismissDirection.endToStart,
                    background: const DeleteSwipeBackground(),
                    confirmDismiss: (_) => confirmDeleteHistory(context),
                    onDismissed: (_) => onDismissed(history[index].id),
                    child: HistoryRow(
                      snapshot: history[index],
                      previous: index + 1 < history.length
                          ? history[index + 1]
                          : null,
                      detail: _fxDetail(context, history[index]),
                      horizontalPadding: horizontalPadding,
                    ),
                  ),
              ],
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
