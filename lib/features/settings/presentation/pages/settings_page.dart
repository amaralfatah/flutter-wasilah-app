import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/features/backup/presentation/widgets/backup_section.dart';
import 'package:flutter_wasilah_app/features/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter_wasilah_app/features/settings/providers/locale_provider.dart';
import 'package:flutter_wasilah_app/features/settings/providers/theme_mode_provider.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:go_router/go_router.dart';

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
            value: _themeModeLabel(l10n, themeMode),
            onTap: () => unawaited(
              _showThemeModePicker(context, ref, themeMode),
            ),
          ),
          const SettingsDivider(),
          SettingsTile(
            icon: Icons.language,
            title: l10n.settingsLanguageLabel,
            value: _localeLabel(l10n, locale),
            onTap: () => unawaited(_showLanguagePicker(context, ref, locale)),
          ),
          SettingsSectionHeader(l10n.settingsDataSection),
          SettingsTile(
            icon: Icons.inventory_2_outlined,
            title: 'Assets',
            onTap: () => unawaited(context.push(RouteNames.masterAssets)),
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

  void _updateThemeMode(WidgetRef ref, ThemeMode mode) {
    unawaited(ref.read(themeModeProvider.notifier).updateThemeMode(mode));
  }

  String _themeModeLabel(AppLocalizations l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
      ThemeMode.system => l10n.themeSystem,
    };
  }

  Future<void> _showThemeModePicker(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final l10n = context.l10n;

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: RadioGroup<ThemeMode>(
            groupValue: current,
            onChanged: (value) {
              if (value == null) return;
              _updateThemeMode(ref, value);
              Navigator.pop(sheetContext);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(l10n.themeSystem),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l10n.themeLight),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l10n.themeDark),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
        );
      },
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
