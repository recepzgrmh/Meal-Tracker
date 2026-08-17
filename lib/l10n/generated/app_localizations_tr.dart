// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Meal Clarity';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonBack => 'Geri';

  @override
  String get mealReviewTitle => 'Öğünü kontrol et';

  @override
  String get mealComposeTitle => 'Ne yedin?';

  @override
  String get mealComposeSubtitle =>
      'Günlük konuşur gibi anlat. Miktarları biliyorsan ekle; bilmiyorsan önemli noktaları birlikte netleştiririz.';

  @override
  String get mealInputHint =>
      'Örn. 2 yumurta, biraz beyaz peynir ve yarım simit';

  @override
  String get mealVoiceInput => 'Sesle ekle';

  @override
  String get mealQuickTry => 'Hızlı dene';

  @override
  String get mealQuickEggCheeseLabel => '2 yumurta · peynir · ½ simit';

  @override
  String get mealQuickEggCheeseValue =>
      '2 yumurta, biraz beyaz peynir ve yarım simit';

  @override
  String get mealQuickYogurtLabel => 'Bir kase yoğurt';

  @override
  String get mealQuickYogurtValue => 'Bir kase yoğurt yedim';

  @override
  String get mealAnalyze => 'Öğünü analiz et';

  @override
  String get mealAnalyzingFoods => 'Yiyecekler bulunuyor';

  @override
  String get mealAnalyzingPortions => 'Porsiyonlar eşleştiriliyor';

  @override
  String get mealAnalyzingAmbiguity => 'Belirsizlikler kontrol ediliyor';

  @override
  String get mealCatalogNutrition => 'Besin değerleri katalogdan hesaplanacak.';

  @override
  String get mealTypeQuestion => 'Hangisine daha yakındı?';

  @override
  String get mealTypeExplanation =>
      'Doğru gıdayı seçmek kalori ve makroları doğrudan etkiler.';

  @override
  String get yogurtWhole => 'Tam yağlı yoğurt';

  @override
  String get yogurtStrained => 'Süzme yoğurt';

  @override
  String get yogurtLight => 'Light yoğurt';

  @override
  String get mealCheeseAmountQuestion => 'Peynir ne kadardı?';

  @override
  String get mealCheeseAmountExplanation =>
      '30 g tahmin ettik. En yakın miktarı seçebilirsin.';

  @override
  String get portionSmall => 'Az';

  @override
  String get portionEstimate => 'Tahmin';

  @override
  String get portionLarge => 'Fazla';

  @override
  String get portionExact => 'Tam miktar gir';

  @override
  String mealMatchedCount(int count) {
    return '$count yiyecek eşleşti';
  }

  @override
  String mealFoundCount(int count) {
    return '$count yiyecek bulduk';
  }

  @override
  String get mealReadyToLog =>
      'Her şey hazır. Kaydetmeden önce son kez kontrol et.';

  @override
  String mealReviewImpactCount(int count) {
    return '$count nokta sonucu etkileyebilir.';
  }

  @override
  String get mealCheckAmount => 'Miktarı kontrol et';

  @override
  String get mealCheckType => 'Türü kontrol et';

  @override
  String get mealEstimatedTotal => 'Tahmini toplam';

  @override
  String get macroProtein => 'Protein';

  @override
  String get macroCarbs => 'Karbonhidrat';

  @override
  String get macroFat => 'Yağ';

  @override
  String get mealLog => 'Öğünü kaydet';

  @override
  String mealReviewPoints(int count) {
    return '$count noktayı kontrol et';
  }

  @override
  String get mealAddPhoto => 'Öğün fotoğrafı ekle';

  @override
  String get mealCamera => 'Fotoğraf çek';

  @override
  String get mealGallery => 'Galeriden seç';

  @override
  String get mealPhotoSelected => 'Öğün fotoğrafı seçildi';

  @override
  String get mealRemovePhoto => 'Fotoğrafı kaldır';

  @override
  String get mealPhotoHint =>
      'Net ve üstten çekilmiş bir fotoğraf ekle. Kısa bir açıklama doğruluğu artırır.';

  @override
  String get mealPhotoError =>
      'Bu fotoğrafı açamadık. Başka bir fotoğraf dene.';

  @override
  String get mealPhotoTooLarge =>
      'Fotoğraf çok büyük. 8 MB\'den küçük bir fotoğraf seç.';
}
