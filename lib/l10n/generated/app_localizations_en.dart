// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Meal Clarity';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get mealReviewTitle => 'Review meal';

  @override
  String get mealComposeTitle => 'What did you eat?';

  @override
  String get mealComposeSubtitle =>
      'Describe it naturally. Add amounts if you know them; if not, we’ll clarify what matters.';

  @override
  String get mealInputHint => 'e.g. 2 eggs, some white cheese and half a bagel';

  @override
  String get mealVoiceInput => 'Add by voice';

  @override
  String get mealQuickTry => 'Quick try';

  @override
  String get mealQuickEggCheeseLabel => '2 eggs · cheese · ½ bagel';

  @override
  String get mealQuickEggCheeseValue =>
      '2 eggs, some white cheese and half a bagel';

  @override
  String get mealQuickYogurtLabel => 'A bowl of yogurt';

  @override
  String get mealQuickYogurtValue => 'I ate a bowl of yogurt';

  @override
  String get mealAnalyze => 'Analyze meal';

  @override
  String get mealAnalyzingFoods => 'Finding foods';

  @override
  String get mealAnalyzingPortions => 'Matching portions';

  @override
  String get mealAnalyzingAmbiguity => 'Checking uncertainty';

  @override
  String get mealCatalogNutrition =>
      'Nutrition will be calculated from the catalog.';

  @override
  String get mealTypeQuestion => 'Which one was closest?';

  @override
  String get mealTypeExplanation =>
      'Choosing the correct food directly affects calories and macros.';

  @override
  String get yogurtWhole => 'Whole milk yogurt';

  @override
  String get yogurtStrained => 'Strained yogurt';

  @override
  String get yogurtLight => 'Light yogurt';

  @override
  String get mealCheeseAmountQuestion => 'How much cheese was it?';

  @override
  String get mealCheeseAmountExplanation =>
      'We estimated 30 g. Choose the closest amount.';

  @override
  String get portionSmall => 'Small';

  @override
  String get portionEstimate => 'Estimate';

  @override
  String get portionLarge => 'Large';

  @override
  String get portionExact => 'Enter exact amount';

  @override
  String mealMatchedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foods matched',
      one: '1 food matched',
    );
    return '$_temp0';
  }

  @override
  String mealFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'We found $count foods',
      one: 'We found 1 food',
    );
    return '$_temp0';
  }

  @override
  String get mealReadyToLog =>
      'Everything is ready. Review once more before logging.';

  @override
  String mealReviewImpactCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count details may affect the result.',
      one: '1 detail may affect the result.',
    );
    return '$_temp0';
  }

  @override
  String get mealCheckAmount => 'Check amount';

  @override
  String get mealCheckType => 'Check type';

  @override
  String get mealEstimatedTotal => 'Estimated total';

  @override
  String get macroProtein => 'Protein';

  @override
  String get macroCarbs => 'Carbs';

  @override
  String get macroFat => 'Fat';

  @override
  String get mealLog => 'Log meal';

  @override
  String mealReviewPoints(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Review $count details',
      one: 'Review 1 detail',
    );
    return '$_temp0';
  }
}
