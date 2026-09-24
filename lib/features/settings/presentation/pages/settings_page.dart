import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/features/backup/presentation/widgets/backup_section.dart';
import 'package:flutter_wasilah_app/features/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter_wasilah_app/features/settings/providers/locale_provider.dart';
import 'package:flutter_wasilah_app/features/settings/providers/theme_mode_provider.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';

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
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          SettingsSectionHeader(l10n.settingsDisplaySection),
          SettingsTile(
            icon: Icons.contrast,
            title: l10n.settingsDarkMode,
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (isDark) => _updateTheme(ref, isDark),
            ),
            onTap: () => _updateTheme(ref, themeMode != ThemeMode.dark),
          ),
          const SettingsDivider(),
          SettingsTile(
            icon: Icons.language,
            title: l10n.settingsLanguageLabel,
            value: _localeLabel(l10n, locale),
            onTap: () => unawaited(_showLanguagePicker(context, ref, locale)),
          ),
          SettingsSectionHeader(l10n.settingsBackupSection),
          const BackupSection(),
          SettingsSectionHeader(l10n.settingsAppSection),
          SettingsTile(
            icon: Icons.info_outline,
            title: l10n.settingsAboutApp,
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Wasilah',
              applicationVersion: _appVersion,
            ),
          ),
        ],
      ),
    );
  }

  void _updateTheme(WidgetRef ref, bool isDark) {
    unawaited(
      ref
          .read(themeModeProvider.notifier)
          .updateThemeMode(isDark ? ThemeMode.dark : ThemeMode.light),
    );
  }

  void _updateLocale(WidgetRef ref, Locale? value) {
    unawaited(ref.read(localeProvider.notifier).updateLocale(value));
  }

  String _localeLabel(AppLocalizations l10n, Locale? locale) {
    return switch (locale?.languageCode) {
      'id' => l10n.languageIndonesian,
      'en' => l10n.languageEnglish,
      _ => l10n.themeSystem,
    };
  }

  Future<void> _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
    Locale? current,
  ) async {
    final l10n = context.l10n;

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: RadioGroup<Locale?>(
            groupValue: current,
            onChanged: (value) {
              _updateLocale(ref, value);
              Navigator.pop(sheetContext);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<Locale?>(
                  title: Text(l10n.themeSystem),
                  value: null,
                ),
                RadioListTile<Locale?>(
                  title: Text(l10n.languageIndonesian),
                  value: const Locale('id'),
                ),
                RadioListTile<Locale?>(
                  title: Text(l10n.languageEnglish),
                  value: const Locale('en'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
