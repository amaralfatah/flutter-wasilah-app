import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() => _theme(Brightness.light);

  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.seed,
        brightness: brightness,
      ),
    );

    return base.copyWith(textTheme: _tabularFigures(base.textTheme));
  }

  /// Angka rupiah muncul di hampir setiap layar, sering dalam kolom yang
  /// sejajar. Tanpa tabular figures lebar tiap digit berbeda sehingga kolom
  /// nominal terlihat bergoyang saat nilainya berubah.
  static TextTheme _tabularFigures(TextTheme theme) {
    const features = [FontFeature.tabularFigures()];
    TextStyle? tabular(TextStyle? style) =>
        style?.copyWith(fontFeatures: features);

    return TextTheme(
      displayLarge: tabular(theme.displayLarge),
      displayMedium: tabular(theme.displayMedium),
      displaySmall: tabular(theme.displaySmall),
      headlineLarge: tabular(theme.headlineLarge),
      headlineMedium: tabular(theme.headlineMedium),
      headlineSmall: tabular(theme.headlineSmall),
      titleLarge: tabular(theme.titleLarge),
      titleMedium: tabular(theme.titleMedium),
      titleSmall: tabular(theme.titleSmall),
      bodyLarge: tabular(theme.bodyLarge),
      bodyMedium: tabular(theme.bodyMedium),
      bodySmall: tabular(theme.bodySmall),
      labelLarge: tabular(theme.labelLarge),
      labelMedium: tabular(theme.labelMedium),
      labelSmall: tabular(theme.labelSmall),
    );
  }
}
