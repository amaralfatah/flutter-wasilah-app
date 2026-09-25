import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';

import '../../../helpers/mock_portfolio_repository.dart';

void main() {
  test('reads refresh on their own after a repository write', () async {
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
    final container = ProviderContainer(
      overrides: [
        portfolioRepositoryProvider.overrideWithValue(repository),
        assetRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(assetOverviewProvider, (_, _) {});
    addTearDown(subscription.close);

    final before = await container.read(assetOverviewProvider.future);
    await repository.createAsset(
      const Asset(
        id: 'new',
        name: 'Aset Baru',
        code: 'NEW',
        category: AssetCategory.other,
      ),
    );
    await pumpEventQueue();

    final after = await container.read(assetOverviewProvider.future);
    expect(after, hasLength(before.length + 1));
    expect(after.map((position) => position.id), contains('new'));
  });
}
