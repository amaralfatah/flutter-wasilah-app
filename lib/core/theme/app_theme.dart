import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';

abstract final class AppTheme {
  static const _compactShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );

  static ThemeData light() => _theme(Brightness.light);

  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );

    final base = ThemeData(
      colorScheme: colorScheme,
      fontFamily: 'Inter',
      visualDensity: VisualDensity.compact,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        toolbarHeight: 52,
      ),
      // Tab aktif ditandai warna ikon/label saja, tanpa pil indikator M3 —
      // seperti bar bawah Stockbit.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        height: 60,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => _compactTextTheme(base: null).labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        selectedLabelTextStyle: _compactTextTheme(
          base: null,
        ).labelSmall?.copyWith(color: colorScheme.primary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        margin: EdgeInsets.zero,
        shape: _compactShape.copyWith(
          side: BorderSide(color: colorScheme.outlineVariant, width: 0.3),
        ),
      ),
      // Chip filter Stockbit berbentuk pil bergaris tanpa centang; status
      // terpilih cukup dibedakan warna.
      chipTheme: const ChipThemeData(
        padding: EdgeInsets.symmetric(horizontal: 12),
        labelPadding: EdgeInsets.zero,
        shape: StadiumBorder(),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: _compactShape,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ),
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 0,
        color: colorScheme.outlineVariant,
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        minVerticalPadding: 8,
      ),
      filledButtonTheme: const FilledButtonThemeData(
        style: ButtonStyle(shape: WidgetStatePropertyAll(_compactShape)),
      ),
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: ButtonStyle(shape: WidgetStatePropertyAll(_compactShape)),
      ),
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(shape: WidgetStatePropertyAll(_compactShape)),
      ),
      segmentedButtonTheme: const SegmentedButtonThemeData(
        style: ButtonStyle(shape: WidgetStatePropertyAll(_compactShape)),
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
