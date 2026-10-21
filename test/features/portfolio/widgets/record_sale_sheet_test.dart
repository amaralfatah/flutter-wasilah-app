import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/record_sale_sheet.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_primary_button.dart';
import 'package:flutter_wasilah_app/shared/widgets/labeled_field.dart';

import '../../../helpers/mock_portfolio_repository.dart';

/// Membuka sheet lewat tombol, seperti dari halaman detail, supaya
/// `Navigator.pop` setelah simpan menutup sheet, bukan rute akar.
class _Opener extends StatelessWidget {
  const _Opener({required this.position});

  final PortfolioPosition position;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showRecordSaleSheet(context, position),
          child: const Text('open'),
        ),
      ),
    );
  }
}

Finder _field(String label) => find.descendant(
  of: find.widgetWithText(LabeledField, label),
  matching: find.byType(TextFormField),
);

void main() {
  testWidgets('sell all clears the stale error and empties the holding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
    final stored = (await tester.runAsync(
      () => repository.getPositionByAssetId('btc'),
    ))!;
    // Posisi IDR supaya tidak butuh kurs pasar.
    final position = stored.copyWith(
      holding: stored.holding.copyWith(
        currentValue: 1200000,
        quantity: 4,
        avgBuyPrice: 250000,
        totalCost: 1000000,
        priceCurrency: 'IDR',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioRepositoryProvider.overrideWithValue(repository),
          assetRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _Opener(position: position),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Angka tidak valid.'), findsNWidgets(2));

    await tester.tap(find.text('Jual semua'));
    await tester.pumpAndSettle();
    // Hanya field total diterima yang masih kosong.
    expect(find.text('Angka tidak valid.'), findsOneWidget);

    await tester.enterText(_field('Total diterima'), '1100000');
    await tester.pumpAndSettle();
    expect(find.text('Untung/rugi terealisasi'), findsOneWidget);
    expect(find.text('+100.000'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Simpan'));
    await tester.pumpAndSettle();

    final saved = (await tester.runAsync(
      () => repository.getPositionByAssetId('btc'),
    ))!;
    expect(saved.quantity, 0);
    expect(saved.currentValue, 0);
  });

  testWidgets('rejects selling more than held', (tester) async {
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
    final stored = (await tester.runAsync(
      () => repository.getPositionByAssetId('btc'),
    ))!;
    final position = stored.copyWith(
      holding: stored.holding.copyWith(quantity: 4, priceCurrency: 'IDR'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [portfolioRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _Opener(position: position),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Jumlah dijual'), '5');
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Melebihi jumlah yang dimiliki (4)'), findsOneWidget);
  });
}
