import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/features/backup/presentation/widgets/backup_section.dart';
import 'package:flutter_wasilah_app/features/settings/providers/locale_provider.dart';
import 'package:flutter_wasilah_app/features/settings/providers/theme_mode_provider.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _appVersion = '1.0.0+1';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SettingsSectionHeader(l10n.settingsDisplaySection),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    // Ikon centang bawaan M3 merebut ~30dp ruang label pada
                    // segmen terpilih, membuat teksnya membungkus. Warna
                    // segmen sudah cukup menandakan pilihan aktif.
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        label: Text(l10n.themeSystem),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        label: Text(l10n.themeLight),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        label: Text(l10n.themeDark),
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
                _SettingsSectionHeader(l10n.settingsLanguageSection),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<Locale?>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment<Locale?>(
                        value: null,
                        label: Text(l10n.themeSystem),
                      ),
                      ButtonSegment<Locale?>(
                        value: const Locale('id'),
                        label: Text(l10n.languageIndonesian),
                      ),
                      ButtonSegment<Locale?>(
                        value: const Locale('en'),
                        label: Text(l10n.languageEnglish),
                      ),
                    ],
                    selected: {locale},
                    onSelectionChanged: (selection) {
                      _updateLocale(ref, selection.firstOrNull);
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
                _SettingsSectionHeader(l10n.settingsBackupSection),
                const SizedBox(height: AppSpacing.md),
                const BackupSection(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SettingsSectionHeader(l10n.settingsAppSection),
                const SizedBox(height: AppSpacing.sm),
                ListTileTheme(
                  data: const ListTileThemeData(
                    contentPadding: EdgeInsets.zero,
                  ),
                  child: AboutListTile(
                    icon: const Icon(Icons.info_outline),
                    applicationName: 'Wasilah',
                    applicationVersion: _appVersion,
                    child: Text(l10n.settingsAboutApp),
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

  void _updateLocale(WidgetRef ref, Locale? value) {
    ref.read(localeProvider.notifier).updateLocale(value);
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
      ),
    );
  }
}
