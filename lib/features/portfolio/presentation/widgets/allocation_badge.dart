import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';

class AllocationBadge extends StatelessWidget {
  const AllocationBadge({required this.percentage, super.key});

  final double percentage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        formatPercentage(percentage),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
