import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PreferencesService {
  ThemeMode readThemeMode();

  Future<void> writeThemeMode(ThemeMode mode);

  DateTime? readLastBackupAt();

  Future<void> writeLastBackupAt(DateTime value);

  bool readAutoBackupEnabled();

  Future<void> writeAutoBackupEnabled(bool enabled);

  bool readBackupConnected();

  Future<void> writeBackupConnected(bool connected);
}

class SharedPreferencesService implements PreferencesService {
  SharedPreferencesService(this._preferences);

  static const _themeModeKey = 'theme_mode';
  static const _lastBackupAtKey = 'last_backup_at_millis';
  static const _autoBackupEnabledKey = 'auto_backup_enabled';
  static const _backupConnectedKey = 'backup_account_connected';

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

  @override
  DateTime? readLastBackupAt() {
    final millis = _preferences.getInt(_lastBackupAtKey);
    if (millis == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  Future<void> writeLastBackupAt(DateTime value) {
    return _preferences.setInt(
      _lastBackupAtKey,
      value.millisecondsSinceEpoch,
    );
  }

  @override
  bool readAutoBackupEnabled() {
    return _preferences.getBool(_autoBackupEnabledKey) ?? true;
  }

  @override
  Future<void> writeAutoBackupEnabled(bool enabled) {
    return _preferences.setBool(_autoBackupEnabledKey, enabled);
  }

  @override
  bool readBackupConnected() {
    return _preferences.getBool(_backupConnectedKey) ?? false;
  }

  @override
  Future<void> writeBackupConnected(bool connected) {
    return _preferences.setBool(_backupConnectedKey, connected);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences belum diinisialisasi.');
});

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return SharedPreferencesService(ref.watch(sharedPreferencesProvider));
});
