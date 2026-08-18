import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/l10n/generated/app_localizations_en.dart';
import 'package:meal_clarity/l10n/generated/app_localizations.dart';
import 'package:meal_clarity/src/localization/ota_localizations.dart';
import 'package:meal_clarity/src/localization/ota_translation_repository.dart';
import 'package:meal_clarity/l10n/l10n.dart';

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

  testWidgets('generic mobile copy keys are OTA overridable', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [
          OtaLocalizationsDelegate(
            _FixtureTranslations({'todayTitle': 'OTA Today'}),
          ),
          ...AppLocalizations.localizationsDelegates.skip(1),
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(captured.ota('todayTitle', tr: 'Bugün', en: 'Today'), 'OTA Today');
  });
}

class _FixtureTranslations implements OtaTranslationRepository {
  const _FixtureTranslations(this.values);
  final Map<String, String> values;

  @override
  Future<OtaTranslationBundle> load(String locale) async =>
      OtaTranslationBundle(version: 1, values: values);
}
