import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';
import '../src/localization/ota_localizations.dart';

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('tr'));

  /// Resolves copy that is not represented by a generated ARB getter yet.
  /// Every user-visible string can therefore use the same OTA bundle while
  /// retaining an offline-safe Turkish/English fallback in the binary.
  String ota(
    String key, {
    required String tr,
    required String en,
    Map<String, Object> replacements = const {},
  }) {
    final localizations = l10n;
    final fallback = localizations.localeName.startsWith('tr') ? tr : en;
    final values = replacements.map(
      (name, value) => MapEntry(name, value.toString()),
    );
    return localizations is OtaAppLocalizations
        ? localizations.format(key, fallback, values)
        : values.entries.fold(
            fallback,
            (result, entry) => result.replaceAll('{${entry.key}}', entry.value),
          );
  }
}
