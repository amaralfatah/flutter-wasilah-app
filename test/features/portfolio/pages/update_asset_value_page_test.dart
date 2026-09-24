import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/mock_portfolio_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/pages/update_asset_value_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';

void main() {
  testWidgets('update asset value form validates required fields', (
    tester,
  ) async {
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [portfolioRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          locale: Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: UpdateAssetValuePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    final saveLabel = find.text('Simpan', skipOffstage: false).last;
    await tester.tap(saveLabel);
    await tester.pumpAndSettle();

    expect(
      find.text('Aset wajib dipilih.', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Nilai aset wajib diisi.', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Tanggal wajib dipilih.', skipOffstage: false),
      findsNothing,
    );
  });

  testWidgets('update asset value form defaults date to today', (tester) async {
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [portfolioRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          locale: Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: UpdateAssetValuePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text(formatFullDate(DateTime.now(), const Locale('id'))),
      findsOneWidget,
    );
    expect(find.text('Pilih tanggal'), findsNothing);
  });

  testWidgets(
    'update asset value allows switching between Ubah and Tambah',
    (tester) async {
      final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            portfolioRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            locale: Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: UpdateAssetValuePage(assetId: 'btc'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Defaults to 'Ubah'
      expect(find.text('Total nilai aset'), findsOneWidget);
      expect(
        find.text('Nilai aset akan disesuaikan menjadi nominal ini.'),
        findsOneWidget,
      );

      // Switch to 'Tambah'
      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();

      expect(find.text('Penambahan nilai'), findsOneWidget);
      expect(
        find.text('Nominal ini akan ditambahkan ke nilai aset saat ini.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('update asset value calculates increment correctly on submit', (
    tester,
  ) async {
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [portfolioRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          locale: Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: UpdateAssetValuePage(assetId: 'btc'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Switch to 'Tambah'
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    // Enter 1,000,000
    final inputField = find.byType(TextFormField).first;
    await tester.enterText(inputField, '1.000.000');
    await tester.pumpAndSettle();

    // BTC original value is 18,200,000 -> Latest should be 19,200,000 in
    // preview
    expect(find.text('Tambahan nilai'), findsOneWidget);

    // Scroll to and tap 'Simpan'
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    final saveButton = find.text('Simpan', skipOffstage: false).last;
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify asset value updated: 18,200,000 + 1,000,000 = 19,200,000
    final btcAsset = await repository.getAssetById('btc');
    expect(btcAsset?.currentValue, 19200000.0);
  });
}
