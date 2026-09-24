import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';

void main() {
  group('Asset JSON', () {
    test('round-trips with marketSymbol set', () {
      final asset = Asset(
        id: 'bmri',
        name: 'Bank Mandiri',
        code: 'BMRI',
        category: AssetCategory.stock,
        currentValue: 4070,
        allocationPercentage: 20,
        lastUpdatedAt: DateTime(2026, 9, 24),
        marketSymbol: 'BMRI.JK',
      );

      final decoded = Asset.fromJson(asset.toJson());

      expect(decoded, asset);
      expect(decoded.marketSymbol, 'BMRI.JK');
    });

    test('round-trips without marketSymbol (older JSON)', () {
      final asset = Asset(
        id: 'cash',
        name: 'Kas',
        code: 'CASH',
        category: AssetCategory.cash,
        currentValue: 100,
        allocationPercentage: 5,
        lastUpdatedAt: DateTime(2026, 9, 24),
      );

      final json = asset.toJson()..remove('marketSymbol');
      final decoded = Asset.fromJson(json);

      expect(decoded.marketSymbol, isNull);
      expect(decoded, asset);
    });
  });
}
