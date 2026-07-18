import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/allocation_target.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_summary.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/pages/dashboard_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/portfolio_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/mock_portfolio_repository.dart';

void main() {
  testWidgets('dashboard shows total portfolio summary', (tester) async {
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [portfolioRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: DashboardPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Total Portofolio'), findsOneWidget);
    expect(find.text('Rp55.000.000'), findsOneWidget);
    expect(find.text('Naik 3,4% bulan ini'), findsOneWidget);
    expect(find.text('Update nilai'), findsNothing);
  });

  testWidgets(
    'dashboard shows target setup prompt when allocation targets are empty',
    (tester) async {
      final assets = [
        Asset(
          id: 'bbri',
          name: 'Bank Rakyat Indonesia',
          code: 'BBRI',
          category: AssetCategory.stock,
          currentValue: 12000000,
          allocationPercentage: 100,
          lastUpdatedAt: DateTime(2026, 7, 16),
        ),
      ];
      final repository = _DashboardNoTargetRepository(
        summary: PortfolioSummary(
          totalValue: 12000000,
          monthlyChangePercentage: 2.5,
          targetProgressPercentage: 0,
          assets: assets,
          lastUpdatedAt: DateTime(2026, 7, 16),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            portfolioRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: DashboardPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Belum ada target alokasi'), findsOneWidget);
      expect(find.text('0%'), findsNothing);
    },
  );
}

class _DashboardNoTargetRepository implements PortfolioRepository {
  const _DashboardNoTargetRepository({required this.summary});

  final PortfolioSummary summary;

  @override
  Future<List<AllocationTarget>> getAllocationTargets() async => const [];

  @override
  Future<Asset?> getAssetById(String assetId) async =>
      summary.assets.firstOrNull;

  @override
  Future<List<Asset>> getAssets() async => summary.assets;

  @override
  Future<PortfolioSummary> getPortfolioSummary() async => summary;

  @override
  Future<List<AssetSnapshot>> getPortfolioHistory() async => const [];

  @override
  Future<List<AssetSnapshot>> getAssetHistory(String assetId) async => const [];

  @override
  Future<void> createAsset(Asset asset) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAllocationTarget(String targetId) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAsset(String assetId) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteSnapshot(String snapshotId) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveAllocationTarget(AllocationTarget target) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateAsset(Asset asset) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateAssetValue({
    required String assetId,
    required double totalValue,
    required DateTime recordedAt,
    String? note,
  }) {
    throw UnimplementedError();
  }
}
