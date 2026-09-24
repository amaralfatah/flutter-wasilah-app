import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/storage/preferences_service.dart';

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    return ref.watch(preferencesServiceProvider).readLocale();
  }

  Future<void> updateLocale(Locale? locale) async {
    state = locale;
    await ref.read(preferencesServiceProvider).writeLocale(locale);
  }
}
