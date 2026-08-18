import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/meal_repository.dart';
import '../catalog/food_catalog_repository.dart';
import '../domain/meal_analysis_input.dart';
import '../domain/models.dart';

enum MealFlowStep { compose, analyzing, review }

typedef ManualItemIdFactory = String Function();

class MealFlowViewModel extends ChangeNotifier {
  MealFlowViewModel({
    required MealRepository repository,
    FoodCatalogRepository? catalogRepository,
    ManualItemIdFactory? manualItemIdFactory,
  }) : _repository = repository,
       _catalogRepository = catalogRepository,
       _manualItemIdFactory = manualItemIdFactory ?? const Uuid().v4;

  final MealRepository _repository;
  final FoodCatalogRepository? _catalogRepository;
  final ManualItemIdFactory _manualItemIdFactory;

  MealFlowStep _step = MealFlowStep.compose;
  MealDraft? _draft;
  String? _error;
  MealAnalysisFailureKind? _errorKind;
  bool _manualSearchSuggested = false;
  bool _isSearchingCatalog = false;
  List<CatalogFoodCandidate> _catalogResults = const [];
  String? _catalogSearchError;

  MealFlowStep get step => _step;
  MealDraft? get draft => _draft;
  String? get error => _error;
  MealAnalysisFailureKind? get errorKind => _errorKind;
  bool get manualSearchSuggested => _manualSearchSuggested;
  bool get canSearchCatalog => _catalogRepository != null;
  bool get isSearchingCatalog => _isSearchingCatalog;
  List<CatalogFoodCandidate> get catalogResults => _catalogResults;
  String? get catalogSearchError => _catalogSearchError;

  Future<void> analyze(MealAnalysisInput input) async {
    if (input.isEmpty || _step == MealFlowStep.analyzing) return;
    final normalized = MealAnalysisInput(
      text: input.text.trim(),
      locale: input.locale,
      photo: input.photo,
    );
    _step = MealFlowStep.analyzing;
    _error = null;
    _errorKind = null;
    _manualSearchSuggested = false;
    notifyListeners();
    try {
      _draft = await _repository.analyze(normalized);
      _step = MealFlowStep.review;
    } on MealAnalysisException catch (error) {
      _error = _messageFor(error.kind);
      _errorKind = error.kind;
      _manualSearchSuggested = error.kind == MealAnalysisFailureKind.noMatch;
      _step = MealFlowStep.compose;
    } catch (_) {
      _error = 'Öğünü analiz edemedik. Bağlantını kontrol edip tekrar dene.';
      _errorKind = MealAnalysisFailureKind.unknown;
      _step = MealFlowStep.compose;
    }
    notifyListeners();
  }

  Future<void> searchCatalog(String query, String locale) async {
    final repository = _catalogRepository;
    if (repository == null || query.trim().length < 2 || _isSearchingCatalog) {
      return;
    }
    _isSearchingCatalog = true;
    _catalogSearchError = null;
    notifyListeners();
    try {
      _catalogResults = await repository.search(query: query, locale: locale);
    } catch (_) {
      _catalogSearchError = 'CATALOG_SEARCH_FAILED';
    } finally {
      _isSearchingCatalog = false;
      notifyListeners();
    }
  }

  void selectManualFood(CatalogFoodCandidate candidate, String sourceText) {
    final item = MealItem(
      id: _manualItemIdFactory(),
      foodId: candidate.foodId,
      name: naturalFoodDisplayName(candidate.name),
      canonicalName: candidate.name,
      sourceText: sourceText,
      portionLabel: candidate.defaultPortionLabel,
      grams: candidate.defaultGrams,
      nutritionPer100g: Nutrition(
        calories: candidate.caloriesPer100g,
        protein: candidate.proteinPer100g,
        carbs: candidate.carbsPer100g,
        fat: candidate.fatPer100g,
      ),
      matchState: MatchState.checkAmount,
      sourceName: candidate.nutritionSource,
      confidence: candidate.score,
      matchMethod: 'manual',
    );
    _draft = MealDraft(
      inputText: sourceText,
      mealName: _mealName(DateTime.now()),
      items: [item],
    );
    _step = MealFlowStep.review;
    _manualSearchSuggested = false;
    notifyListeners();
  }

  void addManualFood(CatalogFoodCandidate candidate, String sourceText) {
    final draft = _draft;
    if (draft == null) return;
    _draft = draft.addItem(
      MealItem(
        id: _manualItemIdFactory(),
        foodId: candidate.foodId,
        name: naturalFoodDisplayName(candidate.name),
        canonicalName: candidate.name,
        sourceText: sourceText,
        portionLabel: candidate.defaultPortionLabel,
        grams: candidate.defaultGrams,
        nutritionPer100g: Nutrition(
          calories: candidate.caloriesPer100g,
          protein: candidate.proteinPer100g,
          carbs: candidate.carbsPer100g,
          fat: candidate.fatPer100g,
        ),
        matchState: MatchState.checkAmount,
        sourceName: candidate.nutritionSource,
        confidence: candidate.score,
        matchMethod: 'manual',
      ),
    );
    notifyListeners();
  }

  String _messageFor(MealAnalysisFailureKind kind) {
    return switch (kind) {
      MealAnalysisFailureKind.noMatch =>
        'Bu yiyeceği katalogda güvenle eşleştiremedik. Daha açık tarif etmeyi dene.',
      MealAnalysisFailureKind.unauthenticated =>
        'Oturumun yenilenmeli. Tekrar giriş yapıp deneyebilirsin.',
      MealAnalysisFailureKind.invalidRequest =>
        'Açıklamayı anlayamadık. Daha kısa ve net yazmayı dene.',
      MealAnalysisFailureKind.rateLimited =>
        'Çok hızlı deneme yaptın. Biraz bekleyip tekrar dene.',
      MealAnalysisFailureKind.unavailable ||
      MealAnalysisFailureKind.invalidResponse ||
      MealAnalysisFailureKind.unknown =>
        'Öğünü analiz edemedik. Bağlantını kontrol edip tekrar dene.',
    };
  }

  void showComposer() {
    if (_step == MealFlowStep.compose) return;
    _step = MealFlowStep.compose;
    notifyListeners();
  }

  void updateItem(MealItem updated) {
    if (_draft == null) return;
    _draft = _draft!.updateItem(updated);
    notifyListeners();
  }

  void removeItem(String itemId) {
    if (_draft == null) return;
    _draft = _draft!.removeItem(itemId);
    notifyListeners();
  }

  String _mealName(DateTime time) {
    return switch (time.hour) {
      >= 5 && < 11 => 'Kahvaltı',
      >= 11 && < 16 => 'Öğle yemeği',
      >= 16 && < 22 => 'Akşam yemeği',
      _ => 'Atıştırma',
    };
  }
}
