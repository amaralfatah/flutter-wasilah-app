import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/purchase_math.dart';

void main() {
  group('applyPurchase', () {
    test('weights the new purchase into the existing average', () {
      // Tiga pembelian BTC Tokocrypto, dicatat berurutan.
      var result = applyPurchase(
        quantity: null,
        avgBuyPrice: null,
        totalCost: null,
        boughtQuantity: 0.00038,
        paid: 29.69472,
        rateToIdr: 16000,
      )!;
      result = applyPurchase(
        quantity: result.quantity,
        avgBuyPrice: result.avgBuyPrice,
        totalCost: result.totalCost,
        boughtQuantity: 0.00023,
        paid: 19.228,
        rateToIdr: 16000,
      )!;
      result = applyPurchase(
        quantity: result.quantity,
        avgBuyPrice: result.avgBuyPrice,
        totalCost: result.totalCost,
        boughtQuantity: 0.00024,
        paid: 19.8782376,
        rateToIdr: 16000,
      )!;

      expect(result.quantity, closeTo(0.00085, 1e-12));
      expect(result.avgBuyPrice, closeTo(68.8009576 / 0.00085, 1e-6));
      expect(result.totalCost, closeTo(68.8009576 * 16000, 1e-6));
    });

    test('keeps the old IDR cost and adds the purchase at today rate', () {
      final result = applyPurchase(
        quantity: 0.1,
        avgBuyPrice: 50000,
        totalCost: 75000000,
        boughtQuantity: 0.1,
        paid: 7000,
        rateToIdr: 16000,
      )!;

      expect(result.quantity, closeTo(0.2, 1e-12));
      expect(result.avgBuyPrice, closeTo(60000, 1e-6));
      expect(result.totalCost, closeTo(75000000 + 7000 * 16000, 1e-3));
    });

    test('treats IDX quantity as lots and the average as per share', () {
      final result = applyPurchase(
        quantity: 2,
        avgBuyPrice: 3500,
        totalCost: 700000,
        boughtQuantity: 1,
        paid: 366549,
        rateToIdr: 1,
        lotFactor: 100,
      )!;

      expect(result.quantity, 3);
      expect(result.avgBuyPrice, closeTo((700000 + 366549) / 300, 1e-9));
      expect(result.totalCost, closeTo(1066549, 1e-9));
    });

    test('falls back to the stored cost when the average is missing', () {
      final result = applyPurchase(
        quantity: 1,
        avgBuyPrice: null,
        totalCost: 1600000,
        boughtQuantity: 1,
        paid: 120,
        rateToIdr: 16000,
      )!;

      expect(result.avgBuyPrice, closeTo(110, 1e-9));
      expect(result.totalCost, closeTo(3520000, 1e-6));
    });

    test('returns null when the old position cannot be averaged', () {
      // Modal ada tapi jumlah unit kosong.
      expect(
        applyPurchase(
          quantity: null,
          avgBuyPrice: null,
          totalCost: 1000000,
          boughtQuantity: 1,
          paid: 10,
          rateToIdr: 1,
        ),
        isNull,
      );
      // Unit ada tapi avg dan modal kosong.
      expect(
        applyPurchase(
          quantity: 1,
          avgBuyPrice: null,
          totalCost: null,
          boughtQuantity: 1,
          paid: 10,
          rateToIdr: 1,
        ),
        isNull,
      );
    });

    test('returns null for non-positive purchase input', () {
      expect(
        applyPurchase(
          quantity: 1,
          avgBuyPrice: 10,
          totalCost: 10,
          boughtQuantity: 0,
          paid: 10,
          rateToIdr: 1,
        ),
        isNull,
      );
      expect(
        applyPurchase(
          quantity: 1,
          avgBuyPrice: 10,
          totalCost: 10,
          boughtQuantity: 1,
          paid: 0,
          rateToIdr: 1,
        ),
        isNull,
      );
    });
  });
}
