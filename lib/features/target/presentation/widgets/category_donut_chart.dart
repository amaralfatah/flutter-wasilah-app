import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/target/providers/target_providers.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';

/// Cincin alokasi aktual dengan total nilai di tengahnya. Legenda tidak
/// digambar di sini: daftar target di bawahnya memakai warna yang sama.
class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({required this.items, super.key});

  final List<TargetAllocationData> items;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final segments = items
        .where((item) => item.actualPercentage > 0)
        .toList(growable: false);

    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalValue = segments.fold<double>(
      0,
      (sum, item) => sum + item.actualValue,
    );
    final semanticsSummary = segments
        .map(
          (item) => l10n.categoryDonutSemanticItem(
            item.category.label,
            item.actualPercentage.toStringAsFixed(0),
          ),
        )
        .join(', ');

    return Center(
      child: Semantics(
        label: l10n.categoryDonutSemanticLabel(semanticsSummary),
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: 200,
          child: CustomPaint(
            painter: _DonutPainter(
              values: [for (final item in segments) item.actualPercentage],
              colors: [
                for (final item in segments)
                  AppColors.categoryColorOf(context, item.category.index),
              ],
              trackColor: colorScheme.surfaceContainerHighest,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatCurrency(totalValue),
                      maxLines: 1,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.categoryDonutCategoryCount(segments.length),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.colors,
    required this.trackColor,
  });

  final List<double> values;
  final List<Color> colors;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide * 0.06;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Normalized against a full 100%, so uncategorized allocation shows
    // as a gap in the ring rather than being redistributed among segments.
    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) {
      return;
    }
    final wholeCircle = math.max(total, 100);

    var startAngle = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / wholeCircle) * 2 * math.pi;
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.colors != colors ||
        oldDelegate.trackColor != trackColor;
  }
}
