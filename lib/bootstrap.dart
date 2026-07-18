import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/app.dart';
import 'package:flutter_wasilah_app/core/storage/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();
  var isFirebaseReady = false;

  try {
    await Firebase.initializeApp();
    isFirebaseReady = true;
  } catch (error) {
    if (kDebugMode) {
      debugPrint('Firebase initialization skipped: $error');
    }
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);

    if (isFirebaseReady) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      return;
    }

    if (kDebugMode) {
      debugPrint(details.exceptionAsString());
    }
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    if (isFirebaseReady) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: true,
      );
    } else if (kDebugMode) {
      debugPrint('Unhandled zone error: $error');
    }

    return true;
  };

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const App(),
    ),
  );
}
