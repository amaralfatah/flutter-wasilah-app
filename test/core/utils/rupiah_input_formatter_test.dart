import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/utils/rupiah_input_formatter.dart';

void main() {
  test('formats digits with thousands separators', () {
    const formatter = RupiahInputFormatter();

    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '1000000'),
    );

    expect(result.text, '1.000.000');
    expect(result.selection, const TextSelection.collapsed(offset: 9));
  });

  test('clears non digit input', () {
    const formatter = RupiahInputFormatter();

    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: 'abc'),
    );

    expect(result.text, isEmpty);
    expect(result.selection.baseOffset, 0);
  });
}
