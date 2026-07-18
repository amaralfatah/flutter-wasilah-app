import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/features/backup/providers/backup_controller.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_primary_button.dart';
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
                  state.accountEmail ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: state.isBusy ? null : controller.disconnect,
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
                : 'Backup terakhir: ${formatFullDate(state.lastBackupAt!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: 'Backup sekarang',
            isLoading: state.isBackingUp,
            onPressed: state.isBusy ? null : controller.backupNow,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppPrimaryButton(
            label: 'Pulihkan dari backup',
            isFullWidth: true,
            onPressed: state.isBusy
                ? null
                : () => context.push(RouteNames.backupRestore),
          ),
        ],
        if (state.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            state.errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
