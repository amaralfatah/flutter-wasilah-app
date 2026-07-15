import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';

void main() {
  group('formatCurrency', () {
    test('formats rupiah with thousands separators', () {
      expect(formatCurrency(1000000), 'Rp1.000.000');
      expect(formatCurrency(42400000), 'Rp42.400.000');
      expect(formatCurrency(0), 'Rp0');
    });
  });

  group('formatCompactCurrency', () {
    test('formats large values into juta', () {
      expect(formatCompactCurrency(128400000), 'Rp128,4 juta');
    });
  });
}
