import 'package:intl/intl.dart';

String formatCurrency(double value) {
  final rounded = value.round();
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    final reverseIndex = digits.length - index;
    buffer.write(digits[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  final prefix = rounded.isNegative ? '-Rp' : 'Rp';
  return '$prefix$buffer';
}

/// Nominal tanpa simbol `Rp` untuk kolom tabel, misalnya `12.802.174`.
String formatNumber(double value) {
  return formatCurrency(value).replaceFirst('Rp', '');
}

/// Seperti [formatNumber], dengan tanda `+` untuk nilai positif.
String formatSignedNumber(double value) {
  return value > 0 ? '+${formatNumber(value)}' : formatNumber(value);
}

String formatCompactCurrency(double value) {
  if (value.abs() >= 1000000000) {
    return 'Rp${_formatCompact(value / 1000000000)} miliar';
  }

  if (value.abs() >= 1000000) {
    return 'Rp${_formatCompact(value / 1000000)} juta';
  }

  return formatCurrency(value);
}

String _formatCompact(double value) {
  final hasDecimal = value.truncateToDouble() != value;
  final text = hasDecimal ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
  return text.replaceAll('.', ',');
}

/// Jumlah unit (lot, lembar, koin, gram). Bilangan bulat tampil dengan
/// pemisah ribuan (`1.000`); pecahan mempertahankan desimal signifikan
/// tanpa nol berlebih (`0,5`, `1,25`) — penting untuk kripto/gram.
String formatQuantity(double value) {
  if (value == value.roundToDouble()) {
    return formatNumber(value);
  }
  return NumberFormat('#,##0.########', 'id_ID').format(value);
}

/// Harga pasar (Yahoo Finance) dalam mata uang aslinya, tanpa konversi
/// kurs. `IDR` tanpa simbol seperti Stockbit (`4.070`); mata uang lain
/// pakai simbolnya (`$4,070.12`).
String formatPrice(double value, String currency) {
  if (currency == 'IDR') {
    return value.abs() < 1
        ? NumberFormat('#,##0.00', 'id_ID').format(value)
        : formatNumber(value);
  }

  return NumberFormat.simpleCurrency(
    name: currency,
    decimalDigits: 2,
  ).format(value);
}

/// Seperti [formatPrice] tapi tanpa desimal — untuk label sumbu Y chart,
/// di mana tick sudah dibulatkan `niceTicks` dan `$4,070.00` cuma bikin
/// sesak. IDR sudah bulat lewat [formatPrice].
String formatAxisPrice(double value, String currency) {
  if (currency == 'IDR') {
    return formatPrice(value, currency);
  }
  return NumberFormat.simpleCurrency(
    name: currency,
    decimalDigits: 0,
  ).format(value);
}

/// Harga avg beli per unit, IDR selalu dua desimal (mis. `Rp4.070,50`)
/// karena avg beli sering pecahan, beda dengan [formatPrice] yang
/// membulatkan IDR ke bilangan bulat.
String formatAvgPrice(double value, String currency) {
  if (currency == 'IDR') {
    return 'Rp${NumberFormat('#,##0.00', 'id_ID').format(value)}';
  }

  return NumberFormat.simpleCurrency(
    name: currency,
    decimalDigits: 2,
  ).format(value);
}

/// Seperti [formatPrice], dengan tanda `+` untuk nilai positif.
String formatSignedPrice(double value, String currency) {
  return value > 0
      ? '+${formatPrice(value, currency)}'
      : formatPrice(value, currency);
}
