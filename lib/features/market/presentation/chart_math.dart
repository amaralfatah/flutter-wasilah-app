import 'dart:math' as math;

import 'package:flutter_wasilah_app/features/market/data/models/chart_range.dart';
import 'package:flutter_wasilah_app/features/market/data/models/market_quote.dart';
import 'package:flutter_wasilah_app/features/market/data/models/price_series.dart';

/// Tick sumbu Y "nice number" (kelipatan 1/2/5 x 10^n) yang mencakup
/// [min]..[max], kira-kira sejumlah [target].
List<double> niceTicks(double min, double max, {int target = 6}) {
  if (min == max) {
    return [min];
  }

  final range = _niceNumber(max - min, round: false);
  final step = _niceNumber(range / (target - 1), round: true);
  final niceMin = (min / step).floorToDouble() * step;
  final niceMax = (max / step).ceilToDouble() * step;

  final ticks = <double>[];
  for (var tick = niceMin; tick <= niceMax + step / 2; tick += step) {
    ticks.add(tick);
  }
  return ticks;
}

double _niceNumber(double range, {required bool round}) {
  if (range == 0) {
    return 1;
  }

  final exponent = (math.log(range) / math.ln10).floor();
  final magnitude = math.pow(10, exponent).toDouble();
  final fraction = range / magnitude;

  double niceFraction;
  if (round) {
    if (fraction < 1.5) {
      niceFraction = 1;
    } else if (fraction < 3) {
      niceFraction = 2;
    } else if (fraction < 7) {
      niceFraction = 5;
    } else {
      niceFraction = 10;
    }
  } else {
    if (fraction <= 1) {
      niceFraction = 1;
    } else if (fraction <= 2) {
      niceFraction = 2;
    } else if (fraction <= 5) {
      niceFraction = 5;
    } else {
      niceFraction = 10;
    }
  }

  return niceFraction * magnitude;
}

/// Indeks titik terdekat dengan offset horizontal [dx] pada kanvas selebar
/// [width], untuk interaksi scrub chart.
int nearestPointIndex(List<PricePoint> points, double dx, double width) {
  if (points.length <= 1) {
    return 0;
  }
  final ratio = (dx / width).clamp(0.0, 1.0);
  final index = (ratio * (points.length - 1)).round();
  return index.clamp(0, points.length - 1);
}

/// Harga acuan untuk menghitung perubahan pada [range]: penutupan kemarin
/// untuk [ChartRange.oneDay], atau titik pertama seri untuk range lain.
/// `null` bila belum ada data yang relevan.
double? referencePrice(
  ChartRange range,
  MarketQuote quote,
  PriceSeries? series,
) {
  if (range == ChartRange.oneDay) {
    return quote.previousClose;
  }
  if (series == null || series.points.isEmpty) {
    return null;
  }
  return series.points.first.close;
}
