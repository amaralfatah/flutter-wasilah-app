import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/features/backup/providers/backup_controller.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_primary_button.dart';
import 'package:flutter_wasilah_app/shared/widgets/confirm_dialog.dart';
import 'package:go_router/go_router.dart';

class BackupSection extends ConsumerWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupControllerProvider);
    final controller = ref.read(backupControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!state.isConnected) ...[
          Text(
            'Hubungkan akun Google untuk mem-backup data portofolio Anda.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: 'Hubungkan akun Google',
            isLoading:
                state.connectionStatus == BackupConnectionStatus.connecting,
            onPressed: controller.connect,
          ),
        ] else ...[
          Row(
            children: [
              const Icon(Icons.account_circle_outlined),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  // Status terhubung dipulihkan dari preferences tanpa
                  // sign-in ulang, jadi email bisa kosong untuk sesi yang
                  // tersambung sebelum email ikut disimpan. Baris kosong
                  // terbaca seperti bug.
                  state.accountEmail ?? 'Akun Google terhubung',
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: state.isBusy
                    ? null
                    : () => _confirmDisconnect(context, controller),
                child: const Text('Putuskan'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Backup otomatis'),
            value: state.autoBackupEnabled,
            onChanged: controller.setAutoBackupEnabled,
          ),
          Text(
            state.isRestoring
                ? 'Sedang memulihkan data...'
                : state.lastBackupAt == null
                ? 'Belum pernah backup.'
                : 'Backup terakhir: ${formatFullDateTime(state.lastBackupAt!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: 'Backup sekarang',
            isLoading: state.isBackingUp,
            onPressed: state.isBusy
                ? null
                : () => _confirmBackup(context, controller),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppPrimaryButton(
            label: 'Pulihkan dari backup',
            onPressed: state.isBusy
                ? null
                : () => context.push(RouteNames.backupRestore),
          ),
        ],
        if (state.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            state.errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmBackup(
    BuildContext context,
    BackupController controller,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Backup sekarang?',
      message:
          'Salinan data portofolio saat ini akan diunggah ke Google Drive '
          'dan menghitung ulang jadwal backup otomatis berikutnya.',
      confirmLabel: 'Backup',
    );
    if (confirmed) {
      await controller.backupNow();
    }
  }

  Future<void> _confirmDisconnect(
    BuildContext context,
    BackupController controller,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Putuskan akun Google?',
      message:
          'Backup otomatis akan berhenti dan aplikasi tidak lagi punya akses '
          'ke Google Drive. Data di perangkat dan backup yang sudah ada '
          'tidak dihapus.',
      confirmLabel: 'Putuskan',
      isDestructive: true,
    );
    if (confirmed) {
      await controller.disconnect();
    }
  }
}
