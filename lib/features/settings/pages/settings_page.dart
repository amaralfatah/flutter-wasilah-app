import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/app/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/widgets/app_card.dart';
import 'package:flutter_wasilah_app/features/settings/providers/theme_mode_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _appVersion = '1.0.0+1';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Setelan')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(
            'Kelola preferensi tampilan dan informasi dasar aplikasi.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SettingsSectionHeader('Tampilan'),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Mode tema',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pilih tampilan aplikasi yang paling nyaman digunakan.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        label: Text('Sistem'),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        label: Text('Terang'),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        label: Text('Gelap'),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (selection) {
                      _updateTheme(ref, selection.firstOrNull);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SettingsSectionHeader('Aplikasi'),
                const SizedBox(height: AppSpacing.sm),
                ListTileTheme(
                  data: const ListTileThemeData(
                    contentPadding: EdgeInsets.zero,
                  ),
                  child: Column(
                    children: const [
                      AboutListTile(
                        icon: Icon(Icons.info_outline),
                        applicationName: 'Wasilah',
                        applicationVersion: _appVersion,
                        applicationLegalese:
                            'Memantau total nilai aset secara berkala.',
                        child: Text('Tentang aplikasi'),
                      ),
                      Divider(height: AppSpacing.lg),
                      _InfoSettingTile(
                        icon: Icons.verified_outlined,
                        title: 'Versi aplikasi',
                        subtitle: _appVersion,
                      ),
                      Divider(height: AppSpacing.lg),
                      _InfoSettingTile(
                        icon: Icons.cloud_sync_outlined,
                        title: 'Backup Google Drive',
                        subtitle: 'Segera hadir',
                        supportingText:
                            'Pencadangan cloud akan ditambahkan pada pembaruan berikutnya.',
                      ),
                      Divider(height: AppSpacing.lg),
                      _InfoSettingTile(
                        icon: Icons.logout_outlined,
                        title: 'Keluar',
                        subtitle: 'Segera hadir',
                        supportingText:
                            'Opsi ini aktif setelah autentikasi akun tersedia.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateTheme(WidgetRef ref, ThemeMode? value) {
    if (value == null) {
      return;
    }

    ref.read(themeModeProvider.notifier).updateThemeMode(value);
  }
}

class _InfoSettingTile extends StatelessWidget {
  const _InfoSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.supportingText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? supportingText;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        supportingText == null ? subtitle : '$subtitle\n$supportingText',
      ),
      isThreeLine: supportingText != null,
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
