import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/storage/preferences_service.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/mock_portfolio_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/pages/asset_list_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/pages/dashboard_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/pages/portfolio_history_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter_wasilah_app/features/target/presentation/pages/target_form_page.dart';
import 'package:flutter_wasilah_app/features/target/presentation/pages/target_page.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_primary_button.dart';

void main() {
  testWidgets('dashboard uses pull-to-refresh for top-level content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        child: const DashboardPage(),
        repository: MockPortfolioRepository(simulatedDelay: Duration.zero),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('history uses pull-to-refresh for top-level content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        child: const PortfolioHistoryPage(),
        repository: MockPortfolioRepository(simulatedDelay: Duration.zero),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('asset list uses pull-to-refresh for top-level content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        child: const AssetListPage(),
        repository: MockPortfolioRepository(simulatedDelay: Duration.zero),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(_scrollPadding(tester).bottom, greaterThan(AppSpacing.xl));
  });

  testWidgets('target page shows allocation progress indicators', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        child: const TargetPage(),
        repository: MockPortfolioRepository(simulatedDelay: Duration.zero),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsWidgets);
    expect(_scrollPadding(tester).bottom, greaterThan(AppSpacing.xl));
  });

  testWidgets('target form follows the same Material pattern as asset form', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        child: const TargetFormPage(targetId: 'target-crypto'),
        repository: MockPortfolioRepository(simulatedDelay: Duration.zero),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AppPrimaryButton), findsOneWidget);
    expect(find.text('Simpan perubahan'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Hapus target'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<AssetCategory>));
    await tester.pumpAndSettle();

    expect(find.text('Logam Mulia'), findsOneWidget);
    expect(find.text('Indeks / ETF'), findsOneWidget);
  });

  testWidgets('settings uses the standard Material about dialog flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        child: const SettingsPage(),
        repository: MockPortfolioRepository(simulatedDelay: Duration.zero),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Tentang aplikasi'), findsOneWidget);
    await tester.tap(find.text('Tentang aplikasi'));
    await tester.pumpAndSettle();

    expect(find.text('Wasilah'), findsOneWidget);
    expect(find.text('1.0.0+1'), findsWidgets);
  });
}

Widget _buildApp({
  required Widget child,
  required MockPortfolioRepository repository,
}) {
  return ProviderScope(
    overrides: [
      portfolioRepositoryProvider.overrideWithValue(repository),
      preferencesServiceProvider.overrideWithValue(_FakePreferencesService()),
    ],
    child: MaterialApp(home: child),
  );
}

class _FakePreferencesService implements PreferencesService {
  ThemeMode _themeMode = ThemeMode.system;
  DateTime? _lastBackupAt;
  bool _autoBackupEnabled = true;
  bool _backupConnected = false;

  @override
  ThemeMode readThemeMode() => _themeMode;

  @override
  Future<void> writeThemeMode(ThemeMode mode) async {
    _themeMode = mode;
  }

  @override
  DateTime? readLastBackupAt() => _lastBackupAt;

  @override
  Future<void> writeLastBackupAt(DateTime value) async {
    _lastBackupAt = value;
  }

  @override
  bool readAutoBackupEnabled() => _autoBackupEnabled;

  @override
  Future<void> writeAutoBackupEnabled(bool enabled) async {
    _autoBackupEnabled = enabled;
  }

  @override
  bool readBackupConnected() => _backupConnected;

  @override
  Future<void> writeBackupConnected(bool connected) async {
    _backupConnected = connected;
  }
}

EdgeInsets _scrollPadding(WidgetTester tester) {
  final scrollView = tester.widget<SingleChildScrollView>(
    find.byType(SingleChildScrollView),
  );

  return scrollView.padding! as EdgeInsets;
}
