import 'dart:convert';
import 'dart:io';

import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/features/market/data/models/chart_range.dart';
import 'package:flutter_wasilah_app/features/market/data/models/market_quote.dart';
import 'package:flutter_wasilah_app/features/market/data/models/price_series.dart';
import 'package:http/http.dart' as http;

/// Klien untuk endpoint chart Yahoo Finance yang tidak resmi. Seluruh
/// akses ke Yahoo terkurung di sini supaya gampang diganti bila endpoint
/// ini berubah atau ditutup.
class YahooFinanceClient {
  YahooFinanceClient(this._httpClient, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final http.Client _httpClient;
  final DateTime Function() _clock;

  static const _baseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart';
  static const _timeout = Duration(seconds: 10);
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

  /// Satu request untuk [range]: mengembalikan quote (dari `meta`) dan
  /// seri chart-nya sekaligus.
  Future<({MarketQuote quote, PriceSeries series})> fetch(
    String symbol,
    ChartRange range,
  ) async {
    final uri = _buildUri(symbol, range);

    final http.Response response;
    try {
      response = await _httpClient
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(_timeout);
    } on Exception catch (_) {
      // SocketException, ClientException, TimeoutException, dll.
      throw const MarketDataUnavailableException();
    }

    if (response.statusCode == HttpStatus.notFound) {
      throw const MarketSymbolNotFoundException();
    }
    if (response.statusCode != HttpStatus.ok) {
      throw const MarketDataUnavailableException();
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const MarketDataUnavailableException();
    }

    final chart = body['chart'] as Map<String, dynamic>?;
    if (chart == null) {
      throw const MarketDataUnavailableException();
    }
    if (chart['error'] != null) {
      throw const MarketSymbolNotFoundException();
    }

    final results = chart['result'] as List<dynamic>?;
    if (results == null || results.isEmpty) {
      throw const MarketSymbolNotFoundException();
    }

    final result = results.first as Map<String, dynamic>;
    final meta = result['meta'] as Map<String, dynamic>?;
    if (meta == null) {
      throw const MarketDataUnavailableException();
    }

    final price = (meta['regularMarketPrice'] as num?)?.toDouble();
    if (price == null) {
      throw const MarketDataUnavailableException();
    }

    final currency = meta['currency'] as String? ?? 'IDR';
    final previousClose =
        (meta['chartPreviousClose'] as num?)?.toDouble() ??
        (meta['previousClose'] as num?)?.toDouble();
    final marketTimeEpoch = meta['regularMarketTime'] as num?;
    final marketTime = marketTimeEpoch == null
        ? _clock()
        : DateTime.fromMillisecondsSinceEpoch(
            marketTimeEpoch.toInt() * 1000,
          );

    final quote = MarketQuote(
      symbol: symbol,
      currency: currency,
      price: price,
      marketTime: marketTime,
      fetchedAt: _clock(),
      previousClose: previousClose,
    );

    final series = PriceSeries(
      symbol: symbol,
      currency: currency,
      range: range,
      points: _parsePoints(result),
      previousClose: previousClose,
    );

    return (quote: quote, series: series);
  }

  List<PricePoint> _parsePoints(Map<String, dynamic> result) {
    final timestamps = result['timestamp'] as List<dynamic>?;
    if (timestamps == null) {
      return const [];
    }

    final indicators = result['indicators'] as Map<String, dynamic>?;
    final quoteList = indicators?['quote'] as List<dynamic>?;
    final closes = quoteList == null || quoteList.isEmpty
        ? null
        : (quoteList.first as Map<String, dynamic>)['close'] as List<dynamic>?;
    if (closes == null) {
      return const [];
    }

    final points = <PricePoint>[];
    for (var i = 0; i < timestamps.length && i < closes.length; i++) {
      final close = (closes[i] as num?)?.toDouble();
      if (close == null) {
        // Yahoo mengisi null di menit/hari tanpa transaksi; titik ini
        // dibuang, bukan digambar sebagai nol atau interpolasi.
        continue;
      }
      final epoch = timestamps[i] as num;
      points.add(
        PricePoint(
          time: DateTime.fromMillisecondsSinceEpoch(epoch.toInt() * 1000),
          close: close,
        ),
      );
    }
    return points;
  }

  Uri _buildUri(String symbol, ChartRange range) {
    final encodedSymbol = Uri.encodeComponent(symbol);
    final queryParameters = <String, String>{'interval': range.interval};

    final rangeParam = range.range;
    if (rangeParam != null) {
      queryParameters['range'] = rangeParam;
    } else {
      // ChartRange.threeYears: '3y' bukan validRange Yahoo.
      final now = _clock();
      final threeYearsAgo = DateTime(now.year - 3, now.month, now.day);
      queryParameters['period1'] = (threeYearsAgo.millisecondsSinceEpoch ~/
              1000)
          .toString();
      queryParameters['period2'] = (now.millisecondsSinceEpoch ~/ 1000)
          .toString();
    }

    return Uri.parse(
      '$_baseUrl/$encodedSymbol',
    ).replace(queryParameters: queryParameters);
  }
}
