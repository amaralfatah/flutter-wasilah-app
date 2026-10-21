import 'package:flutter/services.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';

/// Input angka desimal format Indonesia (`1.234,56`) yang menerima titik
/// maupun koma sebagai tanda desimal, mengikuti tombol yang ada di keyboard.
///
/// Pemisah ribuan (`.`) disisipkan otomatis. Koma selalu desimal; titik
/// dibaca dari angka sesudahnya: tiga digit atau lebih berarti pemisah ribuan
/// (`10.000`), satu-dua digit berarti desimal (`1.5`), dan sesudah bagian
/// bulat nol selalu desimal (`0.123`). Selama masih ambigu titik ketikan
/// dibiarkan tampil apa adanya supaya `10.0` masih bisa menjadi `10.000`.
class DecimalInputFormatter extends TextInputFormatter {
  const DecimalInputFormatter({this.maxDecimals = 8});

  final int maxDecimals;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final oldText = oldValue.text.replaceAll(' ', '');
    final inserted = text.length - oldText.length;

    // Menghapus pada angka berpemisah ribuan (`10.000` → `10.00`) tetap
    // dibaca ribuan, kecuali titiknya memang titik desimal yang belum pasti.
    final groupingOnly =
        maxDecimals == 0 ||
        (inserted < 0 && _DecimalParts.parse(oldText).separator != '.');
    final parts = _DecimalParts.parse(text, groupingOnly: groupingOnly);

    var separator = parts.separator;
    var fraction = parts.fraction;
    // Teks tempelan sudah lengkap, jadi titik desimalnya tak lagi ambigu.
    if (separator == '.' && inserted > 1) {
      separator = ',';
    }
    if (fraction != null && fraction.length > maxDecimals) {
      fraction = fraction.substring(0, maxDecimals);
    }

    if (parts.integer.isEmpty && separator == null) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final integerPart = parts.integer.isEmpty
        ? '0'
        : formatNumber(double.parse(parts.integer));
    final formatted = separator == null
        ? integerPart
        : '$integerPart$separator$fraction';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Parse teks dari [DecimalInputFormatter] (`1.234,56`, `10.000`, `1.5`);
/// `null` bila kosong atau tidak valid.
double? parseDecimalInput(String text) {
  final parts = _DecimalParts.parse(text.trim().replaceAll(' ', ''));
  if (parts.integer.isEmpty && (parts.fraction ?? '').isEmpty) {
    return null;
  }
  final integer = parts.integer.isEmpty ? '0' : parts.integer;
  final fraction = parts.fraction ?? '';
  return double.tryParse(fraction.isEmpty ? integer : '$integer.$fraction');
}

/// Parse nominal yang disalin dari aplikasi broker berformat bebas: titik
/// maupun koma boleh jadi desimal (`19.228` dari Tokocrypto, `19,228`).
/// Satu pemisah saja dibaca desimal; pemisah yang berulang dibaca ribuan;
/// bila keduanya ada, yang terakhir desimal (`1,234.56`, `1.234,56`).
/// `null` bila kosong atau tidak valid.
double? parseLooseDecimal(String text) {
  var value = text.trim().replaceAll(' ', '');
  if (value.isEmpty) {
    return null;
  }
  final lastDot = value.lastIndexOf('.');
  final lastComma = value.lastIndexOf(',');
  if (lastDot >= 0 && lastComma >= 0) {
    final decimal = lastDot > lastComma ? '.' : ',';
    final grouping = decimal == '.' ? ',' : '.';
    value = value.replaceAll(grouping, '').replaceAll(decimal, '.');
  } else {
    final separator = lastDot >= 0 ? '.' : ',';
    value = separator.allMatches(value).length > 1
        ? value.replaceAll(separator, '')
        : value.replaceAll(separator, '.');
  }
  return double.tryParse(value);
}

/// Digit bagian bulat & pecahan dari teks angka. [separator] `,` berarti
/// desimal pasti; `.` berarti titik ketikan yang dibaca desimal tapi masih
/// bisa berubah jadi pemisah ribuan bila diikuti digit lagi.
class _DecimalParts {
  const _DecimalParts(this.integer, this.fraction, this.separator);

  factory _DecimalParts.parse(String text, {bool groupingOnly = false}) {
    final commaIndex = text.indexOf(',');
    if (commaIndex >= 0) {
      return _DecimalParts(
        _digits(text.substring(0, commaIndex)),
        _digits(text.substring(commaIndex + 1)),
        ',',
      );
    }

    final dotIndex = text.lastIndexOf('.');
    if (groupingOnly || dotIndex < 0) {
      return _DecimalParts(_digits(text), null, null);
    }

    final integer = _digits(text.substring(0, dotIndex));
    final tail = _digits(text.substring(dotIndex + 1));
    if (RegExp(r'^0*$').hasMatch(integer)) {
      return _DecimalParts(integer.isEmpty ? '' : '0', tail, ',');
    }
    if (tail.length >= 3) {
      return _DecimalParts(_digits(text), null, null);
    }
    return _DecimalParts(integer, tail, '.');
  }

  final String integer;
  final String? fraction;
  final String? separator;

  static String _digits(String value) => value.replaceAll(RegExp('[^0-9]'), '');
}
