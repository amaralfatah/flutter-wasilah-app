import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';

/// Label kategori aset sesuai bahasa aplikasi. Pakai ini di UI, bukan
/// `AssetCategoryX.label` (selalu bahasa Indonesia).
extension AssetCategoryL10n on AssetCategory {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    AssetCategory.crypto => l10n.categoryCrypto,
    AssetCategory.stock => l10n.categoryStock,
    AssetCategory.mutualFund => l10n.categoryMutualFund,
    AssetCategory.indexEtf => l10n.categoryIndexEtf,
    AssetCategory.preciousMetal => l10n.categoryPreciousMetal,
    AssetCategory.cash => l10n.categoryCash,
    AssetCategory.other => l10n.categoryOther,
  };
}
