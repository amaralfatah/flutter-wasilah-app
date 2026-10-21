import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/core/utils/validators.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/asset_management_controller.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/update_asset_value_controller.dart';

import '../../../helpers/mock_portfolio_repository.dart';

void main() {
  late MockPortfolioRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
    container = ProviderContainer(
      overrides: [
        portfolioRepositoryProvider.overrideWithValue(repository),
        assetRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('UpdateAssetValueController', () {
    UpdateAssetValueController controller() =>
        container.read(updateAssetValueControllerProvider.notifier);

    test('saves the value with a trimmed note', () async {
      await controller().submit(
        assetId: 'btc',
        totalValue: 20000000,
        recordedAt: DateTime(2026, 8),
        note: '  Update Agustus  ',
      );

      final history = await repository.getAssetHistory('btc');
      expect(history.first.totalValue, 20000000);
      expect(history.first.note, 'Update Agustus');
      expect(
        container.read(updateAssetValueControllerProvider),
        isA<AsyncData<void>>(),
      );
    });

    test('stores a blank note as null', () async {
      await controller().submit(
        assetId: 'btc',
        totalValue: 1,
        recordedAt: DateTime(2026, 8),
        note: '   ',
      );

      expect((await repository.getAssetHistory('btc')).first.note, isNull);
    });

    test('rejects negative value and cost before touching the repo', () {
      expect(
        () => controller().submit(
          assetId: 'btc',
          totalValue: -1,
          recordedAt: DateTime(2026, 8),
        ),
        throwsA(isA<InvalidCurrentValueException>()),
      );
      expect(
        () => controller().submit(
          assetId: 'btc',
          totalValue: 1,
          totalCost: -1,
          recordedAt: DateTime(2026, 8),
        ),
        throwsA(isA<InvalidTotalCostException>()),
      );
    });

    test('records a purchase and keeps the month note', () async {
      final position = (await repository.getPositionByAssetId('btc'))!;

      await controller().recordPurchase(
        position: position.copyWith(
          holding: position.holding.copyWith(
            quantity: 0.00038,
            avgBuyPrice: 78144,
            totalCost: 0.00038 * 78144 * 16000,
            priceCurrency: 'USD',
          ),
        ),
        boughtQuantity: 0.00023,
        paid: 19.228,
        rateToIdr: 16000,
        recordedAt: DateTime(2026, 7, 20),
      );

      final saved = (await repository.getPositionByAssetId('btc'))!;
      expect(saved.quantity, closeTo(0.00061, 1e-12));
      expect(
        saved.avgBuyPrice,
        closeTo((0.00038 * 78144 + 19.228) / 0.00061, 1e-6),
      );
      expect(saved.priceCurrency, 'USD');
      expect(saved.currentValue, closeTo(18200000 + 19.228 * 16000, 1e-6));
      final history = await repository.getAssetHistory('btc');
      expect(history.first.note, 'Rekap nilai Juli');
      expect(history.first.fxRate, 16000);
    });

    test('scales a market-valued position to the new quantity', () async {
      final position = (await repository.getPositionByAssetId('btc'))!;

      await controller().recordPurchase(
        position: position.copyWith(
          marketPriceAt: DateTime(2026, 7, 20),
          holding: position.holding.copyWith(
            currentValue: 600000,
            quantity: 0.0004,
            avgBuyPrice: 78000,
            priceCurrency: 'USD',
          ),
        ),
        boughtQuantity: 0.0002,
        paid: 16,
        rateToIdr: 16000,
        recordedAt: DateTime(2026, 7, 20),
      );

      final saved = (await repository.getPositionByAssetId('btc'))!;
      expect(saved.currentValue, closeTo(900000, 1e-6));
    });

    test('records a partial sale and keeps the average price', () async {
      final position = (await repository.getPositionByAssetId('btc'))!;

      await controller().recordSale(
        position: position.copyWith(
          holding: position.holding.copyWith(
            currentValue: 1200000,
            quantity: 0.0008,
            avgBuyPrice: 78125,
            totalCost: 1000000,
            priceCurrency: 'USD',
          ),
        ),
        soldQuantity: 0.0002,
        received: 20,
        rateToIdr: 16000,
        recordedAt: DateTime(2026, 7, 20),
      );

      final saved = (await repository.getPositionByAssetId('btc'))!;
      expect(saved.quantity, closeTo(0.0006, 1e-12));
      expect(saved.avgBuyPrice, closeTo(78125, 1e-9));
      expect(saved.totalCost, closeTo(750000, 1));
      expect(saved.currentValue, closeTo(900000, 1));
      final history = await repository.getAssetHistory('btc');
      expect(history.first.note, 'Rekap nilai Juli');
    });

    test('selling everything leaves a zero-value holding', () async {
      final position = (await repository.getPositionByAssetId('btc'))!;

      await controller().recordSale(
        position: position.copyWith(
          holding: position.holding.copyWith(
            currentValue: 1200000,
            quantity: 0.0008,
            avgBuyPrice: 78125,
            totalCost: 1000000,
            priceCurrency: 'USD',
          ),
        ),
        soldQuantity: 0.0008,
        received: 75,
        rateToIdr: 16000,
        recordedAt: DateTime(2026, 7, 20),
      );

      final saved = (await repository.getPositionByAssetId('btc'))!;
      expect(saved.quantity, 0);
      expect(saved.currentValue, 0);
    });

    test('rejects selling more than held', () async {
      final position = (await repository.getPositionByAssetId('btc'))!;

      expect(
        () => controller().recordSale(
          position: position.copyWith(
            holding: position.holding.copyWith(quantity: 0.0001),
          ),
          soldQuantity: 1,
          received: 10,
          rateToIdr: 16000,
          recordedAt: DateTime(2026, 7, 20),
        ),
        throwsA(isA<InvalidSaleException>()),
      );
    });

    test('rejects a purchase that cannot be averaged', () async {
      final position = (await repository.getPositionByAssetId('btc'))!;

      expect(
        () => controller().recordPurchase(
          position: position.copyWith(
            holding: position.holding.copyWith(totalCost: 1000000),
          ),
          boughtQuantity: 1,
          paid: 10,
          rateToIdr: 1,
          recordedAt: DateTime(2026, 7, 20),
        ),
        throwsA(isA<InvalidPurchaseException>()),
      );
    });

    test('exposes repository failures as AsyncError', () async {
      await expectLater(
        controller().submit(
          assetId: 'missing',
          totalValue: 1,
          recordedAt: DateTime(2026, 8),
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        container.read(updateAssetValueControllerProvider),
        isA<AsyncError<void>>(),
      );
    });

    test('removeFromPortfolio drops the holding', () async {
      await controller().removeFromPortfolio('btc');

      expect(await repository.getPositionByAssetId('btc'), isNull);
    });
  });

  group('AssetManagementController', () {
    AssetManagementController controller() =>
        container.read(assetManagementControllerProvider.notifier);

    test('creates an asset with trimmed name and upper-case code', () async {
      final id = await controller().createAsset(
        name: '  Emas Antam ',
        code: ' lm ',
        category: AssetCategory.preciousMetal,
      );

      final asset = await repository.getAssetById(id);
      expect(id, startsWith('lm-'));
      expect(asset!.name, 'Emas Antam');
      expect(asset.code, 'LM');
    });

    test('requires a name and a code', () {
      expect(
        () => controller().createAsset(
          name: ' ',
          code: 'X',
          category: AssetCategory.other,
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.failure,
            'failure',
            ValidationFailure.assetNameRequired,
          ),
        ),
      );
      expect(
        () => controller().createAsset(
          name: 'X',
          code: ' ',
          category: AssetCategory.other,
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.failure,
            'failure',
            ValidationFailure.assetCodeRequired,
          ),
        ),
      );
    });

    test('refuses to delete an asset still in the portfolio', () async {
      await expectLater(
        controller().deleteAsset('btc'),
        throwsA(isA<AssetHasHoldingException>()),
      );
      expect(
        container.read(assetManagementControllerProvider),
        isA<AsyncError<void>>(),
      );
    });
  });
}
