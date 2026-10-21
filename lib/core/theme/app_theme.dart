import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';

abstract final class AppTheme {
  static const _compactShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );

  static ThemeData light() => _theme(Brightness.light);

  static ThemeData dark() => _theme(Brightness.dark);

  /// Skema warna eksplisit ala Stockbit, bukan turunan seed M3: seed
  /// memberi semburat hijau ke semua surface, sedangkan Stockbit memakai
  /// hitam/putih netral dengan aksen hijau saja.
  static ColorScheme _colorScheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final accent = isDark ? AppColors.accent : AppColors.accentLight;
    final base = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    );

    return isDark
        ? base.copyWith(
            primary: accent,
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFF0E2A1F),
            onPrimaryContainer: const Color(0xFF2FD08F),
            secondary: accent,
            onSecondary: Colors.white,
            secondaryContainer: const Color(0xFF0E2A1F),
            onSecondaryContainer: const Color(0xFF2FD08F),
            surface: const Color(0xFF121212),
            onSurface: const Color(0xFFEDEDED),
            onSurfaceVariant: const Color(0xFF8F8F8F),
            surfaceContainerLowest: const Color(0xFF0D0D0D),
            surfaceContainerLow: const Color(0xFF1A1A1A),
            surfaceContainer: const Color(0xFF1E1E1E),
            surfaceContainerHigh: const Color(0xFF242424),
            surfaceContainerHighest: const Color(0xFF2C2C2C),
            outline: const Color(0xFF3D3D3D),
            outlineVariant: const Color(0xFF2A2A2A),
            error: const Color(0xFFF0524A),
            inverseSurface: const Color(0xFFEDEDED),
            onInverseSurface: const Color(0xFF121212),
            surfaceTint: Colors.transparent,
          )
        : base.copyWith(
            primary: accent,
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFFE3F6EC),
            onPrimaryContainer: const Color(0xFF007A4A),
            secondary: accent,
            onSecondary: Colors.white,
            secondaryContainer: const Color(0xFFE3F6EC),
            onSecondaryContainer: const Color(0xFF007A4A),
            surface: Colors.white,
            onSurface: const Color(0xFF1A1A1A),
            onSurfaceVariant: const Color(0xFF7A7A7A),
            surfaceContainerLowest: Colors.white,
            surfaceContainerLow: const Color(0xFFF5F5F5),
            surfaceContainer: const Color(0xFFF2F2F2),
            surfaceContainerHigh: const Color(0xFFEDEDED),
            surfaceContainerHighest: const Color(0xFFE6E6E6),
            outline: const Color(0xFFCFCFCF),
            outlineVariant: const Color(0xFFE6E6E6),
            error: const Color(0xFFD92D20),
            inverseSurface: const Color(0xFF1A1A1A),
            onInverseSurface: Colors.white,
            surfaceTint: Colors.transparent,
          );
  }

  static ThemeData _theme(Brightness brightness) {
    final colorScheme = _colorScheme(brightness);
    final labelStyle = _compactTextTheme(base: null).labelSmall;

    final base = ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: 'Inter',
      visualDensity: VisualDensity.compact,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        toolbarHeight: 52,
        // Judul Stockbit kecil dan tebal ("Performance"), bukan title
        // large M3.
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          height: 22 / 16,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      // Tab teks kapital rata penuh dengan garis bawah hijau (STOCKS /
      // ORDER / HISTORY, PORTFOLIO / TRADE).
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: colorScheme.primary, width: 3),
        ),
        dividerColor: colorScheme.outlineVariant,
        dividerHeight: 1,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: const CircleBorder(),
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
          (states) => labelStyle?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
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
      // Kartu Stockbit: bergaris tipis abu, latar sama dengan halaman.
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: _compactShape.copyWith(
          side: BorderSide(color: colorScheme.outline, width: 0.6),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : colorScheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: _compactShape,
      ),
      // Chip filter Stockbit: pil bergaris tanpa centang; terpilih =
      // garis + teks hijau di atas semburat hijau gelap.
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        labelPadding: EdgeInsets.zero,
        shape: StadiumBorder(side: BorderSide(color: colorScheme.outline)),
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.outline,
          ),
        ),
        color: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.primaryContainer
              : Colors.transparent,
        ),
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
        showCheckmark: false,
      ),
      // Field Stockbit berlatar abu gelap tanpa garis (kolom pencarian,
      // form order); fokus ditandai garis hijau.
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.error)
                ? colorScheme.error
                : states.contains(WidgetState.focused)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        // UnderlineInputBorder (bukan Outline) supaya label mengambang tetap
        // di dalam isian, tidak menumpang di tepi atas seperti field outline.
        border: const UnderlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide.none,
        ),
        disabledBorder: const UnderlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: UnderlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: UnderlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: _compactShape,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        showDragHandle: true,
        dragHandleColor: colorScheme.outline,
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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: _compactShape,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(0, 44),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: _compactShape,
          side: BorderSide(color: colorScheme.outline),
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size(0, 44),
        ),
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
    // Stockbit: huruf rapat (tanpa letter spacing M3 0,25–0,5), ukuran
    // kecil, dan tebal secukupnya — angka tebal hanya di hero.
    TextStyle? tight(
      TextStyle? style,
      double size,
      double height, [
      FontWeight? weight,
    ]) => style?.copyWith(
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      letterSpacing: 0,
    );

    return theme.copyWith(
      headlineMedium: tight(theme.headlineMedium, 28, 34, FontWeight.w700),
      headlineSmall: tight(theme.headlineSmall, 22, 28, FontWeight.w700),
      titleLarge: tight(theme.titleLarge, 18, 24, FontWeight.w600),
      titleMedium: tight(theme.titleMedium, 15, 20, FontWeight.w600),
      titleSmall: tight(theme.titleSmall, 14, 20, FontWeight.w500),
      bodyLarge: tight(theme.bodyLarge, 15, 20, FontWeight.w400),
      bodyMedium: tight(theme.bodyMedium, 14, 20, FontWeight.w400),
      bodySmall: tight(theme.bodySmall, 12, 16, FontWeight.w400),
      labelLarge: tight(theme.labelLarge, 14, 20, FontWeight.w500),
      labelMedium: tight(theme.labelMedium, 12, 16, FontWeight.w500),
      labelSmall: tight(theme.labelSmall, 11, 14, FontWeight.w500),
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
