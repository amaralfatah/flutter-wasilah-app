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

    /// Statistik perdagangan dari `meta` Yahoo. Semuanya `null` bila quote
    /// datang dari cache (kolom ini tidak dipersist) atau Yahoo tidak
    /// mengirimkannya. Bagian statistik di UI hanya tampil bila ada isinya.
    double? dayHigh,
    double? dayLow,
    double? fiftyTwoWeekHigh,
    double? fiftyTwoWeekLow,
    double? volume,
  }) = _MarketQuote;
  const MarketQuote._();

  /// `price - previousClose`; `null` bila [previousClose] tidak ada.
  double? get change {
    final previous = previousClose;
    return previous == null ? null : price - previous;
  }

  /// `true` bila ada minimal satu statistik perdagangan untuk ditampilkan
  /// di section "Data Perdagangan". `false` untuk quote dari cache (offline).
  bool get hasTradingStats =>
      previousClose != null ||
      dayHigh != null ||
      dayLow != null ||
      fiftyTwoWeekHigh != null ||
      fiftyTwoWeekLow != null ||
      volume != null;

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
