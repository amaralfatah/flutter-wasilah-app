import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/utils/validators.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations_en.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations_id.dart';

void main() {
  final id = AppLocalizationsId();
  final en = AppLocalizationsEn();

  group('parseCurrencyInput', () {
    test('ignores thousand separators and prefixes', () {
      expect(parseCurrencyInput('Rp1.250.000'), 1250000);
    });

    test('returns null without any digit', () {
      expect(parseCurrencyInput('Rp'), isNull);
    });

    test('drops the decimal part after a comma', () {
      expect(parseCurrencyInput('1.500.000,50'), 1500000);
      expect(parseCurrencyInput('1500000,5'), 1500000);
      expect(parseCurrencyInput('Rp 2.000,'), 2000);
    });

    test('returns null when only a decimal part is given', () {
      expect(parseCurrencyInput(',50'), isNull);
    });
  });

  group('validateCurrencyValue', () {
    test('requires a value', () {
      expect(validateCurrencyValue(' ', id), 'Nilai aset wajib diisi.');
      expect(validateCurrencyValue(' ', en), 'Asset value is required.');
    });

    test('rejects text without digits', () {
      expect(validateCurrencyValue('abc', id), 'Nilai aset tidak valid.');
      expect(validateCurrencyValue('abc', en), 'Invalid asset value.');
    });

    test('accepts a formatted amount', () {
      expect(validateCurrencyValue('1.000', id), isNull);
    });
  });

  test('validateOptionalCurrencyValue allows an empty field', () {
    expect(validateOptionalCurrencyValue('', id), isNull);
    expect(validateOptionalCurrencyValue('abc', id), 'Nilai aset tidak valid.');
  });

  test('validateRequiredText rejects blank text', () {
    expect(validateRequiredText('  ', message: 'wajib'), 'wajib');
    expect(validateRequiredText('BTC', message: 'wajib'), isNull);
  });

  test('validateSelectedAsset and validateSelectedDate require a value', () {
    expect(validateSelectedAsset('', id), 'Aset wajib dipilih.');
    expect(validateSelectedAsset('', en), 'Please select an asset.');
    expect(validateSelectedAsset('btc', id), isNull);
    expect(validateSelectedDate(null, id), 'Tanggal wajib dipilih.');
    expect(validateSelectedDate(null, en), 'Please select a date.');
    expect(validateSelectedDate(DateTime(2026), id), isNull);
  });

  test('validateNote limits the length', () {
    expect(validateNote('a' * 200, id), isNull);
    expect(validateNote('a' * 201, id), 'Catatan maksimal 200 karakter.');
    expect(
      validateNote('a' * 201, en),
      'Note can be at most 200 characters.',
    );
  });

  test('check functions return failure codes without l10n', () {
    expect(checkSelectedAsset(null), ValidationFailure.assetRequired);
    expect(checkNote('a' * 201), ValidationFailure.noteTooLong);
    expect(checkCurrencyValue('5'), isNull);
  });

  test('validationMessage localizes every failure', () {
    for (final failure in ValidationFailure.values) {
      expect(validationMessage(en, failure), isNotEmpty);
      expect(validationMessage(id, failure), isNotEmpty);
    }
  });
}
