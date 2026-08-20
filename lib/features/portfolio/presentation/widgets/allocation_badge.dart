import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';

class AllocationBadge extends StatelessWidget {
  const AllocationBadge({required this.percentage, super.key});

  final double percentage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Angka telanjang seperti "12%" tidak berarti apa-apa saat dibacakan;
    // konteksnya hanya terlihat dari posisinya di kartu.
    return Semantics(
      label: 'Alokasi ${formatPercentage(percentage)} dari portofolio',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: ShapeDecoration(
          color: colorScheme.secondaryContainer,
          // Sudut penuh: bentuk baku Material 3 untuk badge.
          shape: const StadiumBorder(),
        ),
        child: Text(
          formatPercentage(percentage),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
