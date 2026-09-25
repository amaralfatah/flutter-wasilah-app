import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
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
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => controller().createAsset(
          name: 'X',
          code: ' ',
          category: AssetCategory.other,
        ),
        throwsA(isA<ArgumentError>()),
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
