import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/features/backup/providers/backup_controller.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_primary_button.dart';
import 'package:flutter_wasilah_app/shared/widgets/confirm_dialog.dart';
import 'package:go_router/go_router.dart';

class BackupSection extends ConsumerWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupControllerProvider);
    final controller = ref.read(backupControllerProvider.notifier);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!state.isConnected) ...[
          Text(
            l10n.connectGoogleMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: l10n.connectGoogleButton,
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
                  state.accountEmail ?? l10n.connectedAccountFallback,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: state.isBusy
                    ? null
                    : () => _confirmDisconnect(context, controller),
                child: Text(l10n.disconnectButton),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.autoBackupLabel),
            value: state.autoBackupEnabled,
            onChanged: controller.setAutoBackupEnabled,
          ),
          Text(
            state.isRestoring
                ? l10n.restoringMessage
                : state.lastBackupAt == null
                ? l10n.neverBackedUpMessage
                : l10n.lastBackupMessage(
                    formatFullDateTime(
                      state.lastBackupAt!,
                      Localizations.localeOf(context),
                    ),
                  ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: l10n.backupNowButton,
            isLoading: state.isBackingUp,
            onPressed: state.isBusy
                ? null
                : () => _confirmBackup(context, controller),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppPrimaryButton(
            label: l10n.restoreFromBackupButton,
            onPressed: state.isBusy
                ? null
                : () => context.push(RouteNames.backupRestore),
          ),
        ],
        if (state.error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _describeError(l10n, state.error!),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  String _describeError(AppLocalizations l10n, Object error) {
    return switch (error) {
      GoogleConnectFailedException() => l10n.connectFailedMessage,
      BackupFailedException() => l10n.backupFailedMessage,
      GoogleNotConnectedException() => l10n.googleNotConnectedMessage,
      GoogleAuthorizationRequiredException() =>
        l10n.googleAuthorizationRequiredMessage,
      InvalidBackupFileException() => l10n.invalidBackupFileMessage,
      _ => l10n.backupFailedMessage,
    };
  }

  Future<void> _confirmBackup(
    BuildContext context,
    BackupController controller,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.confirmBackupTitle,
      message: l10n.confirmBackupMessage,
      confirmLabel: l10n.backupLabel,
    );
    if (confirmed) {
      await controller.backupNow();
    }
  }

  Future<void> _confirmDisconnect(
    BuildContext context,
    BackupController controller,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.confirmDisconnectTitle,
      message: l10n.confirmDisconnectMessage,
      confirmLabel: l10n.disconnectButton,
      isDestructive: true,
    );
    if (confirmed) {
      await controller.disconnect();
    }
  }
}
