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

void main() {
  test('groups thousands automatically', () {
    expect(_type('100', '1000'), '1.000');
    expect(_type('', '1234567'), '1.234.567');
  });

  test('accepts comma or dot as decimal separator', () {
    expect(_type('0', '0,'), '0,');
    expect(_type('0', '0.'), '0,');
    expect(_type('1.000', '1.000.'), '1.000,');
    expect(_type('1.000,', '1.000,5'), '1.000,5');
    expect(_type('', '0.49185'), '0,49185');
    expect(_type('', '100.5'), '100,5');
  });

  test('treats thousands pattern and deletions as grouping', () {
    expect(_type('', '1.000'), '1.000');
    expect(_type('1.000', '1.00'), '100');
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
