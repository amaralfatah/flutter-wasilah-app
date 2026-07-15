import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/portfolio/pages/dashboard_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/repository/mock_portfolio_repository.dart';

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
    expect(find.text('Update nilai'), findsOneWidget);
  });
}
