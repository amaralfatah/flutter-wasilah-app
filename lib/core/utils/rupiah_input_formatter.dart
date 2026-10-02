import 'package:flutter/services.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/validators.dart';

class RupiahInputFormatter extends TextInputFormatter {
  const RupiahInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Bagian setelah koma desimal dibuang (rupiah tak berdesimal), supaya
    // tempelan `1.500.000,50` tidak jadi 150000050.
    final digits = rupiahDigits(newValue.text);
    if (digits.isEmpty) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = formatCurrency(
      double.parse(digits),
    ).replaceFirst('Rp', '');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
