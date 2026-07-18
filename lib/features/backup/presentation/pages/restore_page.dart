import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/features/backup/data/drive_backup_service.dart';
import 'package:flutter_wasilah_app/features/backup/providers/backup_controller.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_error_view.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Pulihkan dari backup')),
      body: backupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => AppErrorView(
          title: 'Daftar backup gagal dimuat',
          onRetry: () => ref.invalidate(_backupListProvider),
        ),
        data: (backups) {
          if (backups.isEmpty) {
            return const AppEmptyState(
              title: 'Belum ada backup',
              message: 'Backup pertama Anda akan muncul di sini.',
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
                title: Text(formatFullDateTime(backup.createdAt)),
                subtitle: Text(_formatFileSize(backup.sizeBytes)),
                onTap: () => _confirmRestore(context, ref, backup),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmRestore(
    BuildContext context,
    WidgetRef ref,
    DriveBackupFile backup,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pulihkan data ini?'),
        content: Text(
          'Data portofolio saat ini akan diganti dengan backup '
          '${formatFullDateTime(backup.createdAt)}. Tindakan ini tidak dapat '
          'dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Pulihkan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref.read(backupControllerProvider.notifier).restore(backup.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil dipulihkan.')),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pemulihan gagal. Coba lagi.')),
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
