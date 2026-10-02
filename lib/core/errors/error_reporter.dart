import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mencatat error non-fatal yang ditangani app (mis. auto-backup gagal).
///
/// Saat ini hanya ke log konsol — di build release terbaca lewat
/// `adb logcat`. Titik tunggal ini yang diganti bila nanti memakai layanan
/// crash reporting.
class ErrorReporter {
  const ErrorReporter();

  void report(Object error, StackTrace stackTrace, {required String reason}) {
    debugPrint('$reason: $error\n$stackTrace');
  }
}

final errorReporterProvider = Provider<ErrorReporter>(
  (ref) => const ErrorReporter(),
);
