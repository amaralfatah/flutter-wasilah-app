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

    // Bentuk response diperiksa dengan `is`/pattern, bukan cast `as`: cast
    // yang meleset melempar TypeError (Error, bukan Exception) yang lolos
    // dari fallback cache di MarketRepository. Bentuk apa pun yang tak
    // terduga menjadi MarketDataUnavailableException.
    final Object? body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      throw const MarketDataUnavailableException();
    }

    final chart = _mapOf(_mapOf(body)?['chart']);
    if (chart == null) {
      throw const MarketDataUnavailableException();
    }
    if (chart['error'] != null) {
      throw const MarketSymbolNotFoundException();
    }

    final results = chart['result'];
    if (results == null || (results is List && results.isEmpty)) {
      throw const MarketSymbolNotFoundException();
    }

    final result = results is List ? _mapOf(results.first) : null;
    final meta = _mapOf(result?['meta']);
    if (result == null || meta == null) {
      throw const MarketDataUnavailableException();
    }

    final rawPrice = _doubleOf(meta['regularMarketPrice']);
    if (rawPrice == null) {
      throw const MarketDataUnavailableException();
    }

    final unit = majorCurrencyUnitOf(_currencyOf(symbol, meta['currency']));
    final currency = unit.currency;
    double? toMajor(double? value) =>
        value == null ? null : value / unit.divisor;

    final previousClose = toMajor(
      _doubleOf(meta['chartPreviousClose']) ?? _doubleOf(meta['previousClose']),
    );

    final quote = MarketQuote(
      symbol: symbol,
      currency: currency,
      price: rawPrice / unit.divisor,
      marketTime: _dateTimeOf(meta['regularMarketTime']) ?? _clock(),
      fetchedAt: _clock(),
      previousClose: previousClose,
      dayHigh: toMajor(_doubleOf(meta['regularMarketDayHigh'])),
      dayLow: toMajor(_doubleOf(meta['regularMarketDayLow'])),
      fiftyTwoWeekHigh: toMajor(_doubleOf(meta['fiftyTwoWeekHigh'])),
      fiftyTwoWeekLow: toMajor(_doubleOf(meta['fiftyTwoWeekLow'])),
      volume: _doubleOf(meta['regularMarketVolume']),
    );

    final series = PriceSeries(
      symbol: symbol,
      currency: currency,
      range: range,
      points: _parsePoints(result, unit.divisor),
      previousClose: previousClose,
    );

    return (quote: quote, series: series);
  }

  /// Mata uang dari `meta.currency`. Tanpa mata uang, harga tidak bisa
  /// dikonversi dengan benar (mengasumsikan IDR untuk aset USD membuat
  /// nilainya ~16.000x terlalu kecil), jadi data dianggap tidak tersedia --
  /// kecuali saham IDX (`.JK`), yang selalu dikutip dalam IDR.
  static String _currencyOf(String symbol, Object? raw) {
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    if (symbol.toUpperCase().endsWith('.JK')) {
      return 'IDR';
    }
    throw const MarketDataUnavailableException();
  }

  List<PricePoint> _parsePoints(Map<String, dynamic> result, double divisor) {
    final timestamps = result['timestamp'];
    final quoteList = _mapOf(result['indicators'])?['quote'];
    final closes = quoteList is List && quoteList.isNotEmpty
        ? (_mapOf(quoteList.first)?['close'])
        : null;
    if (timestamps is! List || closes is! List) {
      return const [];
    }

    final points = <PricePoint>[];
    for (var i = 0; i < timestamps.length && i < closes.length; i++) {
      final close = _doubleOf(closes[i]);
      final time = _dateTimeOf(timestamps[i]);
      if (close == null || time == null) {
        // Yahoo mengisi null di menit/hari tanpa transaksi; titik ini
        // dibuang, bukan digambar sebagai nol atau interpolasi.
        continue;
      }
      points.add(PricePoint(time: time, close: close / divisor));
    }
    return points;
  }

  static Map<String, dynamic>? _mapOf(Object? value) =>
      value is Map<String, dynamic> ? value : null;

  static double? _doubleOf(Object? value) =>
      value is num && value.isFinite ? value.toDouble() : null;

  /// Epoch detik Yahoo ke [DateTime]; `null` bila bukan angka atau di luar
  /// rentang [DateTime].
  static DateTime? _dateTimeOf(Object? value) {
    if (value is! num || !value.isFinite) {
      return null;
    }
    final millis = value * 1000;
    if (millis.abs() > _maxEpochMillis) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis.toInt());
  }

  static const _maxEpochMillis = 8640000000000000;

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
      queryParameters['period1'] =
          (threeYearsAgo.millisecondsSinceEpoch ~/ 1000).toString();
      queryParameters['period2'] = (now.millisecondsSinceEpoch ~/ 1000)
          .toString();
    }

    return Uri.parse(
      '$_baseUrl/$encodedSymbol',
    ).replace(queryParameters: queryParameters);
  }
}

/// Yahoo mengutip sebagian bursa dalam satuan minor: LSE dalam pence
/// (`GBp`/`GBX`), JSE dalam sen rand (`ZAc`), TASE dalam agorot (`ILA`).
/// Harga dibagi `divisor` dan mata uang dipetakan ke satuan mayornya supaya
/// kurs forex (`GBPIDR=X`, dst.) bisa langsung dipakai. Kode dicocokkan
/// case-sensitive: `GBp` (pence) berbeda dengan `GBP` (pound).
({String currency, double divisor}) majorCurrencyUnitOf(String currency) {
  return switch (currency.trim()) {
    'GBp' || 'GBX' => (currency: 'GBP', divisor: 100),
    'ZAc' || 'ZAC' => (currency: 'ZAR', divisor: 100),
    'ILA' => (currency: 'ILS', divisor: 100),
    final other => (currency: other, divisor: 1),
  };
}
