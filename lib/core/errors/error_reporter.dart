import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mencatat error non-fatal yang ditangani app (mis. auto-backup gagal)
/// supaya tetap terlihat di Crashlytics walau tidak memunculkan crash.
class ErrorReporter {
  const ErrorReporter();

  void report(Object error, StackTrace stackTrace, {required String reason}) {
    if (kDebugMode) {
      debugPrint('$reason: $error');
    }
    // Firebase bisa gagal diinisialisasi (lihat bootstrap); tanpa itu
    // Crashlytics melempar error saat dipanggil.
    if (Firebase.apps.isEmpty) {
      return;
    }
    FirebaseCrashlytics.instance
        .recordError(error, stackTrace, reason: reason)
        .ignore();
  }
}

final errorReporterProvider = Provider<ErrorReporter>(
  (ref) => const ErrorReporter(),
);
