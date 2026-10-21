import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/utils/decimal_input_formatter.dart';

String _type(String old, String next, {int maxDecimals = 8}) {
  return DecimalInputFormatter(maxDecimals: maxDecimals)
      .formatEditUpdate(
        TextEditingValue(text: old),
        TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        ),
      )
      .text;
}

/// Ketik [keys] satu per satu seperti di keyboard, mulai dari field kosong.
String _typeKeys(String keys, {int maxDecimals = 8}) {
  final formatter = DecimalInputFormatter(maxDecimals: maxDecimals);
  var value = TextEditingValue.empty;
  for (final key in keys.split('')) {
    final next = value.text + key;
    value = formatter.formatEditUpdate(
      value,
      TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      ),
    );
  }
  return value.text;
}

void main() {
  test('groups thousands automatically', () {
    expect(_type('100', '1000'), '1.000');
    expect(_type('', '1234567'), '1.234.567');
  });

  test('accepts comma or dot as decimal separator', () {
    expect(_type('0', '0,'), '0,');
    expect(_type('0', '0.'), '0,');
    // Titik ketikan tetap tampil sampai jelas desimal atau ribuan.
    expect(_type('1.000', '1.000.'), '1.000.');
    expect(_type('1.000.', '1.000.5'), '1.000.5');
    expect(parseDecimalInput('1.000.5'), 1000.5);
    expect(_type('1.000,', '1.000,5'), '1.000,5');
    expect(_type('', '0.49185'), '0,49185');
    expect(_type('', '100.5'), '100,5');
  });

  test('treats thousands pattern and deletions as grouping', () {
    expect(_type('', '1.000'), '1.000');
    expect(_type('1.000', '1.00'), '100');
    expect(_type('10.000', '10.00'), '1.000');
    expect(_type('10.50', '10.5'), '10.5');
  });

  test('typing more digits after a grouped value keeps grouping', () {
    expect(_type('1.000', '1.0000'), '10.000');
    expect(_type('10.000', '10.0000'), '100.000');
    expect(_type('1.000', '1.0000', maxDecimals: 2), '10.000');
  });

  test('typed dot followed by three digits is a thousands separator', () {
    expect(_typeKeys('10.000'), '10.000');
    expect(parseDecimalInput(_typeKeys('10.000')), 10000);
    expect(_typeKeys('1.000'), '1.000');
    expect(parseDecimalInput(_typeKeys('1.000')), 1000);
    expect(_typeKeys('1.000.000'), '1.000.000');
    expect(parseDecimalInput(_typeKeys('1.000.000')), 1000000);
    expect(_typeKeys('10.000', maxDecimals: 2), '10.000');
  });

  test('typed dot followed by one or two digits is a decimal', () {
    expect(parseDecimalInput(_typeKeys('1.5')), 1.5);
    expect(parseDecimalInput(_typeKeys('16.25')), 16.25);
    expect(parseDecimalInput(_typeKeys('10.')), 10);
  });

  test('dot after a zero integer part is always a decimal', () {
    expect(_typeKeys('0.123'), '0,123');
    expect(parseDecimalInput(_typeKeys('0.123')), 0.123);
    expect(_typeKeys('0.49185'), '0,49185');
  });

  test('typed comma is always a decimal', () {
    expect(_typeKeys('10,5'), '10,5');
    expect(parseDecimalInput(_typeKeys('1000,000')), 1000);
  });

  test('limits decimals', () {
    expect(_type('', '1,23456', maxDecimals: 2), '1,23');
  });

  test('parseDecimalInput reads the formatted text', () {
    expect(parseDecimalInput('1.234,56'), 1234.56);
    expect(parseDecimalInput('0,49185'), 0.49185);
    expect(parseDecimalInput('1.000'), 1000);
    expect(parseDecimalInput(''), isNull);
  });
}
