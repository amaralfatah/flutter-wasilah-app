import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/validators.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';

/// Field tanggal catat. Tanggal masa depan tidak bisa dipilih: nilai aset
/// dicatat untuk hari ini atau sebelumnya.
class RecordedDateField extends StatelessWidget {
  const RecordedDateField({
    required this.initialValue,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final DateTime? initialValue;
  final bool enabled;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return FormField<DateTime>(
      initialValue: initialValue,
      validator: (date) => validateSelectedDate(date, l10n),
      builder: (field) {
        final selectedDate = field.value;
        final hasValue = selectedDate != null;

        return InkWell(
          onTap: enabled ? () => unawaited(_pickDate(context, field)) : null,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.commonRecordedAtLabel,
              errorText: field.errorText,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            child: Text(
              hasValue
                  ? formatFullDate(
                      selectedDate,
                      Localizations.localeOf(context),
                    )
                  : l10n.commonSelectDatePlaceholder,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: hasValue ? null : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    FormFieldState<DateTime> field,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = field.value;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current == null || current.isAfter(today) ? today : current,
      firstDate: DateTime(now.year - 10),
      lastDate: today,
    );

    if (pickedDate == null) {
      return;
    }

    onChanged(pickedDate);
    field.didChange(pickedDate);
  }
}
