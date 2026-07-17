import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color seed = Color(0xFF0B57D0);

  static const Color _positiveLight = Color(0xFF137333);
  static const Color _positiveDark = Color(0xFF81C995);
  static const Color _negativeLight = Color(0xFFC5221F);
  static const Color _negativeDark = Color(0xFFF28B82);
  static const Color _warningLight = Color(0xFFB06000);
  static const Color _warningDark = Color(0xFFFDD663);

  static const List<Color> _categoryPaletteLight = [
    Color(0xFF0B57D0),
    Color(0xFF137333),
    Color(0xFFB06000),
    Color(0xFF8430CE),
    Color(0xFFC5221F),
    Color(0xFF12656B),
    Color(0xFF9E6A00),
  ];
  static const List<Color> _categoryPaletteDark = [
    Color(0xFFA8C7FA),
    Color(0xFF81C995),
    Color(0xFFFDD663),
    Color(0xFFD0BCFF),
    Color(0xFFF28B82),
    Color(0xFF6DD3D8),
    Color(0xFFFFCB6B),
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
