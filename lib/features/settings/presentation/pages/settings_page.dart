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
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SettingsSectionHeader('Tampilan'),
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
                  child: const AboutListTile(
                    icon: Icon(Icons.info_outline),
                    applicationName: 'Wasilah',
                    applicationVersion: _appVersion,
                    child: Text('Tentang aplikasi'),
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
