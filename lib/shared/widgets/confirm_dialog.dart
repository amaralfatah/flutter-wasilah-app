import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';

/// Dialog konfirmasi tunggal untuk seluruh app.
///
/// Aksi merusak ditandai lewat [isDestructive] supaya tombolnya memakai warna
/// error. Tanpa pembeda itu "Hapus" terlihat sama netral dengan "Batal", dan
/// tiap layar sempat menulis dialognya sendiri dengan gaya berbeda-beda.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool isDestructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;

      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel ?? context.l10n.dialogCancel),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}
