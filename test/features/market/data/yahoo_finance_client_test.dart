import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/features/market/data/models/chart_range.dart';
import 'package:flutter_wasilah_app/features/market/data/yahoo_finance_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _bmriChartJson = '''
{
  "chart": {
    "result": [
      {
        "meta": {
          "currency": "IDR",
          "symbol": "BMRI.JK",
          "regularMarketPrice": 4070.0,
          "chartPreviousClose": 4190.0,
          "previousClose": 4190.0,
          "regularMarketTime": 1727168400
        },
        "timestamp": [1727168100, 1727168160, 1727168220, 1727168280],
        "indicators": {
          "quote": [
            {
              "close": [4180.0, null, 4090, 4070.0]
            }
          ]
        }
      }
    ],
    "error": null
  }
}
''';

const _notFoundJson = '''
{
  "chart": {
    "result": null,
    "error": {"code": "Not Found", "description": "No data found"}
  }
}
''';

void main() {
  group('YahooFinanceClient.fetch', () {
    test('parses quote and drops null-close chart points', () async {
      final client = YahooFinanceClient(
        MockClient((request) async {
          return http.Response(_bmriChartJson, 200);
        }),
      );

      final result = await client.fetch('BMRI.JK', ChartRange.oneDay);

      expect(result.quote.symbol, 'BMRI.JK');
      expect(result.quote.currency, 'IDR');
      expect(result.quote.price, 4070.0);
      expect(result.quote.previousClose, 4190.0);
      expect(
        result.quote.marketTime,
        DateTime.fromMillisecondsSinceEpoch(1727168400 * 1000),
      );

      // 4 timestamps, but one close is null and must be dropped.
      expect(result.series.points, hasLength(3));
      expect(result.series.points.map((p) => p.close), [4180.0, 4090, 4070.0]);
      expect(result.series.previousClose, 4190.0);
    });

    test('sends encoded symbol, range/interval and a User-Agent', () async {
      late Uri capturedUri;
      late String? userAgent;
      final client = YahooFinanceClient(
        MockClient((request) async {
          capturedUri = request.url;
          userAgent = request.headers['User-Agent'];
          return http.Response(_bmriChartJson, 200);
        }),
      );

      await client.fetch('^JKSE', ChartRange.oneYear);

      expect(capturedUri.path, endsWith('%5EJKSE'));
      expect(capturedUri.queryParameters['range'], '1y');
      expect(capturedUri.queryParameters['interval'], '1d');
      expect(userAgent, isNotNull);
    });

    test('three-year range uses period1/period2 instead of range', () async {
      late Uri capturedUri;
      final now = DateTime(2026, 9, 24);
      final client = YahooFinanceClient(
        MockClient((request) async {
          capturedUri = request.url;
          return http.Response(_bmriChartJson, 200);
        }),
        clock: () => now,
      );

      await client.fetch('SPY', ChartRange.threeYears);

      expect(capturedUri.queryParameters.containsKey('range'), isFalse);
      final period1 = int.parse(capturedUri.queryParameters['period1']!);
      final period2 = int.parse(capturedUri.queryParameters['period2']!);
      expect(
        DateTime.fromMillisecondsSinceEpoch(period2 * 1000),
        now,
      );
      expect(
        DateTime.fromMillisecondsSinceEpoch(period1 * 1000),
        DateTime(2023, 9, 24),
      );
    });

    test('throws MarketSymbolNotFoundException on HTTP 404', () async {
      final client = YahooFinanceClient(
        MockClient((request) async => http.Response('not found', 404)),
      );

      expect(
        () => client.fetch('NOPE', ChartRange.oneDay),
        throwsA(isA<MarketSymbolNotFoundException>()),
      );
    });

    test(
      'throws MarketSymbolNotFoundException when chart.error is set',
      () async {
        final client = YahooFinanceClient(
          MockClient((request) async => http.Response(_notFoundJson, 200)),
        );

        expect(
          () => client.fetch('NOPE', ChartRange.oneDay),
          throwsA(isA<MarketSymbolNotFoundException>()),
        );
      },
    );

    test(
      'throws MarketDataUnavailableException on HTTP 429/500',
      () async {
        final tooManyRequests = YahooFinanceClient(
          MockClient((request) async => http.Response('rate limited', 429)),
        );
        final serverError = YahooFinanceClient(
          MockClient((request) async => http.Response('boom', 500)),
        );

        await expectLater(
          tooManyRequests.fetch('BMRI.JK', ChartRange.oneDay),
          throwsA(isA<MarketDataUnavailableException>()),
        );
        await expectLater(
          serverError.fetch('BMRI.JK', ChartRange.oneDay),
          throwsA(isA<MarketDataUnavailableException>()),
        );
      },
    );

    test(
      'throws MarketDataUnavailableException on malformed body',
      () async {
        final client = YahooFinanceClient(
          MockClient((request) async => http.Response('not json', 200)),
        );

        expect(
          () => client.fetch('BMRI.JK', ChartRange.oneDay),
          throwsA(isA<MarketDataUnavailableException>()),
        );
      },
    );

    test(
      'throws MarketDataUnavailableException when the client throws',
      () async {
        final client = YahooFinanceClient(
          MockClient((request) async => throw http.ClientException('down')),
        );

        expect(
          () => client.fetch('BMRI.JK', ChartRange.oneDay),
          throwsA(isA<MarketDataUnavailableException>()),
        );
      },
    );

    test(
      'throws MarketDataUnavailableException without regularMarketPrice',
      () async {
        final body = jsonEncode({
          'chart': {
            'result': [
              {
                'meta': {'currency': 'IDR', 'symbol': 'BMRI.JK'},
              },
            ],
            'error': null,
          },
        });
        final client = YahooFinanceClient(
          MockClient((request) async => http.Response(body, 200)),
        );

        expect(
          () => client.fetch('BMRI.JK', ChartRange.oneDay),
          throwsA(isA<MarketDataUnavailableException>()),
        );
      },
    );
  });
}
