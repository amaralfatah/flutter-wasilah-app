import 'package:flutter/widgets.dart';

const _monthNamesId = <String>[
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

const _monthNamesEn = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

List<String> _monthNamesFor(Locale locale) {
  return locale.languageCode == 'en' ? _monthNamesEn : _monthNamesId;
}

String formatFullDate(DateTime date, Locale locale) {
  final monthNames = _monthNamesFor(locale);
  return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
}

/// Sama seperti [formatFullDate] tapi nama bulan disingkat 3 huruf,
/// untuk baris sempit seperti item daftar aset.
String formatShortDate(DateTime date, Locale locale) {
  final monthNames = _monthNamesFor(locale);
  return '${date.day} ${monthNames[date.month - 1].substring(0, 3)} '
      '${date.year}';
}

/// Tanggal ringkas tanpa tahun untuk kolom sempit, misalnya `24 Sep`.
String formatDayMonth(DateTime date, Locale locale) {
  final monthNames = _monthNamesFor(locale);
  return '${date.day} ${monthNames[date.month - 1].substring(0, 3)}';
}

String formatMonthYear(DateTime date, Locale locale) {
  final monthNames = _monthNamesFor(locale);
  return '${monthNames[date.month - 1]} ${date.year}';
}

/// Nama bulan saja, misalnya `September`, untuk baris histori yang tahunnya
/// ditampilkan terpisah di bawahnya.
String formatMonthName(DateTime date, Locale locale) =>
    _monthNamesFor(locale)[date.month - 1];

String formatFullDateTime(DateTime date, Locale locale) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${formatFullDate(date, locale)}, $hour.$minute';
}
