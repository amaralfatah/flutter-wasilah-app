import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/storage/preferences_service.dart';
import 'package:flutter_wasilah_app/features/portfolio/pages/asset_list_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/pages/dashboard_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/pages/portfolio_history_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/repository/mock_portfolio_repository.dart';
import 'package:flutter_wasilah_app/features/settings/pages/settings_page.dart';
import 'package:flutter_wasilah_app/features/target/pages/target_page.dart';

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
  });

  testWidgets('target page uses Material chips for allocation status', (
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
    expect(find.byType(Chip), findsWidgets);
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
    await tester.tap(find.text('Tentang aplikasi'));
    await tester.pumpAndSettle();

    expect(find.text('Wasilah'), findsOneWidget);
    expect(find.text('1.0.0+1'), findsOneWidget);
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

  @override
  ThemeMode readThemeMode() => _themeMode;

  @override
  Future<void> writeThemeMode(ThemeMode mode) async {
    _themeMode = mode;
  }
}
