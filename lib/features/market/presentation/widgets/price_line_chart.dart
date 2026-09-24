import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/features/market/data/models/price_series.dart';
import 'package:flutter_wasilah_app/features/market/presentation/chart_math.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';

const double _chartHeight = 200;
const double _axisWidth = 56;

/// Ruang kosong di atas titik tertinggi & di bawah titik terendah skala,
/// supaya label ekstrem dan label sumbu Y di tepi tidak terpotong.
const double _insetY = 16;

/// Chart garis harga penutupan ala Stockbit: area fill, garis acuan
/// putus-putus, label titik ekstrem, sumbu Y kanan, dan scrub interaktif
/// (tekan lama / geser) lewat [onScrub].
class PriceLineChart extends StatefulWidget {
  const PriceLineChart({
    required this.points,
    required this.referencePrice,
    required this.currency,
    super.key,
    this.onScrub,
  });

  /// Titik chart, terurut lama ke baru.
  final List<PricePoint> points;

  /// Garis acuan putus-putus (penutupan kemarin, atau titik pertama range).
  final double? referencePrice;
  final String currency;

  /// Dipanggil dengan titik yang sedang di-scrub, atau `null` saat jari
  /// dilepas.
  final ValueChanged<PricePoint?>? onScrub;

  @override
  State<PriceLineChart> createState() => _PriceLineChartState();
}

class _PriceLineChartState extends State<PriceLineChart> {
  int? _scrubIndex;

  @override
  Widget build(BuildContext context) {
    final points = widget.points;

    if (points.length < 2) {
      return SizedBox(
        height: _chartHeight,
        child: Center(
          child: Text(
            context.l10n.marketChartEmpty,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final closes = points.map((point) => point.close).toList();
    final reference = widget.referencePrice;
    // maxIndex/minIndex harus mengacu ke titik ekstrem di antara `closes`
    // saja, bukan skala gabungan (yang bisa memasukkan referencePrice) --
    // kalau tidak, indexOf bisa gagal menemukannya dan mengembalikan -1.
    final closesMin = closes.reduce((a, b) => a < b ? a : b);
    final closesMax = closes.reduce((a, b) => a > b ? a : b);
    final maxIndex = closes.indexOf(closesMax);
    final minIndex = closes.indexOf(closesMin);

    final scaleValues = [...closes, ?reference];
    final rawMin = scaleValues.reduce((a, b) => a < b ? a : b);
    final rawMax = scaleValues.reduce((a, b) => a > b ? a : b);
    // Stockbit memakai ±8 tick (mis. 4.060-4.200 step 20).
    final ticks = niceTicks(rawMin, rawMax, target: 8);
    final scaleMin = ticks.first;
    final scaleMax = ticks.last;

    final first = points.first.close;
    final last = points.last.close;
    final isPositive = last >= (reference ?? first);
    final lineColor = isPositive
        ? AppColors.positiveOf(context)
        : AppColors.negativeOf(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: _chartHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                void updateScrub(double dx) =>
                    _updateScrub(dx, constraints.maxWidth);

                return GestureDetector(
                  onLongPressStart: (details) =>
                      updateScrub(details.localPosition.dx),
                  onLongPressMoveUpdate: (details) =>
                      updateScrub(details.localPosition.dx),
                  onLongPressEnd: (_) => _clearScrub(),
                  onLongPressCancel: _clearScrub,
                  onHorizontalDragStart: (details) =>
                      updateScrub(details.localPosition.dx),
                  onHorizontalDragUpdate: (details) =>
                      updateScrub(details.localPosition.dx),
                  onHorizontalDragEnd: (_) => _clearScrub(),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, _chartHeight),
                    painter: _ChartPainter(
                      points: points,
                      minValue: scaleMin,
                      maxValue: scaleMax,
                      referenceValue: reference,
                      lineColor: lineColor,
                      referenceColor: colorScheme.outlineVariant,
                      maxIndex: maxIndex,
                      minIndex: minIndex,
                      currency: widget.currency,
                      scrubIndex: _scrubIndex,
                      onSurfaceColor: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: _axisWidth,
            child: Stack(
              children: [
                for (final tick in ticks)
                  Positioned(
                    top:
                        _insetY +
                        _yFraction(tick, scaleMin, scaleMax) *
                            (_chartHeight - 2 * _insetY) -
                        8,
                    right: 0,
                    child: Text(
                      formatPrice(tick, widget.currency),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _yFraction(double value, double min, double max) {
    if (max == min) {
      return 0.5;
    }
    return 1 - (value - min) / (max - min);
  }

  void _updateScrub(double dx, double width) {
    final index = nearestPointIndex(widget.points, dx, width);
    if (index != _scrubIndex) {
      _scrubIndex = index;
      widget.onScrub?.call(widget.points[index]);
      setState(() {});
    }
  }

  void _clearScrub() {
    if (_scrubIndex == null) {
      return;
    }
    setState(() => _scrubIndex = null);
    widget.onScrub?.call(null);
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.points,
    required this.minValue,
    required this.maxValue,
    required this.referenceValue,
    required this.lineColor,
    required this.referenceColor,
    required this.maxIndex,
    required this.minIndex,
    required this.currency,
    required this.scrubIndex,
    required this.onSurfaceColor,
  });

  final List<PricePoint> points;
  final double minValue;
  final double maxValue;
  final double? referenceValue;
  final Color lineColor;
  final Color referenceColor;
  final int maxIndex;
  final int minIndex;
  final String currency;
  final int? scrubIndex;
  final Color onSurfaceColor;

  @override
  void paint(Canvas canvas, Size size) {
    final range = (maxValue - minValue).abs();
    final stepX = points.length > 1 ? size.width / (points.length - 1) : 0.0;

    final plotHeight = size.height - 2 * _insetY;

    double yOf(double value) {
      if (range == 0) {
        return size.height / 2;
      }
      return _insetY + plotHeight - ((value - minValue) / range) * plotHeight;
    }

    final offsets = [
      for (var i = 0; i < points.length; i++)
        Offset(stepX * i, yOf(points[i].close)),
    ];

    // Garis acuan putus-putus.
    if (referenceValue case final reference?) {
      final y = yOf(reference);
      const dashWidth = 4.0;
      const dashSpace = 4.0;
      var x = 0.0;
      final dashPaint = Paint()
        ..color = referenceColor
        ..strokeWidth = 1;
      while (x < size.width) {
        canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), dashPaint);
        x += dashWidth + dashSpace;
      }
    }

    final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final offset in offsets.skip(1)) {
      linePath.lineTo(offset.dx, offset.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(offsets.last.dx, size.height)
      ..lineTo(offsets.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.25),
            lineColor.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    _drawExtremeLabel(
      canvas,
      size,
      offsets[maxIndex],
      points[maxIndex].close,
      isMax: true,
    );
    _drawExtremeLabel(
      canvas,
      size,
      offsets[minIndex],
      points[minIndex].close,
      isMax: false,
    );

    if (scrubIndex case final index?) {
      final offset = offsets[index];
      canvas.drawLine(
        Offset(offset.dx, 0),
        Offset(offset.dx, size.height),
        Paint()
          ..color = onSurfaceColor.withValues(alpha: 0.4)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(offset, 4, Paint()..color = lineColor);
      canvas.drawCircle(
        offset,
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawExtremeLabel(
    Canvas canvas,
    Size size,
    Offset point,
    double value, {
    required bool isMax,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: formatPrice(value, currency),
        style: TextStyle(color: lineColor, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final maxDx = (size.width - painter.width).clamp(0.0, size.width);
    final dx = (point.dx - painter.width / 2).clamp(0.0, maxDx);
    final maxDy = (size.height - painter.height).clamp(0.0, size.height);
    final dy = (isMax ? point.dy - painter.height - 4 : point.dy + 4).clamp(
      0.0,
      maxDy,
    );
    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.referenceValue != referenceValue ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.scrubIndex != scrubIndex;
  }
}
