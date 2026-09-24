import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';

/// Pita selebar layar pemisah section, ala Stockbit: tanpa [label] jadi
/// jeda tebal antarblok; dengan [label] jadi judul grup (mis. tahun) di
/// atas daftar full-bleed.
class AppSectionBand extends StatelessWidget {
  const AppSectionBand({
    super.key,
    this.label,
    this.actionLabel,
    this.onAction,
  });

  final String? label;
  final String? actionLabel;
  final VoidCallback? onAction;

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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (actionLabel != null && onAction != null)
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(actionLabel!),
                    ),
                ],
              ),
            ),
    );
  }
}
