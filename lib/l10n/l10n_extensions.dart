import 'package:flutter/widgets.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';

extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
