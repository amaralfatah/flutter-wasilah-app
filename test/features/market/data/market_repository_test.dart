import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/features/market/data/market_repository.dart';
import 'package:flutter_wasilah_app/features/market/data/models/chart_range.dart';
import 'package:flutter_wasilah_app/features/market/data/models/market_quote.dart';
import 'package:flutter_wasilah_app/features/market/data/models/price_series.dart';
import 'package:flutter_wasilah_app/features/market/data/yahoo_finance_client.dart';

YahooFinanceClient _clientReturning(
  Future<({MarketQuote quote, PriceSeries series})> Function(
    String symbol,
    ChartRange range,
  )
  handler,
) {
  return _FakeYahooFinanceClient(handler);
}

void main() {
  late AppDatabase database;
  late MarketRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  MarketQuote quote({double price = 4070, DateTime? marketTime}) {
    return MarketQuote(
      symbol: 'BMRI.JK',
      currency: 'IDR',
      price: price,
      marketTime: marketTime ?? DateTime(2026, 9, 24),
      fetchedAt: DateTime(2026, 9, 24),
      previousClose: 4190,
    );
  }

  PriceSeries series() {
    return PriceSeries(
      symbol: 'BMRI.JK',
      currency: 'IDR',
      range: ChartRange.oneDay,
      points: [
        PricePoint(time: DateTime(2026, 9, 24, 9), close: 4180),
        PricePoint(time: DateTime(2026, 9, 24, 16), close: 4070),
      ],
      previousClose: 4190,
    );
  }

  group('getQuote', () {
    test('fetches, upserts the cache, and returns a fresh result', () async {
      repository = MarketRepository(
        database,
        _clientReturning((symbol, range) async {
          return (quote: quote(), series: series());
        }),
      );

      final result = await repository.getQuote('BMRI.JK');

      expect(result.isStale, isFalse);
      expect(result.quote.price, 4070);
      expect(result.oneDaySeries?.points, hasLength(2));

      final cached = await repository.getCachedQuote('BMRI.JK');
      expect(cached?.price, 4070);
    });

    test('falls back to cache with isStale when unavailable', () async {
      var callCount = 0;
      repository = MarketRepository(
        database,
        _clientReturning((symbol, range) async {
          callCount++;
          if (callCount == 1) {
            return (quote: quote(), series: series());
          }
          throw const MarketDataUnavailableException();
        }),
      );

      await repository.getQuote('BMRI.JK');
      final result = await repository.getQuote('BMRI.JK');

      expect(result.isStale, isTrue);
      expect(result.oneDaySeries, isNull);
      expect(result.quote.price, 4070);
    });

    test('rethrows MarketDataUnavailableException without a cache', () {
      repository = MarketRepository(
        database,
        _clientReturning((symbol, range) async {
          throw const MarketDataUnavailableException();
        }),
      );

      expect(
        () => repository.getQuote('BMRI.JK'),
        throwsA(isA<MarketDataUnavailableException>()),
      );
    });

    test('rethrows MarketSymbolNotFoundException even with a cache', () async {
      var callCount = 0;
      repository = MarketRepository(
        database,
        _clientReturning((symbol, range) async {
          callCount++;
          if (callCount == 1) {
            return (quote: quote(), series: series());
          }
          throw const MarketSymbolNotFoundException();
        }),
      );

      await repository.getQuote('BMRI.JK');

      expect(
        () => repository.getQuote('BMRI.JK'),
        throwsA(isA<MarketSymbolNotFoundException>()),
      );
    });
  });

  group('getChart', () {
    test('does not touch the quote cache', () async {
      repository = MarketRepository(
        database,
        _clientReturning((symbol, range) async {
          return (quote: quote(), series: series());
        }),
      );

      final result = await repository.getChart('BMRI.JK', ChartRange.oneYear);

      expect(result.points, hasLength(2));
      expect(await repository.getCachedQuote('BMRI.JK'), isNull);
    });
  });
}

class _FakeYahooFinanceClient implements YahooFinanceClient {
  _FakeYahooFinanceClient(this._handler);

  final Future<({MarketQuote quote, PriceSeries series})> Function(
    String symbol,
    ChartRange range,
  )
  _handler;

  @override
  Future<({MarketQuote quote, PriceSeries series})> fetch(
    String symbol,
    ChartRange range,
  ) {
    return _handler(symbol, range);
  }
}
