import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/confirm_dialog.dart';

Future<bool> confirmDeleteHistory(BuildContext context) {
  final l10n = context.l10n;
  return showConfirmDialog(
    context,
    title: l10n.commonDeleteHistoryTitle,
    message: l10n.commonDeleteHistoryMessage,
    confirmLabel: l10n.commonDelete,
    isDestructive: true,
  );
}

/// Jalankan [delete] untuk baris histori yang sudah disembunyikan secara
/// optimistis; bila gagal, [onFailed] memunculkannya kembali.
Future<void> deleteHistoryEntry(
  BuildContext context, {
  required Future<void> Function() delete,
  required VoidCallback onFailed,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await delete();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.commonHistoryDeletedMessage)),
    );
  } on Object {
    if (!context.mounted) return;
    onFailed();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.commonDeleteHistoryFailedMessage)),
    );
  }
}
