import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/shared/widgets/labeled_field.dart';

/// Satu pilihan di [AppSelectField].
class AppSelectOption<T> {
  const AppSelectOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Field pilihan berlabel yang membuka daftar di bottom sheet, seperti
/// pemilih di Stockbit. Menggantikan menu dropdown bawaan yang melebar
/// melewati tepi field.
class AppSelectField<T> extends FormField<T> {
  AppSelectField({
    required String label,
    required List<AppSelectOption<T>> options,
    required ValueChanged<T>? onChanged,
    super.key,
    super.initialValue,
    super.validator,
  }) : super(
         enabled: onChanged != null,
         builder: (field) {
           final context = field.context;
           final theme = Theme.of(context);
           final selected = options
               .where((option) => option.value == field.value)
               .firstOrNull;

           Future<void> pick() async {
             final picked = await showModalBottomSheet<T>(
               context: context,
               builder: (sheetContext) => _SelectSheet<T>(
                 title: label,
                 options: options,
                 selected: field.value,
               ),
             );
             if (picked == null || picked == field.value) {
               return;
             }
             field.didChange(picked);
             onChanged?.call(picked);
           }

           return LabeledField(
             label: label,
             child: InkWell(
               borderRadius: const BorderRadius.all(Radius.circular(8)),
               onTap: onChanged == null ? null : () => unawaited(pick()),
               child: InputDecorator(
                 isEmpty: selected == null,
                 decoration: InputDecoration(
                   enabled: onChanged != null,
                   errorText: field.errorText,
                   suffixIcon: const Icon(Icons.expand_more, size: 20),
                 ),
                 child: Text(
                   selected?.label ?? '',
                   style: theme.textTheme.bodyLarge?.copyWith(
                     color: onChanged == null ? theme.disabledColor : null,
                   ),
                 ),
               ),
             ),
           );
         },
       );
}

class _SelectSheet<T> extends StatelessWidget {
  const _SelectSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<AppSelectOption<T>> options;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final option in options)
                  ListTile(
                    title: Text(
                      option.label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: option.value == selected
                            ? theme.colorScheme.primary
                            : null,
                        fontWeight: option.value == selected
                            ? FontWeight.w600
                            : null,
                      ),
                    ),
                    trailing: option.value == selected
                        ? Icon(Icons.check, color: theme.colorScheme.primary)
                        : null,
                    onTap: () => Navigator.of(context).pop(option.value),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
