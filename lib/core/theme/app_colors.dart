import 'package:flutter/material.dart';

/// Palet mengikuti aplikasi Stockbit: hitam netral (bukan kebiruan), satu
/// aksen hijau, dan hijau/merah hanya untuk naik/turun.
abstract final class AppColors {
  /// Hijau aksen Stockbit: tab/nav terpilih, chip aktif, tombol utama.
  static const Color accent = Color(0xFF00AB6B);
  static const Color accentLight = Color(0xFF00A062);

  static const Color _positiveLight = Color(0xFF00995C);
  static const Color _positiveDark = Color(0xFF1DB97A);
  static const Color _negativeLight = Color(0xFFD92D20);
  static const Color _negativeDark = Color(0xFFF0524A);
  static const Color _warningLight = Color(0xFFB26B00);
  static const Color _warningDark = Color(0xFFF5B547);

  // Palet donut alokasi ala "Stocks Allocation" Stockbit: hijau aksen,
  // mint, biru, ungu, sian, lalu abu — tiap irisan beda warna, dan bar di
  // daftar memakai warna irisannya. Urutan = AssetCategory.index (kripto,
  // saham, reksa dana, indeks/ETF, logam mulia, kas, lainnya).
  static const List<Color> _categoryPaletteLight = [
    Color(0xFF7C4DFF),
    Color(0xFF00A062),
    Color(0xFF2F6FEB),
    Color(0xFF1FB894),
    Color(0xFF0E9AB0),
    Color(0xFF8C8C8C),
    Color(0xFF5E5E5E),
  ];
  static const List<Color> _categoryPaletteDark = [
    Color(0xFF8B5CF6),
    Color(0xFF00AB6B),
    Color(0xFF3B82F6),
    Color(0xFF3DD9B4),
    Color(0xFF22B8CF),
    Color(0xFF9E9E9E),
    Color(0xFF616161),
  ];

  static Color positiveOf(BuildContext context) =>
      _isDark(context) ? _positiveDark : _positiveLight;

  static Color negativeOf(BuildContext context) =>
      _isDark(context) ? _negativeDark : _negativeLight;

  static Color warningOf(BuildContext context) =>
      _isDark(context) ? _warningDark : _warningLight;

  static Color categoryColorOf(BuildContext context, int categoryIndex) {
    final palette = _isDark(context)
        ? _categoryPaletteDark
        : _categoryPaletteLight;
    return palette[categoryIndex % palette.length];
  }

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}
