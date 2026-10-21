import 'package:flutter/material.dart';

/// Tab teks rata dengan garis bawah hijau pendek seperti pemilih periode
/// Stockbit (1W 1M 3M YTD 1Y All), bukan chip atau `SegmentedButton`.
class PeriodTabs<T> extends StatelessWidget {
  const PeriodTabs({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    super.key,
  });

  final List<T> options;
  final T selected;
  final String Function(T option) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        for (final option in options)
          Expanded(
            child: Semantics(
              selected: option == selected,
              button: true,
              child: InkWell(
                onTap: () => onSelected(option),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          labelOf(option),
                          maxLines: 1,
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: option == selected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            fontWeight: option == selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Underline pendek selebar teks, bukan selebar sel.
                      Container(
                        width: 24,
                        height: 3,
                        decoration: BoxDecoration(
                          color: option == selected
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
          ),
      ],
    );
  }
}
