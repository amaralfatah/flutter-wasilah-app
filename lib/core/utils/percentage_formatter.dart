/// Format persentase alokasi, selalu dua desimal.
String formatPercentage(double value) {
  final text = value.toStringAsFixed(2).replaceAll('.', ',');
  return '$text%';
}

/// Sama seperti [formatPercentage], dengan tanda `+`/`-` eksplisit.
String formatSignedPercentage(double value) {
  if (value == 0) {
    return '0%';
  }

  final prefix = value > 0 ? '+' : '-';
  return '$prefix${formatPercentage(value.abs())}';
}

/// Persen perubahan harga pasar, selalu dua desimal dengan tanda eksplisit
/// seperti Stockbit (`-2,86%`, `+45,45%`). Beda dengan alokasi: pergerakan
/// harian saham sering di bawah 1%, jadi pembulatan menyesatkan.
String formatSignedChangePercentage(double value) {
  final text = value.abs().toStringAsFixed(2).replaceAll('.', ',');
  if (text == '0,00') {
    return '0,00%';
  }
  return '${value > 0 ? '+' : '-'}$text%';
}
