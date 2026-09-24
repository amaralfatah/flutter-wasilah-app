import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/market/data/market_symbol_suggestion.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';

void main() {
  group('suggestMarketSymbol', () {
    test('appends .JK for stocks', () {
      expect(suggestMarketSymbol(AssetCategory.stock, 'bmri'), 'BMRI.JK');
    });

    test('appends -USD for crypto', () {
      expect(suggestMarketSymbol(AssetCategory.crypto, 'btc'), 'BTC-USD');
    });

    test('keeps index/ETF code as-is', () {
      expect(suggestMarketSymbol(AssetCategory.indexEtf, 'spy'), 'SPY');
    });

    test('returns null for categories without a market price', () {
      expect(suggestMarketSymbol(AssetCategory.mutualFund, 'RDPT'), isNull);
      expect(suggestMarketSymbol(AssetCategory.preciousMetal, 'GOLD'), isNull);
      expect(suggestMarketSymbol(AssetCategory.cash, 'CASH'), isNull);
      expect(suggestMarketSymbol(AssetCategory.other, 'X'), isNull);
    });

    test('returns null for empty code', () {
      expect(suggestMarketSymbol(AssetCategory.stock, '  '), isNull);
    });

    test('keeps a code that already looks like a full symbol', () {
      expect(
        suggestMarketSymbol(AssetCategory.stock, 'bmri.jk'),
        'BMRI.JK',
      );
      expect(
        suggestMarketSymbol(AssetCategory.crypto, 'btc-usd'),
        'BTC-USD',
      );
      expect(suggestMarketSymbol(AssetCategory.stock, '^jkse'), '^JKSE');
    });
  });
}
