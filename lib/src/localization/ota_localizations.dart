import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';
import 'ota_translation_repository.dart';

class OtaLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const OtaLocalizationsDelegate(this.repository);

  final OtaTranslationRepository repository;

  @override
  bool isSupported(Locale locale) =>
      const ['tr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final base = await AppLocalizations.delegate.load(locale);
    final bundle = await repository.load(locale.languageCode);
    return OtaAppLocalizations(base, bundle.values);
  }

  @override
  bool shouldReload(covariant OtaLocalizationsDelegate old) =>
      old.repository != repository;
}

class OtaAppLocalizations extends AppLocalizations {
  OtaAppLocalizations(this.base, this.values) : super(base.localeName);

  final AppLocalizations base;
  final Map<String, String> values;

  String value(String key, String fallback) {
    final override = values[key]?.trim();
    return override == null || override.isEmpty ? fallback : override;
  }

  String format(String key, String fallback, Map<String, String> replacements) {
    var result = value(key, fallback);
    for (final entry in replacements.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  @override
  String get appTitle => value('appTitle', base.appTitle);
  @override
  String get commonClose => value('commonClose', base.commonClose);
  @override
  String get commonBack => value('commonBack', base.commonBack);
  @override
  String get mealReviewTitle => value('mealReviewTitle', base.mealReviewTitle);
  @override
  String get mealComposeTitle =>
      value('mealComposeTitle', base.mealComposeTitle);
  @override
  String get mealComposeSubtitle =>
      value('mealComposeSubtitle', base.mealComposeSubtitle);
  @override
  String get mealInputHint => value('mealInputHint', base.mealInputHint);
  @override
  String get mealVoiceInput => value('mealVoiceInput', base.mealVoiceInput);
  @override
  String get mealQuickTry => value('mealQuickTry', base.mealQuickTry);
  @override
  String get mealQuickEggCheeseLabel =>
      value('mealQuickEggCheeseLabel', base.mealQuickEggCheeseLabel);
  @override
  String get mealQuickEggCheeseValue =>
      value('mealQuickEggCheeseValue', base.mealQuickEggCheeseValue);
  @override
  String get mealQuickYogurtLabel =>
      value('mealQuickYogurtLabel', base.mealQuickYogurtLabel);
  @override
  String get mealQuickYogurtValue =>
      value('mealQuickYogurtValue', base.mealQuickYogurtValue);
  @override
  String get mealAnalyze => value('mealAnalyze', base.mealAnalyze);
  @override
  String get mealAnalyzingFoods =>
      value('mealAnalyzingFoods', base.mealAnalyzingFoods);
  @override
  String get mealAnalyzingPortions =>
      value('mealAnalyzingPortions', base.mealAnalyzingPortions);
  @override
  String get mealAnalyzingAmbiguity =>
      value('mealAnalyzingAmbiguity', base.mealAnalyzingAmbiguity);
  @override
  String get mealCatalogNutrition =>
      value('mealCatalogNutrition', base.mealCatalogNutrition);
  @override
  String get mealTypeQuestion =>
      value('mealTypeQuestion', base.mealTypeQuestion);
  @override
  String get mealTypeExplanation =>
      value('mealTypeExplanation', base.mealTypeExplanation);
  @override
  String get yogurtWhole => value('yogurtWhole', base.yogurtWhole);
  @override
  String get yogurtStrained => value('yogurtStrained', base.yogurtStrained);
  @override
  String get yogurtLight => value('yogurtLight', base.yogurtLight);
  @override
  String get mealCheeseAmountQuestion =>
      value('mealCheeseAmountQuestion', base.mealCheeseAmountQuestion);
  @override
  String get mealCheeseAmountExplanation =>
      value('mealCheeseAmountExplanation', base.mealCheeseAmountExplanation);
  @override
  String get portionSmall => value('portionSmall', base.portionSmall);
  @override
  String get portionEstimate => value('portionEstimate', base.portionEstimate);
  @override
  String get portionLarge => value('portionLarge', base.portionLarge);
  @override
  String get portionExact => value('portionExact', base.portionExact);
  @override
  String mealMatchedCount(int count) => format(
    'mealMatchedCount',
    base.mealMatchedCount(count),
    {'count': '$count'},
  );
  @override
  String mealFoundCount(int count) =>
      format('mealFoundCount', base.mealFoundCount(count), {'count': '$count'});
  @override
  String get mealReadyToLog => value('mealReadyToLog', base.mealReadyToLog);
  @override
  String mealReviewImpactCount(int count) => format(
    'mealReviewImpactCount',
    base.mealReviewImpactCount(count),
    {'count': '$count'},
  );
  @override
  String get mealCheckAmount => value('mealCheckAmount', base.mealCheckAmount);
  @override
  String get mealCheckType => value('mealCheckType', base.mealCheckType);
  @override
  String get mealEstimatedTotal =>
      value('mealEstimatedTotal', base.mealEstimatedTotal);
  @override
  String get macroProtein => value('macroProtein', base.macroProtein);
  @override
  String get macroCarbs => value('macroCarbs', base.macroCarbs);
  @override
  String get macroFat => value('macroFat', base.macroFat);
  @override
  String get mealLog => value('mealLog', base.mealLog);
  @override
  String mealReviewPoints(int count) => format(
    'mealReviewPoints',
    base.mealReviewPoints(count),
    {'count': '$count'},
  );
  @override
  String get mealAddPhoto => value('mealAddPhoto', base.mealAddPhoto);
  @override
  String get mealCamera => value('mealCamera', base.mealCamera);
  @override
  String get mealGallery => value('mealGallery', base.mealGallery);
  @override
  String get mealPhotoSelected =>
      value('mealPhotoSelected', base.mealPhotoSelected);
  @override
  String get mealRemovePhoto => value('mealRemovePhoto', base.mealRemovePhoto);
  @override
  String get mealPhotoHint => value('mealPhotoHint', base.mealPhotoHint);
  @override
  String get mealPhotoError => value('mealPhotoError', base.mealPhotoError);
  @override
  String get mealPhotoTooLarge =>
      value('mealPhotoTooLarge', base.mealPhotoTooLarge);
  @override
  String get catalogSearchAction =>
      value('catalogSearchAction', base.catalogSearchAction);
  @override
  String get catalogSearchTitle =>
      value('catalogSearchTitle', base.catalogSearchTitle);
  @override
  String get catalogSearchExplanation =>
      value('catalogSearchExplanation', base.catalogSearchExplanation);
  @override
  String get catalogSearchHint =>
      value('catalogSearchHint', base.catalogSearchHint);
  @override
  String get catalogSearchEmpty =>
      value('catalogSearchEmpty', base.catalogSearchEmpty);
  @override
  String get catalogSearchError =>
      value('catalogSearchError', base.catalogSearchError);
}
