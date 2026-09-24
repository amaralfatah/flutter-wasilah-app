import 'package:freezed_annotation/freezed_annotation.dart';

part 'market_quote.freezed.dart';

@freezed
abstract class MarketQuote with _$MarketQuote {
  const factory MarketQuote({
    required String symbol,
    required String currency,
    required double price,
    required DateTime marketTime,
    required DateTime fetchedAt,

    /// Penutupan sebelumnya; `null` bila Yahoo tidak mengirimkannya.
    double? previousClose,
  }) = _MarketQuote;
  const MarketQuote._();

  /// `price - previousClose`; `null` bila [previousClose] tidak ada.
  double? get change {
    final previous = previousClose;
    return previous == null ? null : price - previous;
  }

  /// [change] dalam persen [previousClose]; `null` bila tidak ada acuan
  /// atau acuannya nol.
  double? get changePercent {
    final previous = previousClose;
    if (previous == null || previous == 0) {
      return null;
    }
    return (price - previous) / previous * 100;
  }
}
