import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/features/market/data/models/chart_range.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';

/// Tab teks rata seperti Stockbit (1D 1W 1M 3M YTD 1Y 3Y 5Y), bukan
/// `SegmentedButton` -- delapan opsi terlalu banyak untuk gaya chip.
class ChartRangeTabs extends StatelessWidget {
  const ChartRangeTabs({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final ChartRange selected;
  final ValueChanged<ChartRange> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    String labelFor(ChartRange range) => switch (range) {
      ChartRange.oneDay => l10n.chartRange1D,
      ChartRange.oneWeek => l10n.chartRange1W,
      ChartRange.oneMonth => l10n.chartRange1M,
      ChartRange.threeMonths => l10n.chartRange3M,
      ChartRange.yearToDate => l10n.chartRangeYTD,
      ChartRange.oneYear => l10n.chartRange1Y,
      ChartRange.threeYears => l10n.chartRange3Y,
      ChartRange.fiveYears => l10n.chartRange5Y,
    };

    return Row(
      children: [
        for (final range in ChartRange.values)
          Expanded(
            child: InkWell(
              onTap: () => onSelected(range),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      labelFor(range),
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: range == selected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: range == selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Underline pendek selebar teks, bukan selebar sel.
                    Container(
                      width: 24,
                      height: 3,
                      decoration: BoxDecoration(
                        color: range == selected
                            ? colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
