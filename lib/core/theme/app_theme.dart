import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() => _theme(Brightness.light);

  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );

    final base = ThemeData(
      colorScheme: colorScheme,
      visualDensity: VisualDensity.compact,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        toolbarHeight: 52,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        height: 60,
        labelTextStyle: WidgetStatePropertyAll(
          _compactTextTheme(base: null).labelSmall,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      chipTheme: const ChipThemeData(
        padding: EdgeInsets.symmetric(horizontal: 12),
        labelPadding: EdgeInsets.zero,
        shape: StadiumBorder(),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        minVerticalPadding: 8,
      ),
    );

    return base.copyWith(
      textTheme: _tabularFigures(_compactTextTheme(base: base.textTheme)),
    );
  }

  /// Hierarki tipografi dipangkas ala Stockbit: kode/nominal harus terbaca
  /// cepat tanpa memakan tinggi baris—lihat token size di app_theme.dart
  /// bila perlu menambah level baru.
  static TextTheme _compactTextTheme({required TextTheme? base}) {
    final theme = base ?? Typography.material2021().black;
    return theme.copyWith(
      headlineSmall: theme.headlineSmall?.copyWith(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: theme.titleSmall?.copyWith(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: theme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 20 / 14,
      ),
      labelMedium: theme.labelMedium?.copyWith(
        fontSize: 12,
        height: 16 / 12,
      ),
      bodySmall: theme.bodySmall?.copyWith(
        fontSize: 12,
        height: 16 / 12,
      ),
      labelSmall: theme.labelSmall?.copyWith(
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w500,
      ),
    );
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
