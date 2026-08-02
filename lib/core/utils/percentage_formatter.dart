/// Format persentase alokasi.
///
/// Nilai di bawah 10% ditampilkan dengan satu desimal supaya aset kecil tidak
/// terbaca sebagai `0%`; di atas itu desimalnya hanya menambah keramaian.
String formatPercentage(double value) {
  final text = value.abs() >= 10
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '${text.replaceAll('.', ',')}%';
}

/// Sama seperti [formatPercentage], dengan tanda `+`/`-` eksplisit.
String formatSignedPercentage(double value) {
  if (value == 0) {
    return '0%';
  }

  final prefix = value > 0 ? '+' : '-';
  return '$prefix${formatPercentage(value.abs())}';
}
