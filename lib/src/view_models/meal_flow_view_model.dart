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
  MealAnalysisFailureKind? _errorKind;
  bool _manualSearchSuggested = false;
  bool _isSearchingCatalog = false;
  List<CatalogFoodCandidate> _catalogResults = const [];
  String? _catalogSearchError;
  bool _isSearchingVariants = false;
  List<CatalogFoodCandidate> _variantResults = const [];
  String? _variantSearchError;

  /// Bumped whenever the user leaves the analyzing step. An in-flight
  /// `analyze()` compares its own generation on completion and drops its result
  /// when it is stale, so a late response can no longer yank the user out of
  /// the composer they deliberately went back to.
  int _analysisGeneration = 0;

  MealFlowStep get step => _step;
  MealDraft? get draft => _draft;
  MealAnalysisFailureKind? get errorKind => _errorKind;
  bool get manualSearchSuggested => _manualSearchSuggested;
  bool get canSearchCatalog => _catalogRepository != null;
  bool get isSearchingCatalog => _isSearchingCatalog;
  List<CatalogFoodCandidate> get catalogResults => _catalogResults;
  String? get catalogSearchError => _catalogSearchError;
  bool get isSearchingVariants => _isSearchingVariants;
  List<CatalogFoodCandidate> get variantResults => _variantResults;
  String? get variantSearchError => _variantSearchError;

  Future<void> analyze(MealAnalysisInput input) async {
    if (input.isEmpty || _step == MealFlowStep.analyzing) return;
    final normalized = MealAnalysisInput(
      text: input.text.trim(),
      locale: input.locale,
      photo: input.photo,
    );
    final generation = _analysisGeneration;
    _step = MealFlowStep.analyzing;
    _errorKind = null;
    _manualSearchSuggested = false;
    notifyListeners();
    try {
      final draft = await _repository.analyze(normalized);
      if (generation != _analysisGeneration) return;
      _draft = draft;
      _step = MealFlowStep.review;
    } on MealAnalysisException catch (error) {
      if (generation != _analysisGeneration) return;
      _errorKind = error.kind;
      _manualSearchSuggested = error.kind == MealAnalysisFailureKind.noMatch;
      _step = MealFlowStep.compose;
    } catch (_) {
      if (generation != _analysisGeneration) return;
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

  /// Loads the catalog entries the "which type?" question can actually offer
  /// for [item]. Kept in fields of its own so an open variant sheet and the
  /// manual search sheet never overwrite each other's results.
  Future<void> searchItemVariants(MealItem item, String locale) async {
    final repository = _catalogRepository;
    if (repository == null || _isSearchingVariants) return;
    // The user's own words, not the match we are asking them to correct.
    //
    // Seeding from `canonicalName` meant the sheet searched for whatever the
    // pipeline had already picked, so a wrong match produced alternatives that
    // were wrong in the same direction — matching "makarna" to a low-protein
    // gluten-free PKU row returned PKU flour and PKU biscuits as the things it
    // "could have been". The one question this sheet exists to answer is what
    // the user actually ate, so it searches what they actually wrote.
    final query = item.sourceText.trim().isNotEmpty
        ? item.sourceText.trim()
        : item.canonicalName.trim();
    _isSearchingVariants = true;
    _variantSearchError = null;
    _variantResults = const [];
    notifyListeners();
    try {
      _variantResults = query.length < 2
          ? const []
          : _preferAlternatives(
              await repository.search(query: query, locale: locale),
              item.alternativeFoodIds,
            );
    } catch (_) {
      _variantSearchError = 'CATALOG_SEARCH_FAILED';
    } finally {
      _isSearchingVariants = false;
      notifyListeners();
    }
  }

  void selectManualFood(
    CatalogFoodCandidate candidate,
    String sourceText, {
    required String mealName,
  }) {
    final item = _manualItem(candidate, sourceText);
    final draft = _draft;
    // A manual correction used to throw away everything already analyzed; it
    // only starts a draft when there is nothing to add to.
    _draft = draft == null
        ? MealDraft(inputText: sourceText, mealName: mealName, items: [item])
        : draft.addItem(item);
    _step = MealFlowStep.review;
    _manualSearchSuggested = false;
    notifyListeners();
  }

  void addManualFood(CatalogFoodCandidate candidate, String sourceText) {
    final draft = _draft;
    if (draft == null) return;
    _draft = draft.addItem(_manualItem(candidate, sourceText));
    notifyListeners();
  }

  /// Swaps [target] for a catalog food picked by hand.
  ///
  /// Built for AI-estimate rows: the estimate keeps the meal loggable, but a
  /// real catalog match is strictly better, so the correction replaces the
  /// guess instead of adding a duplicate beside it. The row keeps its id and
  /// analyzer item key (the commit diffs corrections by that key) and drops
  /// the estimate id — the item is catalog-grounded from here on.
  void replaceWithManualFood(
    MealItem target,
    CatalogFoodCandidate candidate,
    String sourceText,
  ) {
    final draft = _draft;
    if (draft == null) return;
    final manual = _manualItem(candidate, sourceText);
    _draft = draft.updateItem(
      MealItem(
        id: target.id,
        analysisItemKey: target.analysisItemKey,
        foodId: manual.foodId,
        name: manual.displayName,
        canonicalName: manual.canonicalName,
        sourceText: manual.sourceText,
        portionLabel: manual.portionLabel,
        grams: manual.grams,
        nutritionPer100g: manual.nutritionPer100g,
        matchState: manual.matchState,
        sourceName: manual.sourceName,
        confidence: manual.confidence,
        matchMethod: manual.matchMethod,
      ),
    );
    notifyListeners();
  }

  /// Server-suggested identity alternatives lead the variant list; everything
  /// else keeps the retrieval order behind them.
  List<CatalogFoodCandidate> _preferAlternatives(
    List<CatalogFoodCandidate> results,
    List<String> alternativeFoodIds,
  ) {
    if (alternativeFoodIds.isEmpty) return results;
    final byId = {for (final candidate in results) candidate.foodId: candidate};
    final leading = [
      for (final foodId in alternativeFoodIds) ?byId[foodId],
    ];
    final leadingIds = {for (final candidate in leading) candidate.foodId};
    return [
      ...leading,
      ...results.where((candidate) => !leadingIds.contains(candidate.foodId)),
    ];
  }

  MealItem _manualItem(CatalogFoodCandidate candidate, String sourceText) =>
      MealItem(
        id: _manualItemIdFactory(),
        foodId: candidate.foodId,
        name: naturalFoodDisplayName(candidate.name),
        canonicalName: candidate.name,
        sourceText: sourceText,
        // A catalog food may carry no published portion. Falling back to the
        // 100 g basis the nutrition is already expressed in keeps the item
        // arithmetically correct; `matchState` below is already `checkAmount`,
        // so the user is asked for the real amount instead of being shown a
        // number the catalog never published.
        portionLabel: candidate.defaultPortionLabel ?? '100 g',
        grams: candidate.defaultGrams ?? 100,
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

  void showComposer() {
    _analysisGeneration++;
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

  void setEatenAt(DateTime? value) {
    final draft = _draft;
    if (draft == null) return;
    _draft = draft.withEatenAt(value);
    notifyListeners();
  }
}
