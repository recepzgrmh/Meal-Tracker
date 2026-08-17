import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal Clarity'**
  String get appTitle;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @mealReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review meal'**
  String get mealReviewTitle;

  /// No description provided for @mealComposeTitle.
  ///
  /// In en, this message translates to:
  /// **'What did you eat?'**
  String get mealComposeTitle;

  /// No description provided for @mealComposeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Describe it naturally. Add amounts if you know them; if not, we’ll clarify what matters.'**
  String get mealComposeSubtitle;

  /// No description provided for @mealInputHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2 eggs, some white cheese and half a bagel'**
  String get mealInputHint;

  /// No description provided for @mealVoiceInput.
  ///
  /// In en, this message translates to:
  /// **'Add by voice'**
  String get mealVoiceInput;

  /// No description provided for @mealQuickTry.
  ///
  /// In en, this message translates to:
  /// **'Quick try'**
  String get mealQuickTry;

  /// No description provided for @mealQuickEggCheeseLabel.
  ///
  /// In en, this message translates to:
  /// **'2 eggs · cheese · ½ bagel'**
  String get mealQuickEggCheeseLabel;

  /// No description provided for @mealQuickEggCheeseValue.
  ///
  /// In en, this message translates to:
  /// **'2 eggs, some white cheese and half a bagel'**
  String get mealQuickEggCheeseValue;

  /// No description provided for @mealQuickYogurtLabel.
  ///
  /// In en, this message translates to:
  /// **'A bowl of yogurt'**
  String get mealQuickYogurtLabel;

  /// No description provided for @mealQuickYogurtValue.
  ///
  /// In en, this message translates to:
  /// **'I ate a bowl of yogurt'**
  String get mealQuickYogurtValue;

  /// No description provided for @mealAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze meal'**
  String get mealAnalyze;

  /// No description provided for @mealAnalyzingFoods.
  ///
  /// In en, this message translates to:
  /// **'Finding foods'**
  String get mealAnalyzingFoods;

  /// No description provided for @mealAnalyzingPortions.
  ///
  /// In en, this message translates to:
  /// **'Matching portions'**
  String get mealAnalyzingPortions;

  /// No description provided for @mealAnalyzingAmbiguity.
  ///
  /// In en, this message translates to:
  /// **'Checking uncertainty'**
  String get mealAnalyzingAmbiguity;

  /// No description provided for @mealCatalogNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition will be calculated from the catalog.'**
  String get mealCatalogNutrition;

  /// No description provided for @mealTypeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which one was closest?'**
  String get mealTypeQuestion;

  /// No description provided for @mealTypeExplanation.
  ///
  /// In en, this message translates to:
  /// **'Choosing the correct food directly affects calories and macros.'**
  String get mealTypeExplanation;

  /// No description provided for @yogurtWhole.
  ///
  /// In en, this message translates to:
  /// **'Whole milk yogurt'**
  String get yogurtWhole;

  /// No description provided for @yogurtStrained.
  ///
  /// In en, this message translates to:
  /// **'Strained yogurt'**
  String get yogurtStrained;

  /// No description provided for @yogurtLight.
  ///
  /// In en, this message translates to:
  /// **'Light yogurt'**
  String get yogurtLight;

  /// No description provided for @mealCheeseAmountQuestion.
  ///
  /// In en, this message translates to:
  /// **'How much cheese was it?'**
  String get mealCheeseAmountQuestion;

  /// No description provided for @mealCheeseAmountExplanation.
  ///
  /// In en, this message translates to:
  /// **'We estimated 30 g. Choose the closest amount.'**
  String get mealCheeseAmountExplanation;

  /// No description provided for @portionSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get portionSmall;

  /// No description provided for @portionEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get portionEstimate;

  /// No description provided for @portionLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get portionLarge;

  /// No description provided for @portionExact.
  ///
  /// In en, this message translates to:
  /// **'Enter exact amount'**
  String get portionExact;

  /// No description provided for @mealMatchedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 food matched} other{{count} foods matched}}'**
  String mealMatchedCount(int count);

  /// No description provided for @mealFoundCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{We found 1 food} other{We found {count} foods}}'**
  String mealFoundCount(int count);

  /// No description provided for @mealReadyToLog.
  ///
  /// In en, this message translates to:
  /// **'Everything is ready. Review once more before logging.'**
  String get mealReadyToLog;

  /// No description provided for @mealReviewImpactCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 detail may affect the result.} other{{count} details may affect the result.}}'**
  String mealReviewImpactCount(int count);

  /// No description provided for @mealCheckAmount.
  ///
  /// In en, this message translates to:
  /// **'Check amount'**
  String get mealCheckAmount;

  /// No description provided for @mealCheckType.
  ///
  /// In en, this message translates to:
  /// **'Check type'**
  String get mealCheckType;

  /// No description provided for @mealEstimatedTotal.
  ///
  /// In en, this message translates to:
  /// **'Estimated total'**
  String get mealEstimatedTotal;

  /// No description provided for @macroProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get macroProtein;

  /// No description provided for @macroCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get macroCarbs;

  /// No description provided for @macroFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get macroFat;

  /// No description provided for @mealLog.
  ///
  /// In en, this message translates to:
  /// **'Log meal'**
  String get mealLog;

  /// No description provided for @mealReviewPoints.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Review 1 detail} other{Review {count} details}}'**
  String mealReviewPoints(int count);

  /// No description provided for @mealAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add meal photo'**
  String get mealAddPhoto;

  /// No description provided for @mealCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get mealCamera;

  /// No description provided for @mealGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get mealGallery;

  /// No description provided for @mealPhotoSelected.
  ///
  /// In en, this message translates to:
  /// **'Meal photo selected'**
  String get mealPhotoSelected;

  /// No description provided for @mealRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get mealRemovePhoto;

  /// No description provided for @mealPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Add a clear overhead photo. A short description improves accuracy.'**
  String get mealPhotoHint;

  /// No description provided for @mealPhotoError.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t open that photo. Try another one.'**
  String get mealPhotoError;

  /// No description provided for @mealPhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That photo is too large. Choose one under 8 MB.'**
  String get mealPhotoTooLarge;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
