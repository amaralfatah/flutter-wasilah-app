import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/mock_portfolio_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/pages/asset_form_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';

void main() {
  testWidgets('asset form only asks for master data', (tester) async {
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioRepositoryProvider.overrideWithValue(repository),
          assetRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          locale: Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AssetFormPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Nama aset'), findsOneWidget);
    // Nilai, tanggal, dan mata uang harga beli milik portofolio, bukan
    // master aset: diisi lewat update nilai.
    expect(find.text('Tanggal pencatatan'), findsNothing);
    expect(find.text('Mata uang harga beli'), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(3));
  });
}
