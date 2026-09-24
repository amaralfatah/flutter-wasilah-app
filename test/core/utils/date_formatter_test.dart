import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';

void main() {
  const idLocale = Locale('id');

  group('formatFullDateTime', () {
    test('formats date with zero-padded hour and minute', () {
      expect(
        formatFullDateTime(DateTime(2026, 7, 18, 9, 5), idLocale),
        '18 Juli 2026, 09.05',
      );
    });

    test('formats afternoon time in 24-hour clock', () {
      expect(
        formatFullDateTime(DateTime(2026, 12, 1, 21, 30), idLocale),
        '1 Desember 2026, 21.30',
      );
    });
  });
}
