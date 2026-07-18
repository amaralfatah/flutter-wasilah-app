import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/storage/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesService backup preferences', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to no last backup time and auto backup enabled', () async {
      final preferences = SharedPreferencesService(
        await SharedPreferences.getInstance(),
      );

      expect(preferences.readLastBackupAt(), isNull);
      expect(preferences.readAutoBackupEnabled(), isTrue);
    });

    test('persists last backup time and auto backup toggle', () async {
      final preferences = SharedPreferencesService(
        await SharedPreferences.getInstance(),
      );
      final backupTime = DateTime(2026, 7, 18, 9, 30);

      await preferences.writeLastBackupAt(backupTime);
      await preferences.writeAutoBackupEnabled(false);

      expect(preferences.readLastBackupAt(), backupTime);
      expect(preferences.readAutoBackupEnabled(), isFalse);
    });
  });
}
