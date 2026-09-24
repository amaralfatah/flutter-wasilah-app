import 'package:flutter_wasilah_app/features/market/data/models/chart_range.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'price_series.freezed.dart';

@freezed
abstract class PricePoint with _$PricePoint {
  const factory PricePoint({required DateTime time, required double close}) =
      _PricePoint;
}

@freezed
abstract class PriceSeries with _$PriceSeries {
  const factory PriceSeries({
    required String symbol,
    required String currency,
    required ChartRange range,
    required List<PricePoint> points,

    /// Dari `meta.chartPreviousClose`; harga acuan untuk range
    /// [ChartRange.oneDay].
    double? previousClose,
  }) = _PriceSeries;
}
