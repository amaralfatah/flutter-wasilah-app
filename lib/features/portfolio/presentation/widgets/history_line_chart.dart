import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';

class HistoryLineChart extends StatelessWidget {
  const HistoryLineChart({required this.history, super.key});

  /// Snapshots ordered oldest to newest.
  final List<AssetSnapshot> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    // Satu titik tidak bisa digambar sebagai garis. Tampilkan penjelasan,
    // jangan menghilang begitu saja — kalau tidak, grafik akan lenyap tanpa
    // sebab saat user memfilter tahun yang hanya punya satu pencatatan.
    if (history.length < 2) {
      return const _ChartPlaceholder();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final values = history.map((item) => item.totalValue).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);

    final axisStyle = textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formatCurrency(maxValue), style: axisStyle),
          const SizedBox(height: AppSpacing.sm),
          // Kanvasnya kosong bagi pembaca layar: angka sumbu di atas dan
          // bawah tidak menjelaskan bahwa keduanya batas sebuah grafik.
          Semantics(
            label:
                'Grafik nilai portofolio '
                '${formatMonthYear(history.first.recordedAt)} sampai '
                '${formatMonthYear(history.last.recordedAt)}, '
                'terendah ${formatCurrency(minValue)}, '
                'tertinggi ${formatCurrency(maxValue)}',
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: CustomPaint(
                painter: _LineChartPainter(
                  values: values,
                  lineColor: colorScheme.primary,
                  fillColor: colorScheme.primary.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(formatCurrency(minValue), style: axisStyle),
          const SizedBox(height: AppSpacing.xs),
          Divider(height: AppSpacing.lg, color: colorScheme.outlineVariant),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatMonthYear(history.first.recordedAt), style: axisStyle),
              Text(formatMonthYear(history.last.recordedAt), style: axisStyle),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Row(
        children: [
          Icon(
            Icons.show_chart_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Grafik muncul setelah ada minimal dua pencatatan nilai.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final range = (maxValue - minValue).abs();
    final stepX = values.length > 1 ? size.width / (values.length - 1) : 0.0;

    double yOf(double value) {
      if (range == 0) {
        return size.height / 2;
      }
      final normalized = (value - minValue) / range;
      return size.height - (normalized * size.height);
    }

    final points = [
      for (var i = 0; i < values.length; i++) Offset(stepX * i, yOf(values[i])),
    ];

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = fillColor);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dotPaint = Paint()..color = lineColor;
    for (final point in points) {
      canvas.drawCircle(point, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}
