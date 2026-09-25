import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Chart mini tanpa sumbu ala watchlist Stockbit: garis harga intraday plus
/// garis putus-putus di [baseline] (penutupan kemarin) sebagai acuan naik /
/// turun. Warna garis ditentukan pemanggil.
class MarketSparkline extends StatelessWidget {
  const MarketSparkline({
    required this.values,
    required this.color,
    super.key,
    this.baseline,
  });

  final List<double> values;
  final double? baseline;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(
        values: values,
        baseline: baseline,
        color: color,
        baselineColor: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.baseline,
    required this.color,
    required this.baselineColor,
  });

  final List<double> values;
  final double? baseline;
  final Color color;
  final Color baselineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      return;
    }

    final baseline = this.baseline;
    var minValue = values.reduce((a, b) => a < b ? a : b);
    var maxValue = values.reduce((a, b) => a > b ? a : b);
    if (baseline != null) {
      minValue = minValue < baseline ? minValue : baseline;
      maxValue = maxValue > baseline ? maxValue : baseline;
    }
    final span = maxValue - minValue;

    // Harga datar (span 0) digambar di tengah, bukan di tepi bawah.
    double yOf(double value) => span == 0
        ? size.height / 2
        : size.height - (value - minValue) / span * size.height;

    if (baseline != null) {
      _drawDashedLine(canvas, size.width, yOf(baseline));
    }

    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = index / (values.length - 1) * size.width;
      final y = yOf(values[index]);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawDashedLine(Canvas canvas, double width, double y) {
    const dash = 4.0;
    const gap = 3.0;
    final paint = Paint()
      ..color = baselineColor
      ..strokeWidth = 1;
    final points = <Offset>[];
    for (var x = 0.0; x < width; x += dash + gap) {
      points
        ..add(Offset(x, y))
        ..add(Offset((x + dash).clamp(0, width), y));
    }
    canvas.drawPoints(ui.PointMode.lines, points, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.baseline != baseline ||
      oldDelegate.color != color ||
      oldDelegate.baselineColor != baselineColor;
}
