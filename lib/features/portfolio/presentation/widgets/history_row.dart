import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/value_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/utils/history_change_calculator.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';

/// Header tabel histori ala "Total Equity Return" Stockbit:
/// Tanggal · Nilai · Perubahan.
class HistoryTableHeader extends StatelessWidget {
  const HistoryTableHeader({
    super.key,
    this.horizontalPadding = AppSpacing.xl,
  });

  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return ExcludeSemantics(
      child: _HistoryTableRow(
        horizontalPadding: horizontalPadding,
        date: Text(l10n.historyTableDateHeader, style: style),
        value: Text(l10n.assetTableValueHeader, style: style),
        change: Text(l10n.historyTableChangeHeader, style: style),
      ),
    );
  }
}

/// Satu baris histori: bulan, nilai, dan perubahan dari snapshot
/// sebelumnya dalam rupiah sekaligus persen (`+1.221.000 (+8,47%)`).
class HistoryRow extends StatelessWidget {
  const HistoryRow({
    required this.snapshot,
    required this.previous,
    super.key,
    this.detail,
    this.dateLabel,
    this.horizontalPadding = AppSpacing.xl,
  });

  /// Pengganti label bulan, mis. tahun untuk tabel tahunan.
  final String? dateLabel;

  final double horizontalPadding;

  final ValueSnapshot snapshot;

  /// Snapshot satu langkah lebih lama; `null` untuk pencatatan pertama.
  final ValueSnapshot? previous;

  /// Keterangan kecil di bawah tanggal, mis. kurs yang dipakai.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final previous = this.previous;
    final amount = previous == null
        ? null
        : snapshot.totalValue - previous.totalValue;
    final percent = previous == null || previous.totalValue == 0
        ? null
        : amount! / previous.totalValue * 100;
    final changeText = amount == null
        ? l10n.initialDataLabel
        : percent == null
        ? formatSignedNumber(amount)
        : '${formatSignedNumber(amount)} (${formatSignedPercentage(percent)})';
    final detail = this.detail;

    return _HistoryTableRow(
      horizontalPadding: horizontalPadding,
      date: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateLabel ??
                formatShortMonthYear(
                  snapshot.recordedAt,
                  Localizations.localeOf(context),
                ),
            style: textTheme.bodyMedium,
          ),
          if (detail != null)
            Text(
              detail,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      value: Text(
        formatNumber(snapshot.totalValue),
        style: textTheme.bodyMedium,
      ),
      change: Text(
        changeText,
        style: textTheme.bodyMedium?.copyWith(
          color: historyChangeColor(
            context,
            percent ?? amount,
            isFirstSnapshot: previous == null,
          ),
        ),
      ),
    );
  }
}

class _HistoryTableRow extends StatelessWidget {
  const _HistoryTableRow({
    required this.horizontalPadding,
    required this.date,
    required this.value,
    required this.change,
  });

  final double horizontalPadding;
  final Widget date;
  final Widget value;
  final Widget change;

  @override
  Widget build(BuildContext context) {
    Widget fit(Widget child, Alignment alignment) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: child,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: date),
          const SizedBox(width: AppSpacing.sm),
          Expanded(flex: 6, child: fit(value, Alignment.center)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(flex: 8, child: fit(change, Alignment.centerRight)),
        ],
      ),
    );
  }
}
