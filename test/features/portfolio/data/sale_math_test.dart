import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/sale_math.dart';

void main() {
  group('applySale', () {
    test('reduces quantity and cost proportionally', () {
      // 0,0008 BTC dengan modal Rp1.000.000, jual separuh dapat $40.
      final result = applySale(
        quantity: 0.0008,
        avgBuyPrice: 78125,
        totalCost: 1000000,
        soldQuantity: 0.0004,
        received: 40,
        rateToIdr: 16000,
      )!;

      expect(result.quantity, closeTo(0.0004, 1e-12));
      expect(result.totalCost, closeTo(500000, 1e-6));
      expect(result.realizedProfit, closeTo(40 * 16000 - 500000, 1e-6));
    });

    test('selling everything leaves zero quantity and cost', () {
      final result = applySale(
        quantity: 0.00085,
        avgBuyPrice: 80942.3,
        totalCost: 1237041,
        // Sedikit di atas karena pembulatan input tetap dianggap habis.
        soldQuantity: 0.0008500000001,
        received: 70,
        rateToIdr: 16000,
      )!;

      expect(result.quantity, 0);
      expect(result.totalCost, 0);
      expect(result.realizedProfit, closeTo(70 * 16000 - 1237041, 1e-6));
    });

    test('derives cost from average price per share for IDX lots', () {
      // 10 lot BBCA avg 9.000 → modal 9.000.000; jual 4 lot.
      final result = applySale(
        quantity: 10,
        avgBuyPrice: 9000,
        totalCost: null,
        soldQuantity: 4,
        received: 3800000,
        rateToIdr: 1,
        lotFactor: 100,
      )!;

      expect(result.quantity, 6);
      expect(result.totalCost, closeTo(5400000, 1e-6));
      expect(result.realizedProfit, closeTo(200000, 1e-6));
    });

    test('without any cost the gain stays unknown', () {
      final result = applySale(
        quantity: 5,
        avgBuyPrice: null,
        totalCost: null,
        soldQuantity: 2,
        received: 100,
        rateToIdr: 1,
      )!;

      expect(result.quantity, 3);
      expect(result.totalCost, isNull);
      expect(result.realizedProfit, isNull);
    });

    test('rejects selling more than held or without quantity', () {
      expect(
        applySale(
          quantity: 1,
          avgBuyPrice: 10,
          totalCost: 10,
          soldQuantity: 2,
          received: 30,
          rateToIdr: 1,
        ),
        isNull,
      );
      expect(
        applySale(
          quantity: null,
          avgBuyPrice: null,
          totalCost: 10,
          soldQuantity: 1,
          received: 30,
          rateToIdr: 1,
        ),
        isNull,
      );
      expect(
        applySale(
          quantity: 1,
          avgBuyPrice: 10,
          totalCost: 10,
          soldQuantity: 0,
          received: 30,
          rateToIdr: 1,
        ),
        isNull,
      );
    });
  });
}
