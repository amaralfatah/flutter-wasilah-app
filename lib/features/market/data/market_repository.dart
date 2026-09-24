import 'package:drift/drift.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/features/market/data/models/chart_range.dart';
import 'package:flutter_wasilah_app/features/market/data/models/market_quote.dart';
import 'package:flutter_wasilah_app/features/market/data/models/price_series.dart';
import 'package:flutter_wasilah_app/features/market/data/yahoo_finance_client.dart';

/// Hasil [MarketRepository.getQuote]. `oneDaySeries` adalah seri chart 1D
/// dari request yang sama, dan `null` bila `quote` datang dari cache
/// (`isStale` true) sehingga tidak ada seri baru untuk dipakai.
typedef QuoteResult = ({
  MarketQuote quote,
  PriceSeries? oneDaySeries,
  bool isStale,
});

class MarketRepository {
  MarketRepository(this._database, this._client);

  final AppDatabase _database;
  final YahooFinanceClient _client;

  /// Fetch quote + chart 1D, upsert quote ke cache. Bila fetch gagal
  /// karena [MarketDataUnavailableException] dan cache ada, kembalikan
  /// quote cache dengan `isStale: true` dan `oneDaySeries: null`. Tanpa
  /// cache, exception itu di-rethrow. [MarketSymbolNotFoundException]
  /// selalu di-rethrow -- simbol salah tidak ada hubungannya dengan cache.
  Future<QuoteResult> getQuote(String symbol) async {
    try {
      final result = await _client.fetch(symbol, ChartRange.oneDay);
      await _upsertQuote(result.quote);
      return (
        quote: result.quote,
        oneDaySeries: result.series,
        isStale: false,
      );
    } on MarketDataUnavailableException {
      final cached = await getCachedQuote(symbol);
      if (cached == null) {
        rethrow;
      }
      return (quote: cached, oneDaySeries: null, isStale: true);
    }
  }

  /// Chart untuk range selain 1D. Tanpa cache; quote di response ini
  /// tidak menimpa cache (cache hanya diperbarui lewat [getQuote]).
  Future<PriceSeries> getChart(String symbol, ChartRange range) async {
    final result = await _client.fetch(symbol, range);
    return result.series;
  }

  Future<MarketQuote?> getCachedQuote(String symbol) async {
    final row = await _database
        .customSelect(
          '''
      SELECT symbol, currency, price, previous_close, market_time, fetched_at
      FROM market_quotes
      WHERE symbol = ?
      LIMIT 1
      ''',
          variables: [Variable.withString(symbol)],
        )
        .getSingleOrNull();

    if (row == null) {
      return null;
    }

    return MarketQuote(
      symbol: row.read<String>('symbol'),
      currency: row.read<String>('currency'),
      price: row.read<double>('price'),
      marketTime: row.read<DateTime>('market_time'),
      fetchedAt: row.read<DateTime>('fetched_at'),
      previousClose: row.readNullable<double>('previous_close'),
    );
  }

  Future<void> _upsertQuote(MarketQuote quote) async {
    await _database.customStatement(
      '''
      INSERT INTO market_quotes (
        symbol, currency, price, previous_close, market_time, fetched_at
      ) VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(symbol) DO UPDATE SET
        currency = excluded.currency,
        price = excluded.price,
        previous_close = excluded.previous_close,
        market_time = excluded.market_time,
        fetched_at = excluded.fetched_at
      ''',
      [
        quote.symbol,
        quote.currency,
        quote.price,
        quote.previousClose,
        quote.marketTime.millisecondsSinceEpoch ~/ 1000,
        quote.fetchedAt.millisecondsSinceEpoch ~/ 1000,
      ],
    );
  }
}
