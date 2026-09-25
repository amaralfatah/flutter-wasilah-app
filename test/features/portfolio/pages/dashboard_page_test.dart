import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/allocation_target.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/holding.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_summary.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/mock_portfolio_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/portfolio_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/pages/dashboard_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';

void main() {
  testWidgets('dashboard shows total portfolio summary', (tester) async {
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioRepositoryProvider.overrideWithValue(repository),
          assetRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          locale: Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DashboardPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Total Ekuitas'), findsOneWidget);
    expect(find.text('55.000.000'), findsOneWidget);
    expect(find.text('Kas'), findsOneWidget);
    expect(find.text('6.600.000'), findsOneWidget);
    expect(find.text('Bulan Ini'), findsNothing);
    // Dashboard sengaja tanpa FAB: update nilai dicapai lewat tab Aset.
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('dashboard hides the update action while there are no assets', (
    tester,
  ) async {
    final repository = _DashboardNoTargetRepository(
      summary: PortfolioSummary(
        totalValue: 0,
        monthlyChangePercentage: 0,
        targetProgressPercentage: 0,
        positions: const [],
        lastUpdatedAt: DateTime(2026, 7, 16),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [portfolioRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          locale: Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DashboardPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Belum ada aset'), findsOneWidget);
    expect(find.text('Update nilai'), findsNothing);
  });

  testWidgets(
    'dashboard shows target setup prompt when allocation targets are empty',
    (tester) async {
      final assets = [
        PortfolioPosition(
          asset: const Asset(
            id: 'bbri',
            name: 'Bank Rakyat Indonesia',
            code: 'BBRI',
            category: AssetCategory.stock,
          ),
          holding: Holding(
            assetId: 'bbri',
            currentValue: 12000000,
            lastUpdatedAt: DateTime(2026, 7, 16),
          ),
          allocationPercentage: 100,
        ),
      ];
      final repository = _DashboardNoTargetRepository(
        summary: PortfolioSummary(
          totalValue: 12000000,
          monthlyChangePercentage: 2.5,
          targetProgressPercentage: 0,
          positions: assets,
          lastUpdatedAt: DateTime(2026, 7, 16),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            portfolioRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            locale: Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: DashboardPage(),
          ),
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
  Future<List<PortfolioPosition>> getPositions() async => summary.positions;

  @override
  Future<PortfolioPosition?> getPositionByAssetId(String assetId) async =>
      summary.positions.where((position) => position.id == assetId).firstOrNull;

  @override
  Future<PortfolioSummary> getPortfolioSummary() async => summary;

  @override
  Future<List<PortfolioSnapshot>> getPortfolioHistory() async => const [];

  @override
  Future<List<AssetSnapshot>> getAssetHistory(String assetId) async => const [];

  @override
  Future<void> deleteAllocationTarget(String targetId) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAssetSnapshot(String snapshotId) {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePortfolioSnapshot(String snapshotId) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeFromPortfolio(String assetId) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveAllocationTarget(AllocationTarget target) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateAssetValue({
    required String assetId,
    required double totalValue,
    required DateTime recordedAt,
    String? note,
    double? totalCost,
    double? quantity,
    double? avgBuyPrice,
    String? priceCurrency,
  }) {
    throw UnimplementedError();
  }
}
