import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/holding.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';

void main() {
  group('Asset JSON', () {
    test('round-trips with marketSymbol set', () {
      const asset = Asset(
        id: 'bmri',
        name: 'Bank Mandiri',
        code: 'BMRI',
        category: AssetCategory.stock,
        marketSymbol: 'BMRI.JK',
      );

      final decoded = Asset.fromJson(asset.toJson());

      expect(decoded, asset);
      expect(decoded.marketSymbol, 'BMRI.JK');
    });

    test('round-trips without marketSymbol (older JSON)', () {
      const asset = Asset(
        id: 'cash',
        name: 'Kas',
        code: 'CASH',
        category: AssetCategory.cash,
      );

      final json = asset.toJson()..remove('marketSymbol');
      final decoded = Asset.fromJson(json);

      expect(decoded.marketSymbol, isNull);
      expect(decoded, asset);
    });
  });

  group('Holding', () {
    final holding = Holding(
      assetId: 'gold',
      currentValue: 12000000,
      lastUpdatedAt: DateTime(2026, 9, 24),
      totalCost: 10000000,
      quantity: 10,
      avgBuyPrice: 1000000,
    );

    test('round-trips through JSON', () {
      expect(Holding.fromJson(holding.toJson()), holding);
    });

    test('computes profit/loss against total cost', () {
      expect(holding.profitLoss, 2000000);
      expect(holding.profitLossPercentage, 20);
      expect(holding.effectivePriceCurrency, 'IDR');
    });

    test('has no profit/loss without cost', () {
      final noCost = holding.copyWith(totalCost: null);
      expect(noCost.profitLoss, isNull);
      expect(noCost.profitLossPercentage, isNull);
    });
  });

  group('PortfolioPosition', () {
    test('empty position represents an asset outside the portfolio', () {
      const asset = Asset(
        id: 'cash',
        name: 'Kas',
        code: 'CASH',
        category: AssetCategory.cash,
      );

      final position = PortfolioPosition.empty(asset);

      expect(position.id, 'cash');
      expect(position.currentValue, 0);
      expect(position.allocationPercentage, 0);
      expect(position.totalCost, isNull);
      expect(PortfolioPosition.fromJson(position.toJson()), position);
    });
  });
}
