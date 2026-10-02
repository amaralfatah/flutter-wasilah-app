import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/utils/rupiah_input_formatter.dart';

TextEditingValue _format(String text) => const RupiahInputFormatter()
    .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text));

void main() {
  test('formats digits with thousands separators', () {
    final result = _format('1000000');

    expect(result.text, '1.000.000');
    expect(result.selection, const TextSelection.collapsed(offset: 9));
  });

  test('clears non digit input', () {
    final result = _format('abc');

    expect(result.text, isEmpty);
    expect(result.selection.baseOffset, 0);
  });

  test('drops the decimal part of a pasted Indonesian amount', () {
    expect(_format('1.500.000,50').text, '1.500.000');
    expect(_format('1500000,5').text, '1.500.000');
  });

  test('a typed decimal comma is ignored', () {
    expect(_format('1.500,').text, '1.500');
  });
}
