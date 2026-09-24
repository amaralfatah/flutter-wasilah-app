import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/router/app_router.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/mock_portfolio_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';

void main() {
  testWidgets('window sempit memakai navigation bar di bawah', (tester) async {
    await _pumpShell(tester, width: 400);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('mulai 600dp navigasi pindah ke rail samping', (tester) async {
    await _pumpShell(tester, width: 800);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('rail tetap bisa berpindah tab', (tester) async {
    await _pumpShell(tester, width: 800);

    await tester.tap(find.text('Target'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Target'), findsOneWidget);
  });
}

Future<void> _pumpShell(WidgetTester tester, {required double width}) async {
  tester.view.physicalSize = Size(width, 900) * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);

  final container = ProviderContainer(
    overrides: [
      portfolioRepositoryProvider.overrideWithValue(
        MockPortfolioRepository(simulatedDelay: Duration.zero),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: container.read(appRouterProvider),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
