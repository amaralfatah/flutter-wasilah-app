import 'package:flutter/material.dart';

class AllocationBadge extends StatelessWidget {
  const AllocationBadge({super.key, required this.percentage});

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
        '${percentage.toStringAsFixed(0)}%',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSecondaryContainer,
            ),
      ),
    );
  }
}
