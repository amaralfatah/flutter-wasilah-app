import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';

/// Pita selebar layar pemisah section, ala Stockbit: tanpa [label] jadi
/// jeda tebal antarblok; dengan [label] jadi judul grup (mis. tahun) di
/// atas daftar full-bleed.
class AppSectionBand extends StatelessWidget {
  const AppSectionBand({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerLow,
      child: label == null
          ? const SizedBox(width: double.infinity, height: AppSpacing.sm)
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                label!,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }
}
