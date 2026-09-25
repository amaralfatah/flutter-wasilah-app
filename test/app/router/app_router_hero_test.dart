import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/router/app_router.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/mock_portfolio_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';

void main() {
  testWidgets('navigating to asset detail does not throw hero tag conflicts', (
    tester,
  ) async {
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
    final container = ProviderContainer(
      overrides: [
        portfolioRepositoryProvider.overrideWithValue(repository),
        assetRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Portofolio'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('BTC'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Bitcoin'), findsOneWidget);
    // Detail holding tidak menyediakan edit master aset.
    expect(find.byTooltip('Edit aset'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'master assets have their own page, separate from portfolio',
    (
      tester,
    ) async {
      final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
      final container = ProviderContainer(
        overrides: [
          portfolioRepositoryProvider.overrideWithValue(repository),
          assetRepositoryProvider.overrideWithValue(repository),
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

      unawaited(
        container.read(appRouterProvider).push(RouteNames.masterAssets),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Master aset'), findsOneWidget);
      expect(find.text('Bitcoin'), findsOneWidget);

      await tester.tap(find.text('Bitcoin'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Edit aset'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
