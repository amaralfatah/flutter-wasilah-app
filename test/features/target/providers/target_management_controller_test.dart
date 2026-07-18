import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/mock_portfolio_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/target/providers/target_management_controller.dart';

void main() {
  test('saveTarget updates a valid target allocation', () async {
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
    final container = ProviderContainer(
      overrides: [portfolioRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container
        .read(targetManagementControllerProvider.notifier)
        .saveTarget(
          id: 'target-mutual-fund',
          category: AssetCategory.mutualFund,
          targetPercentage: 5,
        );

    final targets = await repository.getAllocationTargets();
    final cashTarget = targets.singleWhere(
      (target) => target.category == AssetCategory.mutualFund,
    );

    expect(cashTarget.targetPercentage, 5);
  });

  test('saveTarget rejects allocations above 100 percent total', () async {
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);
    final container = ProviderContainer(
      overrides: [portfolioRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    expect(
      () => container
          .read(targetManagementControllerProvider.notifier)
          .saveTarget(
            id: 'target-cash',
            category: AssetCategory.cash,
            targetPercentage: 20,
          ),
      throwsArgumentError,
    );
  });
}
