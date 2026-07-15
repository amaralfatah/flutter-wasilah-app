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
