import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/market/data/models/market_quote.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/market_valuation.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/holding.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';

void main() {
  final priceAt = DateTime(2026, 10, 2, 15, 30);

  MarketQuote quote(String symbol, double price, String currency) =>
      MarketQuote(
        symbol: symbol,
        currency: currency,
        price: price,
        marketTime: priceAt,
        fetchedAt: priceAt,
      );

  PortfolioPosition position({
    required String id,
    required AssetCategory category,
    required double value,
    String? symbol,
    double? quantity,
  }) => PortfolioPosition(
    asset: Asset(
      id: id,
      name: id,
      code: id.toUpperCase(),
      category: category,
      marketSymbol: symbol,
    ),
    holding: Holding(
      assetId: id,
      currentValue: value,
      lastUpdatedAt: DateTime(2026, 9),
      quantity: quantity,
    ),
    allocationPercentage: 0,
  );

  test('values IDX stock in lots and USD crypto via the IDR rate', () {
    final result = applyMarketPrices(
      [
        position(
          id: 'bmri',
          category: AssetCategory.stock,
          value: 1000000,
          symbol: 'BMRI.JK',
          quantity: 2,
        ),
        position(
          id: 'btc',
          category: AssetCategory.crypto,
          value: 1000000,
          symbol: 'BTC-USD',
          quantity: 0.01,
        ),
      ],
      {
        'BMRI.JK': quote('BMRI.JK', 5000, 'IDR'),
        'BTC-USD': quote('BTC-USD', 60000, 'USD'),
        'USDIDR=X': quote('USDIDR=X', 16000, 'IDR'),
      },
    );

    final byId = {for (final item in result) item.id: item};
    expect(byId['bmri']!.currentValue, 2 * 100 * 5000);
    expect(byId['btc']!.currentValue, 0.01 * 60000 * 16000);
    expect(byId['btc']!.marketPriceAt, priceAt);
    expect(result.first.id, 'btc');
    expect(
      result.fold<double>(0, (sum, item) => sum + item.allocationPercentage),
      closeTo(100, 1e-9),
    );
  });

  test('keeps the recorded value when price, rate, or quantity is missing', () {
    final result = applyMarketPrices(
      [
        position(
          id: 'spy',
          category: AssetCategory.indexEtf,
          value: 500,
          symbol: 'SPY',
          quantity: 1,
        ),
        position(
          id: 'bbri',
          category: AssetCategory.stock,
          value: 400,
          symbol: 'BBRI.JK',
        ),
        position(
          id: 'gold',
          category: AssetCategory.preciousMetal,
          value: 300,
          symbol: 'GC=F',
          quantity: 10,
        ),
      ],
      {
        'SPY': quote('SPY', 600, 'USD'),
        'BBRI.JK': quote('BBRI.JK', 4000, 'IDR'),
        'GC=F': quote('GC=F', 2500, 'USD'),
      },
    );

    expect(result.map((item) => item.currentValue), [500, 400, 300]);
    expect(result.every((item) => !item.isMarketValued), isTrue);
  });

  test('returns positions unchanged without quotes', () {
    final positions = [
      position(id: 'cash', category: AssetCategory.cash, value: 100),
    ];
    expect(applyMarketPrices(positions, const {}), same(positions));
  });

  test('builds records only for market-valued holdings, with the FX rate', () {
    final records = marketValueRecordsOf(
      [
        position(
          id: 'btc',
          category: AssetCategory.crypto,
          value: 1,
          symbol: 'BTC-USD',
          quantity: 0.01,
        ),
        position(
          id: 'bmri',
          category: AssetCategory.stock,
          value: 1,
          symbol: 'BMRI.JK',
          quantity: 2,
        ),
        position(id: 'cash', category: AssetCategory.cash, value: 100),
      ],
      {
        'BTC-USD': quote('BTC-USD', 60000, 'USD'),
        'BMRI.JK': quote('BMRI.JK', 5000, 'IDR'),
        'USDIDR=X': quote('USDIDR=X', 16000, 'IDR'),
      },
    );

    expect(records, [
      (
        assetId: 'btc',
        totalValue: 0.01 * 60000 * 16000,
        fxCurrency: 'USD',
        fxRate: 16000.0,
      ),
      (
        assetId: 'bmri',
        totalValue: 2.0 * 100 * 5000,
        fxCurrency: null,
        fxRate: null,
      ),
    ]);
  });
}
