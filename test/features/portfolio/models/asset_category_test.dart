import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/portfolio/models/asset.dart';

void main() {
  test('precious metals have their own asset category label', () {
    expect(AssetCategory.preciousMetal.label, 'Logam Mulia');
    expect(AssetCategory.values, contains(AssetCategory.preciousMetal));
  });

  test('index funds and ETFs have their own asset category label', () {
    expect(AssetCategory.indexEtf.label, 'Indeks / ETF');
    expect(AssetCategory.values, contains(AssetCategory.indexEtf));
  });
}
