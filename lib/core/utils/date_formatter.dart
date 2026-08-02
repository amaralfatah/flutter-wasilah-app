const _monthNames = <String>[
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

String formatFullDate(DateTime date) {
  return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
}

/// Sama seperti [formatFullDate] tapi nama bulan disingkat 3 huruf,
/// untuk baris sempit seperti item daftar aset.
String formatShortDate(DateTime date) {
  return '${date.day} ${_monthNames[date.month - 1].substring(0, 3)} '
      '${date.year}';
}

String formatMonthYear(DateTime date) {
  return '${_monthNames[date.month - 1]} ${date.year}';
}

String formatFullDateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${formatFullDate(date)}, $hour.$minute';
}
