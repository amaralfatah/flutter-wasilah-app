import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/value_snapshot.dart';

/// Satu baris histori: bulan di kiri, nilai dan perubahannya dari bulan
/// sebelumnya di kanan (nilai di atas, persentase di bawahnya) — nilai dan
/// perubahannya jadi satu kesatuan yang dibaca sekali lihat.
class HistoryRow extends StatelessWidget {
  const HistoryRow({
    required this.snapshot,
    super.key,
    this.changeLabel,
    this.changeColor,
    this.showYear = true,
  });

  final ValueSnapshot snapshot;

  /// `false` bila tahun sudah tampil di pita grup di atas baris.
  final bool showYear;

  /// Perubahan dari bulan sebelumnya, misalnya "Naik 5,1%"; `null` untuk
  /// halaman yang tidak menghitungnya (histori per aset).
  final String? changeLabel;
  final Color? changeColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatMonthName(
                    snapshot.recordedAt,
                    Localizations.localeOf(context),
                  ),
                  style: textTheme.titleSmall,
                ),
                if (showYear)
                  Text(
                    '${snapshot.recordedAt.year}',
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatCurrency(snapshot.totalValue),
                style: textTheme.bodyMedium,
                textAlign: TextAlign.end,
              ),
              if (changeLabel != null)
                Text(
                  changeLabel!,
                  style: textTheme.bodySmall?.copyWith(color: changeColor),
                  textAlign: TextAlign.end,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
