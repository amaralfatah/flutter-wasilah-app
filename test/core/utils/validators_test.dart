import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/utils/validators.dart';

void main() {
  group('parseCurrencyInput', () {
    test('ignores thousand separators and prefixes', () {
      expect(parseCurrencyInput('Rp1.250.000'), 1250000);
    });

    test('returns null without any digit', () {
      expect(parseCurrencyInput('Rp'), isNull);
    });
  });

  group('validateCurrencyValue', () {
    test('requires a value', () {
      expect(validateCurrencyValue(' '), 'Nilai aset wajib diisi.');
    });

    test('rejects text without digits', () {
      expect(validateCurrencyValue('abc'), 'Nilai aset tidak valid.');
    });

    test('accepts a formatted amount', () {
      expect(validateCurrencyValue('1.000'), isNull);
    });
  });

  test('validateOptionalCurrencyValue allows an empty field', () {
    expect(validateOptionalCurrencyValue(''), isNull);
    expect(validateOptionalCurrencyValue('abc'), 'Nilai aset tidak valid.');
  });

  test('validateRequiredText rejects blank text', () {
    expect(validateRequiredText('  ', message: 'wajib'), 'wajib');
    expect(validateRequiredText('BTC', message: 'wajib'), isNull);
  });

  test('validateSelectedAsset and validateSelectedDate require a value', () {
    expect(validateSelectedAsset(''), 'Aset wajib dipilih.');
    expect(validateSelectedAsset('btc'), isNull);
    expect(validateSelectedDate(null), 'Tanggal wajib dipilih.');
    expect(validateSelectedDate(DateTime(2026)), isNull);
  });

  test('validateNote limits the length', () {
    expect(validateNote('a' * 200), isNull);
    expect(validateNote('a' * 201), 'Catatan maksimal 200 karakter.');
  });
}
