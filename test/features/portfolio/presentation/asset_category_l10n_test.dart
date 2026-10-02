import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/utils/asset_category_l10n.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations_en.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations_id.dart';

void main() {
  test('Indonesian labels match the model labels', () {
    final l10n = AppLocalizationsId();
    for (final category in AssetCategory.values) {
      expect(category.localizedLabel(l10n), category.label);
    }
  });

  test('English labels are translated', () {
    final l10n = AppLocalizationsEn();
    expect(AssetCategory.cash.localizedLabel(l10n), 'Cash');
    expect(AssetCategory.preciousMetal.localizedLabel(l10n), 'Precious metals');
  });
}
