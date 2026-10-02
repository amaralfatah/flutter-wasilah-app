import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/pages/portfolio_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';

import '../../../helpers/mock_portfolio_repository.dart';

Future<void> _pumpPage(WidgetTester tester, MarketValueRecords records) {
  final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        portfolioRepositoryProvider.overrideWithValue(repository),
        assetRepositoryProvider.overrideWithValue(repository),
        marketValueRecordsProvider.overrideWithValue(records),
      ],
      child: const MaterialApp(
        locale: Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PortfolioPage(),
      ),
    ),
  );
}

void main() {
  testWidgets('record dialog says how many stale holdings are excluded', (
    tester,
  ) async {
    await _pumpPage(tester, (
      records: const [
        (assetId: 'btc', totalValue: 1000, fxCurrency: null, fxRate: null),
      ],
      staleCount: 2,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Catat nilai pasar'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        '2 aset belum punya harga terkini (offline atau gagal dimuat)',
      ),
      findsOneWidget,
    );
  });

  testWidgets('record action is hidden when every price is stale', (
    tester,
  ) async {
    await _pumpPage(tester, (records: const [], staleCount: 3));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Catat nilai pasar'), findsNothing);
  });
}
