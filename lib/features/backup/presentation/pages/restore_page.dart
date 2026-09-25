import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/features/backup/data/drive_backup_service.dart';
import 'package:flutter_wasilah_app/features/backup/providers/backup_controller.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_error_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_loading.dart';
import 'package:flutter_wasilah_app/shared/widgets/confirm_dialog.dart';

final AutoDisposeFutureProvider<List<DriveBackupFile>> _backupListProvider =
    FutureProvider.autoDispose<List<DriveBackupFile>>((
      ref,
    ) {
      return ref.read(backupControllerProvider.notifier).listBackups();
    });

class RestorePage extends ConsumerWidget {
  const RestorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupsAsync = ref.watch(_backupListProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.restoreTitle)),
      body: SafeArea(
        child: backupsAsync.when(
          loading: () => const AppLoading(),
          error: (error, stackTrace) => AppErrorView(
            title: l10n.backupListLoadFailedTitle,
            onRetry: () => ref.invalidate(_backupListProvider),
          ),
          data: (backups) {
            if (backups.isEmpty) {
              return AppEmptyState(
                title: l10n.emptyBackupTitle,
                message: l10n.emptyBackupMessage,
                icon: Icons.cloud_off_outlined,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: backups.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final backup = backups[index];
                return ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(
                    formatFullDateTime(
                      backup.createdAt,
                      Localizations.localeOf(context),
                    ),
                  ),
                  subtitle: Text(_formatFileSize(backup.sizeBytes)),
                  onTap: () => _confirmRestore(context, ref, backup),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmRestore(
    BuildContext context,
    WidgetRef ref,
    DriveBackupFile backup,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.restoreDataTitle,
      message: l10n.restoreDataMessage(
        formatFullDateTime(backup.createdAt, Localizations.localeOf(context)),
      ),
      confirmLabel: l10n.restoreLabel,
      isDestructive: true,
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      await ref.read(backupControllerProvider.notifier).restore(backup.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.restoreSuccessMessage)),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.restoreFailedMessage)),
        );
      }
    }
  }
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
