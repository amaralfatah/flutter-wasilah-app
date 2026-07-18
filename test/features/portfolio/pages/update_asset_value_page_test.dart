import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/repository/mock_portfolio_repository.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/pages/update_asset_value_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';

void main() {
  testWidgets('update asset value form validates required fields', (
    tester,
  ) async {
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [portfolioRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: UpdateAssetValuePage()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    final saveLabel = find.text('Simpan', skipOffstage: false).last;
    await tester.tap(saveLabel);
    await tester.pumpAndSettle();

    expect(find.text('Aset wajib dipilih.'), findsOneWidget);
    expect(find.text('Nilai aset wajib diisi.'), findsOneWidget);
    expect(find.text('Tanggal wajib dipilih.'), findsNothing);
  });

  testWidgets('update asset value form defaults date to today', (tester) async {
    final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [portfolioRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: UpdateAssetValuePage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(formatFullDate(DateTime.now())), findsOneWidget);
    expect(find.text('Pilih tanggal'), findsNothing);
  });
}
