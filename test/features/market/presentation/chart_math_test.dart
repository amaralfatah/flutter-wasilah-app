import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/market/data/models/chart_range.dart';
import 'package:flutter_wasilah_app/features/market/data/models/market_quote.dart';
import 'package:flutter_wasilah_app/features/market/data/models/price_series.dart';
import 'package:flutter_wasilah_app/features/market/presentation/chart_math.dart';

void main() {
  group('niceTicks', () {
    test('covers the given range with round steps', () {
      final ticks = niceTicks(4060, 4190);

      expect(ticks.first, lessThanOrEqualTo(4060));
      expect(ticks.last, greaterThanOrEqualTo(4190));
      // Steps between ticks should all be equal (a "nice" round number).
      final steps = <double>[
        for (var i = 1; i < ticks.length; i++) ticks[i] - ticks[i - 1],
      ];
      expect(steps.toSet(), hasLength(1));
    });

    test('returns a single tick when min equals max', () {
      expect(niceTicks(100, 100), [100]);
    });
  });

  group('nearestPointIndex', () {
    final time = DateTime(2026, 9, 24);
    final points = [
      PricePoint(time: time, close: 1),
      PricePoint(time: time, close: 2),
      PricePoint(time: time, close: 3),
      PricePoint(time: time, close: 4),
      PricePoint(time: time, close: 5),
    ];

    test('clamps to the first point at the left edge', () {
      expect(nearestPointIndex(points, -10, 100), 0);
      expect(nearestPointIndex(points, 0, 100), 0);
    });

    test('clamps to the last point at the right edge', () {
      expect(nearestPointIndex(points, 100, 100), points.length - 1);
      expect(nearestPointIndex(points, 1000, 100), points.length - 1);
    });

    test('picks the nearest point in the middle', () {
      expect(nearestPointIndex(points, 50, 100), 2);
    });

    test('handles a single point without dividing by zero', () {
      expect(nearestPointIndex([points.first], 30, 100), 0);
    });
  });

  group('referencePrice', () {
    final quote = MarketQuote(
      symbol: 'BMRI.JK',
      currency: 'IDR',
      price: 4070,
      marketTime: DateTime(2026, 9, 24),
      fetchedAt: DateTime(2026, 9, 24),
      previousClose: 4190,
    );

    test('uses previousClose for oneDay', () {
      expect(referencePrice(ChartRange.oneDay, quote, null), 4190);
    });

    test('uses the first chart point for other ranges', () {
      final series = PriceSeries(
        symbol: 'BMRI.JK',
        currency: 'IDR',
        range: ChartRange.oneMonth,
        points: [
          PricePoint(time: DateTime(2026, 8, 24), close: 3900),
          PricePoint(time: DateTime(2026, 9, 24), close: 4070),
        ],
      );

      expect(referencePrice(ChartRange.oneMonth, quote, series), 3900);
    });

    test('returns null without series data', () {
      expect(referencePrice(ChartRange.oneMonth, quote, null), isNull);
      expect(
        referencePrice(
          ChartRange.oneMonth,
          quote,
          const PriceSeries(
            symbol: 'BMRI.JK',
            currency: 'IDR',
            range: ChartRange.oneMonth,
            points: [],
          ),
        ),
        isNull,
      );
    });
  });
}
