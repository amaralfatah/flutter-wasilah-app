import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/features/market/data/models/chart_range.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/period_tabs.dart';

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

    return PeriodTabs<ChartRange>(
      options: ChartRange.values,
      selected: selected,
      labelOf: labelFor,
      onSelected: onSelected,
    );
  }
}
