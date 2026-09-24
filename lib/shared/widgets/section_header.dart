import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.actionLabel,
    this.onAction,
    this.onInfoTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onInfoTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(child: Text(title, style: textTheme.titleMedium)),
        if (onInfoTap != null)
          IconButton(
            onPressed: onInfoTap,
            tooltip: context.l10n.sectionHeaderInfoTooltip,
            icon: const Icon(Icons.info_outline),
            visualDensity: VisualDensity.compact,
          ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}
