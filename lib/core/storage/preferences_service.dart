import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PreferencesService {
  ThemeMode readThemeMode();

  Future<void> writeThemeMode(ThemeMode mode);
}

class SharedPreferencesService implements PreferencesService {
  SharedPreferencesService(this._preferences);

  static const _themeModeKey = 'theme_mode';

  final SharedPreferences _preferences;

  @override
  ThemeMode readThemeMode() {
    final rawValue = _preferences.getString(_themeModeKey);
    return switch (rawValue) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  Future<void> writeThemeMode(ThemeMode mode) {
    return _preferences.setString(_themeModeKey, mode.name);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences belum diinisialisasi.');
});

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return SharedPreferencesService(ref.watch(sharedPreferencesProvider));
});
