import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/l10n/generated/app_localizations_en.dart';
import 'package:meal_clarity/src/localization/ota_localizations.dart';

void main() {
  test('OTA values override bundled copy and interpolate placeholders', () {
    final localizations = OtaAppLocalizations(AppLocalizationsEn(), const {
      'mealComposeTitle': 'Log your meal',
      'mealFoundCount': 'Found {count} catalog foods',
    });

    expect(localizations.mealComposeTitle, 'Log your meal');
    expect(localizations.mealFoundCount(3), 'Found 3 catalog foods');
    expect(localizations.mealAnalyze, 'Analyze meal');
  });

  test('empty OTA values fail closed to bundled ARB copy', () {
    final localizations = OtaAppLocalizations(AppLocalizationsEn(), const {
      'mealComposeTitle': '   ',
    });

    expect(localizations.mealComposeTitle, 'What did you eat?');
  });
}
