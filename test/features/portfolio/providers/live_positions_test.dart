import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/features/market/data/market_repository.dart';
import 'package:flutter_wasilah_app/features/market/data/models/chart_range.dart';
import 'package:flutter_wasilah_app/features/market/data/models/market_quote.dart';
import 'package:flutter_wasilah_app/features/market/data/models/price_series.dart';
import 'package:flutter_wasilah_app/features/market/providers/market_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';

import '../../../helpers/mock_portfolio_repository.dart';

void main() {
  late MockPortfolioRepository repository;
  late _FakeMarketRepository market;
  late ProviderContainer container;

  setUp(() async {
    repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
    await repository.createAsset(
      const Asset(
        id: 'spy',
        name: 'S&P 500',
        code: 'SPY',
        category: AssetCategory.indexEtf,
        marketSymbol: 'SPY',
      ),
    );
    await repository.updateAssetValue(
      assetId: 'spy',
      totalValue: 9000000,
      recordedAt: DateTime(2026, 9),
      quantity: 1,
    );
    market = _FakeMarketRepository();
    container = ProviderContainer(
      overrides: [
        portfolioRepositoryProvider.overrideWithValue(repository),
        assetRepositoryProvider.overrideWithValue(repository),
        marketRepositoryProvider.overrideWithValue(market),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<double> spyValue() async {
    final positions = await container.read(positionListProvider.future);
    return positions
        .firstWhere((position) => position.id == 'spy')
        .currentValue;
  }

  test('shows cached prices first, then fresh prices', () async {
    market
      ..cached['SPY'] = _quote('SPY', 500, 'USD')
      ..cached['USDIDR=X'] = _quote('USDIDR=X', 15000, 'IDR')
      ..fresh['SPY'] = _quote('SPY', 600, 'USD')
      ..fresh['USDIDR=X'] = _quote('USDIDR=X', 16000, 'IDR');
    final subscription = container.listen(positionListProvider, (_, _) {});
    addTearDown(subscription.close);

    await container.read(holdingQuotesProvider.future);
    expect(await spyValue(), 500 * 15000);

    await pumpEventQueue();
    expect(await spyValue(), 600 * 16000);
    final summary = await container.read(portfolioSummaryProvider.future);
    expect(
      summary.totalValue,
      summary.positions.fold<double>(0, (sum, item) => sum + item.currentValue),
    );
  });

  test('offline without cache keeps the recorded value', () async {
    final subscription = container.listen(positionListProvider, (_, _) {});
    addTearDown(subscription.close);
    await pumpEventQueue();

    expect(await spyValue(), 9000000);
  });

  test('update form keeps reading the recorded value', () async {
    market
      ..fresh['SPY'] = _quote('SPY', 600, 'USD')
      ..fresh['USDIDR=X'] = _quote('USDIDR=X', 16000, 'IDR');
    final subscription = container.listen(assetOverviewProvider, (_, _) {});
    addTearDown(subscription.close);
    await pumpEventQueue();

    final overview = await container.read(assetOverviewProvider.future);
    expect(
      overview.firstWhere((position) => position.id == 'spy').currentValue,
      9000000,
    );
  });
}

MarketQuote _quote(String symbol, double price, String currency) => MarketQuote(
  symbol: symbol,
  currency: currency,
  price: price,
  marketTime: DateTime(2026, 10, 2, 16),
  fetchedAt: DateTime(2026, 10, 2, 16),
);

class _FakeMarketRepository implements MarketRepository {
  final Map<String, MarketQuote> cached = {};
  final Map<String, MarketQuote> fresh = {};

  @override
  Future<MarketQuote?> getCachedQuote(String symbol) async => cached[symbol];

  @override
  Future<QuoteResult> getQuote(String symbol) async {
    final quote = fresh[symbol];
    if (quote == null) {
      throw const MarketDataUnavailableException();
    }
    return (quote: quote, oneDaySeries: null, isStale: false);
  }

  @override
  Future<PriceSeries> getChart(String symbol, ChartRange range) =>
      throw UnimplementedError();
}
