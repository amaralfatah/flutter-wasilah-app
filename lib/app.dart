import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/app_router.dart';
import 'package:flutter_wasilah_app/core/theme/app_theme.dart';
import 'package:flutter_wasilah_app/features/backup/providers/backup_controller.dart';
import 'package:flutter_wasilah_app/features/settings/providers/locale_provider.dart';
import 'package:flutter_wasilah_app/features/settings/providers/theme_mode_provider.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  // `resumed` juga terpicu saat kembali dari dialog sistem — termasuk bottom
  // sheet Google Sign-In dan share sheet. Hanya perlakukan sebagai "buka
  // aplikasi" kalau app benar-benar sempat masuk background.
  bool _wasPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(backupControllerProvider.notifier).maybeAutoBackup());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _wasPaused = true;
      return;
    }
    if (state == AppLifecycleState.resumed && _wasPaused) {
      _wasPaused = false;
      unawaited(ref.read(backupControllerProvider.notifier).maybeAutoBackup());
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Wasilah',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
