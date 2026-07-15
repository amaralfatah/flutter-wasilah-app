import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/portfolio/repository/mock_portfolio_repository.dart';

void main() {
  test(
    'updateAssetValue refreshes asset value, history, and allocations',
    () async {
      final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);

      final beforeSummary = await repository.getPortfolioSummary();
      final beforeBitcoin = await repository.getAssetById('btc');
      final beforeHistory = await repository.getAssetHistory('btc');

      expect(beforeSummary.totalValue, 55000000);
      expect(beforeBitcoin, isNotNull);
      expect(beforeBitcoin!.currentValue, 18200000);
      expect(beforeHistory, hasLength(2));

      await repository.updateAssetValue(
        assetId: 'btc',
        totalValue: 50000000,
        recordedAt: DateTime(2026, 7, 15),
        note: 'Update Juli',
      );

      final afterSummary = await repository.getPortfolioSummary();
      final afterBitcoin = await repository.getAssetById('btc');
      final afterHistory = await repository.getAssetHistory('btc');

      expect(afterSummary.totalValue, 86800000);
      expect(afterBitcoin, isNotNull);
      expect(afterBitcoin!.currentValue, 50000000);
      expect(afterBitcoin.lastUpdatedAt, DateTime(2026, 7, 15));
      expect(afterBitcoin.allocationPercentage, closeTo(57.6, 0.01));
      expect(afterHistory, hasLength(3));
      expect(afterHistory.first.totalValue, 50000000);
      expect(afterHistory.first.note, 'Update Juli');
    },
  );
}
