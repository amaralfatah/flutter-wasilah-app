import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/features/market/providers/market_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/pages/update_asset_value_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_primary_button.dart';

import '../../../helpers/mock_portfolio_repository.dart';

/// Perbesar viewport supaya seluruh form (kini punya field jumlah unit &
/// harga avg) muat tanpa scroll -- ListView-nya lazy, jadi widget di luar
/// viewport tidak dibangun dan tak bisa di-tap.
void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _pumpPage(
  WidgetTester tester,
  MockPortfolioRepository repository, {
  String? assetId,
  bool marketRateAvailable = true,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        portfolioRepositoryProvider.overrideWithValue(repository),
        assetRepositoryProvider.overrideWithValue(repository),
        fxRateToIdrProvider.overrideWith(
          (ref, currency) => marketRateAvailable
              ? 16000
              : throw Exception('offline'),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: UpdateAssetValuePage(assetId: assetId),
      ),
    ),
  );
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

const _spy = Asset(
  id: 'spy',
  name: 'S&P 500',
  code: 'SPY',
  category: AssetCategory.stock,
);

Future<void> _switchValueToUsd(WidgetTester tester) async {
  await tester.tap(
    find.descendant(of: _field('Total nilai aset'), matching: find.text('IDR')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('USD').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('update asset value form validates required fields', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);

    await _pumpPage(tester, repository);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();

    expect(find.text('Aset wajib dipilih.'), findsOneWidget);
    expect(
      find.text(
        'Isi minimal salah satu: jumlah unit, harga beli, modal, atau nilai.',
      ),
      findsOneWidget,
    );
    expect(find.text('Tanggal wajib dipilih.'), findsNothing);
  });

  testWidgets('update asset value form defaults date to today', (tester) async {
    _useTallView(tester);
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);

    await _pumpPage(tester, repository);
    await tester.pumpAndSettle();

    expect(
      find.text(formatFullDate(DateTime.now(), const Locale('id'))),
      findsOneWidget,
    );
    expect(find.text('Pilih tanggal'), findsNothing);
  });

  testWidgets('cash can switch between Ubah and Tambah', (tester) async {
    _useTallView(tester);
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);

    await _pumpPage(tester, repository, assetId: 'cash');
    await tester.pumpAndSettle();

    expect(find.text('Total nilai aset'), findsOneWidget);
    // Kas cukup satu input.
    expect(find.text('Total modal'), findsNothing);
    expect(find.text('Jumlah unit'), findsNothing);

    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    expect(find.text('Penambahan nilai'), findsOneWidget);
  });

  testWidgets('non-cash asset has no Tambah option', (tester) async {
    _useTallView(tester);
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);

    await _pumpPage(tester, repository, assetId: 'btc');
    await tester.pumpAndSettle();

    expect(find.text('Tambah'), findsNothing);
    expect(find.text('Jumlah unit'), findsOneWidget);
  });

  testWidgets('cash increment is added to the current value', (tester) async {
    _useTallView(tester);
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);

    await _pumpPage(tester, repository, assetId: 'cash');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Penambahan nilai'), '1.000.000');
    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();

    final position = await tester.runAsync(
      () => repository.getPositionByAssetId('cash'),
    );
    expect(position?.currentValue, 7600000);
    // Modal kas mengikuti nilainya.
    expect(position?.totalCost, 7600000);
  });

  testWidgets('cash in USD keeps its currency', (tester) async {
    _useTallView(tester);
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);

    await _pumpPage(tester, repository, assetId: 'cash');
    await tester.pumpAndSettle();

    final valueField = _field('Total nilai aset');
    await tester.tap(
      find.descendant(of: valueField, matching: find.text('IDR')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD').last);
    await tester.pumpAndSettle();
    await tester.enterText(valueField, '20');
    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();

    final position = await tester.runAsync(
      () => repository.getPositionByAssetId('cash'),
    );
    expect(position?.currentValue, 320000);
    expect(position?.priceCurrency, 'USD');
  });

  testWidgets('first update of an asset outside the portfolio adds it', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
    // Mock memakai Future.delayed; di zona FakeAsync harus lewat runAsync.
    await tester.runAsync(
      () => repository.createAsset(
        const Asset(
          id: 'gold',
          name: 'Emas',
          code: 'XAU',
          category: AssetCategory.preciousMetal,
        ),
      ),
    );

    await _pumpPage(tester, repository, assetId: 'gold');
    await tester.pumpAndSettle();

    await tester.enterText(_field('Total nilai aset'), '5.000.000');
    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();

    final position = await tester.runAsync(
      () => repository.getPositionByAssetId('gold'),
    );
    expect(position?.currentValue, 5000000);
    expect(position?.priceCurrency, 'IDR');
  });

  testWidgets('value filled in USD is stored in IDR', (tester) async {
    _useTallView(tester);
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
    await tester.runAsync(
      () => repository.createAsset(
        const Asset(
          id: 'spy',
          name: 'S&P 500',
          code: 'SPY',
          category: AssetCategory.stock,
        ),
      ),
    );

    await _pumpPage(tester, repository, assetId: 'spy');
    await tester.pumpAndSettle();

    final valueField = _field('Total nilai aset');
    await tester.tap(
      find.descendant(of: valueField, matching: find.text('IDR')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD').last);
    await tester.pumpAndSettle();

    await tester.enterText(valueField, '100.5');
    await tester.pumpAndSettle();
    expect(find.textContaining('≈ Rp1.608.000'), findsOneWidget);

    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();

    final position = await tester.runAsync(
      () => repository.getPositionByAssetId('spy'),
    );
    expect(position?.currentValue, 1608000);
  });

  testWidgets('manual USD rate overrides the market rate and is stored', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
    await tester.runAsync(() => repository.createAsset(_spy));

    await _pumpPage(tester, repository, assetId: 'spy');
    await tester.pumpAndSettle();
    await _switchValueToUsd(tester);

    expect(find.text('Otomatis: Rp16.000'), findsOneWidget);
    await tester.enterText(_field('Total nilai aset'), '100');
    await tester.enterText(_field('Kurs 1 USD (Rp)'), '16500');
    await tester.pumpAndSettle();
    expect(find.textContaining('≈ Rp1.650.000'), findsOneWidget);

    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();

    final history = await tester.runAsync(
      () => repository.getAssetHistory('spy'),
    );
    expect(history!.first.totalValue, 1650000);
    expect(history.first.fxCurrency, 'USD');
    expect(history.first.fxRate, 16500);
  });

  testWidgets('manual USD rate unblocks saving when market rate is down', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
    await tester.runAsync(() => repository.createAsset(_spy));

    await _pumpPage(
      tester,
      repository,
      assetId: 'spy',
      marketRateAvailable: false,
    );
    await tester.pumpAndSettle();
    await _switchValueToUsd(tester);

    expect(
      find.text('Kurs pasar tidak tersedia. Isi kurs secara manual.'),
      findsOneWidget,
    );
    await tester.enterText(_field('Total nilai aset'), '10');
    await tester.enterText(_field('Kurs 1 USD (Rp)'), '15000');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();

    final position = await tester.runAsync(
      () => repository.getPositionByAssetId('spy'),
    );
    expect(position?.currentValue, 150000);
  });

  testWidgets('quantity and avg price alone derive cost and value', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
    await tester.runAsync(
      () => repository.createAsset(
        const Asset(
          id: 'spy',
          name: 'S&P 500',
          code: 'SPY',
          category: AssetCategory.stock,
        ),
      ),
    );

    await _pumpPage(tester, repository, assetId: 'spy');
    await tester.pumpAndSettle();

    final avgField = _field('Harga rata-rata beli');
    await tester.tap(find.descendant(of: avgField, matching: find.text('IDR')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD').last);
    await tester.pumpAndSettle();

    await tester.enterText(_field('Jumlah unit'), '2');
    await tester.enterText(avgField, '500');
    await tester.pumpAndSettle();
    // 2 × $500 × 16.000
    expect(find.text('Otomatis: Rp16.000.000'), findsNWidgets(2));

    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();

    final position = await tester.runAsync(
      () => repository.getPositionByAssetId('spy'),
    );
    expect(position?.totalCost, 16000000);
    // Tanpa simbol pasar, nilai mengikuti modal.
    expect(position?.currentValue, 16000000);
    expect(position?.avgBuyPrice, 500);
    expect(position?.priceCurrency, 'USD');
  });
}
