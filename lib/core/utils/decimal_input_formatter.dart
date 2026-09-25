import 'package:flutter/services.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';

/// Input angka desimal format Indonesia (`1.234,56`) yang menerima titik
/// maupun koma sebagai tanda desimal, mengikuti tombol yang ada di keyboard.
///
/// Pemisah ribuan (`.`) disisipkan otomatis, jadi pengguna tak perlu
/// mengetiknya; titik yang diketik dibaca sebagai desimal kecuali teksnya
/// memang berpola ribuan (`1.000`) atau sedang menghapus.
class DecimalInputFormatter extends TextInputFormatter {
  const DecimalInputFormatter({this.maxDecimals = 8});

  final int maxDecimals;

  static final _groupedPattern = RegExp(r'^\d{1,3}(\.\d{3})+$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final isDeleting = text.length < oldValue.text.length;

    var decimalIndex = text.indexOf(',');
    if (decimalIndex < 0 && !isDeleting && !_groupedPattern.hasMatch(text)) {
      decimalIndex = text.lastIndexOf('.');
    }

    final integerDigits = _digits(
      decimalIndex < 0 ? text : text.substring(0, decimalIndex),
    );
    var fraction = decimalIndex < 0
        ? null
        : _digits(text.substring(decimalIndex + 1));
    if (maxDecimals == 0) {
      fraction = null;
    } else if (fraction != null && fraction.length > maxDecimals) {
      fraction = fraction.substring(0, maxDecimals);
    }

    if (integerDigits.isEmpty && fraction == null) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final integerPart = integerDigits.isEmpty
        ? '0'
        : formatNumber(double.parse(integerDigits));
    final formatted = fraction == null ? integerPart : '$integerPart,$fraction';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _digits(String value) => value.replaceAll(RegExp('[^0-9]'), '');
}

/// Parse teks dari [DecimalInputFormatter] (`1.234,56`); `null` bila kosong
/// atau tidak valid.
double? parseDecimalInput(String text) {
  final normalized = text
      .trim()
      .replaceAll(' ', '')
      .replaceAll('.', '')
      .replaceAll(',', '.');
  if (normalized.isEmpty) {
    return null;
  }
  return double.tryParse(normalized);
}
