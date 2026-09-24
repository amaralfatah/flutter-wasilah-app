import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/database/app_database.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/features/market/data/market_repository.dart';
import 'package:flutter_wasilah_app/features/market/data/models/chart_range.dart';
import 'package:flutter_wasilah_app/features/market/data/models/price_series.dart';
import 'package:flutter_wasilah_app/features/market/data/yahoo_finance_client.dart';
import 'package:http/http.dart' as http;

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final yahooFinanceClientProvider = Provider<YahooFinanceClient>((ref) {
  return YahooFinanceClient(ref.watch(httpClientProvider));
});

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(yahooFinanceClientProvider),
  );
});

/// Harga terkini + seri chart 1D. `autoDispose`: membuka ulang halaman
/// pasar memicu fetch baru; tidak ada polling/timer.
final AutoDisposeFutureProviderFamily<QuoteResult, String>
marketQuoteProvider = FutureProvider.autoDispose.family<QuoteResult, String>((
  ref,
  symbol,
) async {
  final repository = ref.watch(marketRepositoryProvider);
  return repository.getQuote(symbol);
});

typedef ChartArgs = ({String symbol, ChartRange range});

/// Chart untuk range apa pun. Untuk [ChartRange.oneDay], seri diambil dari
/// [marketQuoteProvider] (satu request menghasilkan quote + chart 1D)
/// alih-alih fetch ulang; bila quote sedang stale (offline), seri 1D tidak
/// tersedia dan provider ini melempar [MarketDataUnavailableException].
final AutoDisposeFutureProviderFamily<PriceSeries, ChartArgs>
priceChartProvider = FutureProvider.autoDispose.family<PriceSeries, ChartArgs>((
  ref,
  args,
) async {
      if (args.range == ChartRange.oneDay) {
        final quoteResult = await ref.watch(
          marketQuoteProvider(args.symbol).future,
        );
        final series = quoteResult.oneDaySeries;
        if (series == null) {
          throw const MarketDataUnavailableException();
        }
        return series;
      }

      final repository = ref.watch(marketRepositoryProvider);
      return repository.getChart(args.symbol, args.range);
    });
