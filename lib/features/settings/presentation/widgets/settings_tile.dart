import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
    this.subtitle,
    this.value,
    this.trailing,
    this.color,
  });

  final IconData icon;
  final String title;

  /// Teks kecil di bawah judul.
  final String? subtitle;

  /// Teks kecil di kiri chevron, untuk nilai pilihan aktif.
  final String? value;
  final Widget? trailing;
  final Color? color;

  /// `null` menonaktifkan baris.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: color,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: mutedColor,
                          ),
                        ),
                    ],
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    value!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: mutedColor,
                    ),
                  ),
                ],
                const SizedBox(width: AppSpacing.xs),
                trailing ?? Icon(Icons.chevron_right, color: mutedColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 0.2);
  }
}

class SettingsTileProgress extends StatelessWidget {
  const SettingsTileProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
