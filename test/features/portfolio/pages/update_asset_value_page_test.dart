import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/features/market/data/models/market_quote.dart';
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
          (ref, currency) =>
              marketRateAvailable ? 16000 : throw Exception('offline'),
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

  testWidgets('market asset leaves value empty and saves the market value', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = await _marketHolding(tester);

    await _pumpMarketPage(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('Total nilai aset (opsional)'), findsOneWidget);
    // 10 lot × 100 lembar × Rp9.000
    expect(
      find.text('Kosongkan untuk pakai harga pasar: Rp9.000.000'),
      findsOneWidget,
    );

    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();

    final position = await tester.runAsync(
      () => repository.getPositionByAssetId('bbca'),
    );
    expect(position?.currentValue, 9000000);
    expect(position?.totalCost, 800000);
  });

  testWidgets('market asset needs a manual value for another month', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = await _marketHolding(tester);

    await _pumpMarketPage(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bulan sebelumnya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').last);
    await tester.tap(find.text('OKE'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Harga pasar hanya untuk bulan ini; isi nilai bulan yang dipilih.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Isi total nilai untuk bulan yang dipilih.'),
      findsOneWidget,
    );
    final position = await tester.runAsync(
      () => repository.getPositionByAssetId('bbca'),
    );
    expect(position?.currentValue, 1000000);
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

  testWidgets('emptying a prefilled avg price clears it, quantity is kept', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
    await tester.runAsync(() async {
      await repository.createAsset(_spy);
      await repository.updateAssetValue(
        assetId: 'spy',
        totalValue: 1000000,
        recordedAt: DateTime(2020),
        totalCost: 800000,
        quantity: 2,
        avgBuyPrice: 400000,
      );
    });

    await _pumpPage(tester, repository, assetId: 'spy');
    await tester.pumpAndSettle();

    await tester.enterText(_field('Harga rata-rata beli'), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();

    final position = await tester.runAsync(
      () => repository.getPositionByAssetId('spy'),
    );
    expect(position?.avgBuyPrice, isNull);
    expect(position?.quantity, 2);
  });

  testWidgets('a field that was never filled does not clear anything', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
    await tester.runAsync(() async {
      await repository.createAsset(_spy);
      await repository.updateAssetValue(
        assetId: 'spy',
        totalValue: 1000000,
        recordedAt: DateTime(2020),
        totalCost: 800000,
        quantity: 2,
      );
    });

    await _pumpPage(tester, repository, assetId: 'spy');
    await tester.pumpAndSettle();

    // Harga beli memang kosong sejak awal; mengetik lalu menghapus tidak
    // mengosongkan jumlah unit.
    await tester.enterText(_field('Harga rata-rata beli'), '1');
    await tester.enterText(_field('Harga rata-rata beli'), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();

    final position = await tester.runAsync(
      () => repository.getPositionByAssetId('spy'),
    );
    expect(position?.quantity, 2);
    expect(position?.avgBuyPrice, isNull);
  });

  testWidgets('autofill button shows dollar and rupiah for USD cost', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
    await tester.runAsync(() => repository.createAsset(_spy));

    await _pumpPage(tester, repository, assetId: 'spy');
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: _field('Total modal'), matching: find.text('IDR')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD').last);
    await tester.pumpAndSettle();

    await tester.enterText(_field('Total modal'), '2');
    await tester.enterText(_field('Jumlah unit'), '2');
    await tester.enterText(_field('Harga rata-rata beli'), '8.000');
    await tester.pumpAndSettle();

    // 2 × Rp8.000 = Rp16.000 = $1 pada kurs 16.000.
    expect(find.text(r'$1.00 · Rp16.000'), findsOneWidget);
    expect(
      find.byTooltip(r'Isi otomatis: $1.00 · Rp16.000'),
      findsOneWidget,
    );
  });

  testWidgets('autofill button stays hidden while the field is empty', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
    await tester.runAsync(() => repository.createAsset(_spy));

    await _pumpPage(tester, repository, assetId: 'spy');
    await tester.pumpAndSettle();
    await tester.enterText(_field('Jumlah unit'), '3');
    await tester.enterText(_field('Harga rata-rata beli'), '1000');
    await tester.pumpAndSettle();

    // Helper "Otomatis" sudah menampilkan nilai yang dipakai.
    expect(find.byIcon(Icons.auto_fix_high), findsNothing);
    expect(find.text('Otomatis: Rp3.000'), findsNWidgets(2));
  });

  testWidgets(
    'autofill buttons fill cost and value after quantity or price changes',
    (tester) async {
      _useTallView(tester);
      final repository = MockPortfolioRepository(
        simulatedDelay: Duration.zero,
      );
      await tester.runAsync(() => repository.createAsset(_spy));

      await _pumpPage(tester, repository, assetId: 'spy');
      await tester.pumpAndSettle();

      await tester.enterText(_field('Total modal'), '1.000');
      await tester.enterText(_field('Total nilai aset'), '1.000');
      expect(find.byIcon(Icons.auto_fix_high), findsNothing);

      await tester.enterText(_field('Jumlah unit'), '3');
      await tester.enterText(_field('Harga rata-rata beli'), '1000');
      await tester.pumpAndSettle();

      // Modal: unit × harga beli. Nilai tanpa harga pasar mengikuti modal,
      // yang saat ini masih 1.000 sehingga sama dan tak ditawarkan.
      await tester.tap(find.byTooltip('Isi otomatis: Rp3.000'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: _field('Total modal'),
          matching: find.text('3.000'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Isi otomatis: Rp3.000'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: _field('Total nilai aset'),
          matching: find.text('3.000'),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.auto_fix_high), findsNothing);

      // Modal tetap bisa ditimpa manual, mis. untuk fee; nilai ditawarkan
      // lagi tanpa langsung berubah.
      await tester.enterText(_field('Total modal'), '3.100');
      await tester.pumpAndSettle();
      expect(find.byTooltip('Isi otomatis: Rp3.100'), findsOneWidget);
      await tester.tap(find.byType(AppPrimaryButton));
      await tester.pumpAndSettle();

      final position = await tester.runAsync(
        () => repository.getPositionByAssetId('spy'),
      );
      expect(position?.totalCost, 3100);
      expect(position?.currentValue, 3000);
    },
  );

  testWidgets('backdated cash increment adds to the value of that month', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
    final now = DateTime.now();
    // Saldo bulan ini berbeda dari saldo bulan lalu (6.600.000, histori
    // mock), supaya ketahuan nilai mana yang dijadikan dasar.
    await tester.runAsync(
      () => repository.updateAssetValue(
        assetId: 'cash',
        totalValue: 9000000,
        recordedAt: DateTime(now.year, now.month, now.day),
      ),
    );

    await _pumpPage(tester, repository, assetId: 'cash');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bulan sebelumnya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').last);
    await tester.tap(find.text('OKE'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Penambahan nilai'), '1.000.000');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();

    final previousMonth = DateTime(now.year, now.month - 1);
    final history = await tester.runAsync(
      () => repository.getAssetHistory('cash'),
    );
    final snapshot = history!.firstWhere(
      (item) =>
          item.recordedAt.year == previousMonth.year &&
          item.recordedAt.month == previousMonth.month,
    );
    expect(snapshot.totalValue, 7600000);
  });

  testWidgets('date picker does not allow future dates', (tester) async {
    _useTallView(tester);
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);

    await _pumpPage(tester, repository, assetId: 'cash');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final dialog = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    expect(dialog.lastDate, DateTime(now.year, now.month, now.day));
  });

  testWidgets('validation messages follow the app language', (tester) async {
    _useTallView(tester);
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioRepositoryProvider.overrideWithValue(repository),
          assetRepositoryProvider.overrideWithValue(repository),
          fxRateToIdrProvider.overrideWith((ref, currency) => 16000),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: UpdateAssetValuePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();

    expect(find.text('Please select an asset.'), findsOneWidget);
    expect(find.text('Aset wajib dipilih.'), findsNothing);
  });
}

Future<MockPortfolioRepository> _marketHolding(WidgetTester tester) async {
  final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
  await tester.runAsync(() async {
    await repository.createAsset(
      const Asset(
        id: 'bbca',
        name: 'Bank BCA',
        code: 'BBCA',
        category: AssetCategory.stock,
        marketSymbol: 'BBCA.JK',
      ),
    );
    await repository.updateAssetValue(
      assetId: 'bbca',
      totalValue: 1000000,
      recordedAt: DateTime(2020),
      totalCost: 800000,
      quantity: 10,
    );
  });
  return repository;
}

Future<void> _pumpMarketPage(
  WidgetTester tester,
  MockPortfolioRepository repository,
) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        portfolioRepositoryProvider.overrideWithValue(repository),
        assetRepositoryProvider.overrideWithValue(repository),
        fxRateToIdrProvider.overrideWith(
          (ref, currency) => currency == 'IDR' ? 1 : 16000,
        ),
        marketQuoteProvider.overrideWith(
          (ref, symbol) => (
            quote: MarketQuote(
              symbol: symbol,
              currency: 'IDR',
              price: 9000,
              marketTime: DateTime.now(),
              fetchedAt: DateTime.now(),
            ),
            oneDaySeries: null,
            isStale: false,
          ),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: UpdateAssetValuePage(assetId: 'bbca'),
      ),
    ),
  );
}
