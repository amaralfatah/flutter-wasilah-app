import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';

/// Prefill simbol Yahoo Finance dari kategori dan kode aset, mis. saham
/// `BMRI` -> `BMRI.JK`. `null` bila kategori tidak biasa punya harga pasar
/// atau kode kosong.
///
/// Bila [code] sudah mengandung `.`, `-`, `^`, atau `=`, dianggap sudah
/// berupa simbol lengkap dan dikembalikan apa adanya (huruf besar).
String? suggestMarketSymbol(AssetCategory category, String code) {
  final normalized = code.trim().toUpperCase();
  if (normalized.isEmpty) {
    return null;
  }

  if (_looksLikeFullSymbol(normalized)) {
    return normalized;
  }

  switch (category) {
    case AssetCategory.stock:
      return '$normalized.JK';
    case AssetCategory.crypto:
      return '$normalized-USD';
    case AssetCategory.indexEtf:
      return normalized;
    case AssetCategory.mutualFund:
    case AssetCategory.preciousMetal:
    case AssetCategory.cash:
    case AssetCategory.other:
      return null;
  }
}

bool _looksLikeFullSymbol(String code) {
  return code.contains('.') ||
      code.contains('-') ||
      code.contains('^') ||
      code.contains('=');
}
