import 'package:flutter/material.dart';

/// Kolom kiri rata kiri, tengah rata tengah, kanan rata kanan — pola kartu
/// akun Stockbit supaya tiga angka sebaris terbaca sebagai tiga kolom.
enum MetricAlignment {
  start(CrossAxisAlignment.start, Alignment.centerLeft, TextAlign.start),
  center(CrossAxisAlignment.center, Alignment.center, TextAlign.center),
  end(CrossAxisAlignment.end, Alignment.centerRight, TextAlign.end);

  const MetricAlignment(this.cross, this.fit, this.text);

  final CrossAxisAlignment cross;
  final Alignment fit;
  final TextAlign text;
}

/// Angka tebal di atas label kecil, satu kolom kartu ringkasan ala
/// Stockbit.
class SummaryMetric extends StatelessWidget {
  const SummaryMetric({
    required this.label,
    required this.value,
    super.key,
    this.valueColor,
    this.alignment = MetricAlignment.start,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final MetricAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: alignment.cross,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment.fit,
          child: Text(
            value,
            maxLines: 1,
            style: textTheme.titleSmall?.copyWith(
              color: valueColor ?? colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 2),
        // Mengecil, bukan terpotong: label seperti "Portfolio Value" harus
        // tetap terbaca utuh di kolom sempit.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment.fit,
          child: Text(
            label,
            maxLines: 1,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
