import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';

/// Mata uang yang bisa dipilih untuk field nominal di form update nilai.
const updateValueCurrencies = ['IDR', 'USD'];

/// Pilihan mata uang inline di ujung field nominal.
class CurrencyPicker extends StatelessWidget {
  const CurrencyPicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          items: updateValueCurrencies
              .map(
                (currency) => DropdownMenuItem(
                  value: currency,
                  child: Text(currency),
                ),
              )
              .toList(),
          onChanged: onChanged == null
              ? null
              : (currency) {
                  if (currency != null && currency != value) {
                    onChanged(currency);
                  }
                },
        ),
      ),
    );
  }
}
