import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_wasilah_app/shared/widgets/labeled_field.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    required this.controller,
    super.key,
    this.hint,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.onTap,
    this.helperText,
    this.prefixText,
    this.onChanged,
    this.inputFormatters,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? helperText;
  final String? prefixText;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: label,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        maxLength: maxLength,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: suffixIcon,
          helperText: helperText,
          prefixText: prefixText,
        ),
      ),
    );
  }
}
