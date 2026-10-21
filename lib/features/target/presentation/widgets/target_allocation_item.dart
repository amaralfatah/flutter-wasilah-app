import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/utils/asset_category_l10n.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/asset_category_icon.dart';
import 'package:flutter_wasilah_app/features/target/providers/target_providers.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';

/// Baris alokasi ala "Portfolio Allocation" Stockbit: ikon, kategori dan
/// nilainya, persen aktual di kanan, lalu bar tipis selebar baris. Di
/// bawah bar: target dan selisihnya dalam rupiah sekaligus persen.
class TargetAllocationItem extends StatelessWidget {
  const TargetAllocationItem({required this.item, super.key, this.onTap});

  final TargetAllocationData item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final mutedStyle = textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    // Selisih di dalam batas wajar tetap netral; warna hanya untuk kategori
    // yang perlu rebalancing.
    final differenceColor = item.status == TargetStatus.onTrack
        ? colorScheme.onSurfaceVariant
        : item.statusColor(context);
    final category = item.category.localizedLabel(l10n);
    final differenceText =
        '${formatSignedNumber(item.differenceValue)} '
        '(${formatSignedPercentage(item.differencePercentage)})';

    return Semantics(
      button: onTap != null,
      label:
          '$category. '
          '${l10n.targetAllocationActualOfTarget(
            formatPercentage(item.actualPercentage),
            formatPercentage(item.targetPercentage),
          )}. '
          '${l10n.targetDifferenceLabel} '
          '${formatSignedCurrency(item.differenceValue)}, '
          '${item.status.localizedLabel(l10n)}.',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              AssetCategoryIcon(
                category: item.category,
                radius: 18,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: category,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: '  ${formatCurrency(item.actualValue)}',
                                  style: mutedStyle,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          formatPercentage(item.actualPercentage),
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 10,
                      child: CustomPaint(
                        painter: _AllocationBarPainter(
                          actual: item.actualPercentage,
                          target: item.targetPercentage,
                          fillColor: AppColors.categoryColorOf(
                            context,
                            item.category.index,
                          ),
                          trackColor: colorScheme.surfaceContainerHighest,
                          markerColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Text(
                          l10n.targetAllocationTargetValue(
                            formatPercentage(item.targetPercentage),
                          ),
                          style: mutedStyle,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              differenceText,
                              maxLines: 1,
                              style: textTheme.bodySmall?.copyWith(
                                color: differenceColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bar alokasi Stockbit (0–100%) dengan penanda target tegak.
class _AllocationBarPainter extends CustomPainter {
  _AllocationBarPainter({
    required this.actual,
    required this.target,
    required this.fillColor,
    required this.trackColor,
    required this.markerColor,
  });

  final double actual;
  final double target;
  final Color fillColor;
  final Color trackColor;
  final Color markerColor;

  @override
  void paint(Canvas canvas, Size size) {
    const barHeight = 4.0;
    const radius = Radius.circular(barHeight / 2);
    final top = (size.height - barHeight) / 2;
    double xOf(double percent) => (percent / 100).clamp(0.0, 1.0) * size.width;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, top, size.width, barHeight),
        radius,
      ),
      Paint()..color = trackColor,
    );
    if (actual > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, top, xOf(actual), barHeight),
          radius,
        ),
        Paint()..color = fillColor,
      );
    }
    final targetX = xOf(target).clamp(1.0, size.width - 1);
    canvas.drawRect(
      Rect.fromLTWH(targetX - 1, 0, 2, size.height),
      Paint()..color = markerColor,
    );
  }

  @override
  bool shouldRepaint(covariant _AllocationBarPainter oldDelegate) {
    return oldDelegate.actual != actual ||
        oldDelegate.target != target ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.markerColor != markerColor;
  }
}

extension TargetStatusL10n on TargetStatus {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case TargetStatus.onTrack:
        return l10n.targetStatusOnTrack;
      case TargetStatus.below:
        return l10n.targetStatusBelow;
      case TargetStatus.above:
        return l10n.targetStatusAbove;
    }
  }
}
