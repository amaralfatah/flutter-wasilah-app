import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/utils/decimal_input_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/rupiah_input_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/update_asset_value/currency_picker.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_text_field.dart';

/// Field nominal (modal/nilai) dengan pilihan mata uang inline. IDR diisi
/// bilangan bulat berpemisah ribuan; mata uang lain boleh 2 desimal.
class MoneyField extends StatelessWidget {
  const MoneyField({
    required this.label,
    required this.controller,
    required this.currency,
    required this.helperText,
    required this.onCurrencyChanged,
    super.key,
    this.validator,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String currency;
  final String? helperText;
  final ValueChanged<String>? onCurrencyChanged;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isIdr = currency == 'IDR';
    return AppTextField(
      label: label,
      helperText: helperText,
      controller: controller,
      keyboardType: isIdr
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: isIdr
          ? const [RupiahInputFormatter()]
          : const [DecimalInputFormatter(maxDecimals: 2)],
      validator: validator,
      onChanged: onChanged,
      suffixIcon: CurrencyPicker(
        value: currency,
        onChanged: onCurrencyChanged,
      ),
    );
  }
}
