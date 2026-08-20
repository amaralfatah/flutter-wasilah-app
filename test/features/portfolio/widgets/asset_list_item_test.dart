import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/core/theme/app_theme.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/asset_list_item.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_list_card.dart';

Asset _asset(double value) => Asset(
  id: 'a',
  name: 'Bitcoin',
  code: 'BTC',
  category: AssetCategory.crypto,
  currentValue: value,
  allocationPercentage: 12.5,
  lastUpdatedAt: DateTime(2026, 7, 17),
);

Future<void> _pumpRow(
  WidgetTester tester, {
  required double value,
  required double screenWidth,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(screenWidth * 3, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AppListCard(
              children: [AssetListItem(asset: _asset(value), onTap: () {})],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AssetListItem', () {
    // Regresi: dulu nominal panjang menyisakan lebar nyaris nol untuk nama
    // aset, membuat teks membungkus per huruf dan tinggi baris meledak
    // sampai 724dp.
    testWidgets('tinggi baris tidak terpengaruh besarnya nominal', (
      tester,
    ) async {
      final heights = <double>[];

      for (final value in <double>[50000, 2500000, 123456789]) {
        await _pumpRow(tester, value: value, screenWidth: 360);
        heights.add(tester.getRect(find.byType(AssetListItem)).height);
      }

      expect(heights.toSet(), hasLength(1));
      expect(heights.first, lessThan(100));
    });

    testWidgets('kode aset tetap mendapat ruang baca', (tester) async {
      await _pumpRow(tester, value: 123456789, screenWidth: 360);

      // Kode aset pendek, jadi lebar teksnya tidak mewakili ruang yang
      // tersedia. Ukur jarak judul ke kolom nominal sebagai proksi slot.
      final titleLeft = tester.getRect(find.text('BTC')).left;
      final valueLeft = tester.getRect(find.byType(FittedBox)).left;
      expect(valueLeft - titleLeft, greaterThan(100));
    });

    testWidgets('tidak meluber di layar sempit dan skala teks besar', (
      tester,
    ) async {
      await _pumpRow(tester, value: 999999999999, screenWidth: 320);
      expect(tester.takeException(), isNull);

      await _pumpRow(tester, value: 45000000, screenWidth: 360, textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });
}
