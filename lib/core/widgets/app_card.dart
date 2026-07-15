import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/app/theme/app_radius.dart';
import 'package:flutter_wasilah_app/app/theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final body = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );

    return Card(
      color: backgroundColor ?? colorScheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      child: onTap == null
          ? body
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.large),
              child: body,
            ),
    );
  }
}
