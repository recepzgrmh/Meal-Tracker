import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/data/meal_repository.dart';
import 'package:meal_clarity/src/catalog/food_catalog_repository.dart';
import 'package:meal_clarity/src/domain/meal_analysis_input.dart';
import 'package:meal_clarity/src/domain/models.dart';
import 'package:meal_clarity/src/view_models/meal_detail_view_model.dart';
import 'package:meal_clarity/src/view_models/meal_flow_view_model.dart';
import 'package:meal_clarity/src/view_models/today_view_model.dart';

void main() {
  const item = MealItem(
    id: 'cheese',
    name: 'Beyaz Peynir',
    sourceText: 'peynir',
    portionLabel: '30 g',
    grams: 30,
    nutritionPer100g: Nutrition(calories: 300, protein: 20, carbs: 2, fat: 24),
    matchState: MatchState.checkAmount,
    foodId: 'catalog-cheese',
    confidence: 0.84,
    matchMethod: 'exact',
  );
  const draft = MealDraft(
    inputText: 'peynir',
    mealName: 'Kahvaltı',
    items: [item],
    analysisRunId: 'analysis-run',
    traceId: 'trace-id',
  );

  group('TodayViewModel', () {
    test('logs, updates, deletes, and restores a meal deterministically', () {
      final ids = ['meal-test', 'item-test'].iterator;
      final viewModel = TodayViewModel(
        idFactory: () {
          ids.moveNext();
          return ids.current;
        },
      );
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      final loggedAt = DateTime(2026, 8, 17, 9, 5);
      final logged = viewModel.logDraft(draft, loggedAt);

      expect(logged.id, 'meal-test');
      expect(logged.items.single.id, 'item-test');
      expect(logged.timeLabel, '09:05');
      expect(viewModel.meals, hasLength(1));
      expect(viewModel.total.calories, closeTo(90, 0.001));

      final updated = logged.copyWith(
        items: [item.copyWith(grams: 50, matchState: MatchState.matched)],
      );
      viewModel.updateMeal(updated);
      expect(viewModel.total.calories, closeTo(150, 0.001));

      final removed = viewModel.deleteMeal(logged.id);
      expect(removed?.id, logged.id);
      expect(viewModel.meals, isEmpty);

      viewModel.restoreMeal(updated);
      viewModel.restoreMeal(updated);
      expect(viewModel.meals, hasLength(1));
      expect(notifications, 4);
    });
  });

  group('MealFlowViewModel', () {
    test(
      'exposes analyzing and review states around repository work',
      () async {
        final repository = _ControllableRepository();
        final viewModel = MealFlowViewModel(repository: repository);

        final operation = viewModel.analyze(_input('  peynir  '));

        expect(viewModel.step, MealFlowStep.analyzing);
        expect(repository.receivedInput, 'peynir');
        repository.complete(draft);
        await operation;

        expect(viewModel.step, MealFlowStep.review);
        expect(viewModel.draft?.reviewCount, 1);
        expect(viewModel.draft?.analysisRunId, 'analysis-run');

        viewModel.updateItem(item.copyWith(matchState: MatchState.matched));
        expect(viewModel.draft?.reviewCount, 0);
        expect(viewModel.draft?.items.single.foodId, 'catalog-cheese');
      },
    );

    test(
      'returns to composer with a reportable failure kind on repository error',
      () async {
        final viewModel = MealFlowViewModel(repository: _ThrowingRepository());

        await viewModel.analyze(_input('peynir'));

        expect(viewModel.step, MealFlowStep.compose);
        expect(viewModel.errorKind, MealAnalysisFailureKind.unknown);
        expect(viewModel.draft, isNull);
      },
    );

    test('discards a stale analysis after the user cancels', () async {
      final repository = _ControllableRepository();
      final viewModel = MealFlowViewModel(repository: repository);

      final operation = viewModel.analyze(_input('peynir'));
      expect(viewModel.step, MealFlowStep.analyzing);

      viewModel.showComposer();
      repository.complete(draft);
      await operation;

      expect(viewModel.step, MealFlowStep.compose);
      expect(viewModel.draft, isNull);
    });

    test('shows a corrective message for a grounded no-match', () async {
      final viewModel = MealFlowViewModel(
        repository: _DomainFailureRepository(
          const MealAnalysisException(
            kind: MealAnalysisFailureKind.noMatch,
            code: 'NO_MATCH',
            retryable: false,
          ),
        ),
      );

      await viewModel.analyze(_input('avokado'));

      expect(viewModel.step, MealFlowStep.compose);
      expect(viewModel.errorKind, MealAnalysisFailureKind.noMatch);
      expect(viewModel.manualSearchSuggested, isTrue);
    });

    test(
      'turns a manual catalog correction into a reviewable grounded draft',
      () async {
        final catalog = _FakeCatalogRepository();
        final viewModel = MealFlowViewModel(
          repository: _ThrowingRepository(),
          catalogRepository: catalog,
          manualItemIdFactory: () => '10000000-0000-0000-0000-000000000099',
        );

        await viewModel.searchCatalog('beyaz peynr', 'tr-TR');
        viewModel.selectManualFood(
          viewModel.catalogResults.single,
          'beyaz peynr',
          mealName: 'Kahvaltı',
        );

        expect(catalog.query, 'beyaz peynr');
        expect(viewModel.step, MealFlowStep.review);
        expect(viewModel.draft?.mealName, 'Kahvaltı');
        expect(viewModel.draft?.analysisRunId, isNull);
        expect(viewModel.draft?.items.single.matchMethod, 'manual');
        expect(viewModel.draft?.items.single.foodId, 'catalog-cheese');
        expect(viewModel.draft?.reviewCount, 1);
      },
    );

    test(
      'keeps an analyzed draft when a manual correction is picked',
      () async {
        final catalog = _FakeCatalogRepository();
        final viewModel = MealFlowViewModel(
          repository: _ImmediateRepository(draft),
          catalogRepository: catalog,
          manualItemIdFactory: () => 'manual-1',
        );

        await viewModel.analyze(_input('peynir'));
        await viewModel.searchCatalog('beyaz peynir', 'tr-TR');
        viewModel.selectManualFood(
          viewModel.catalogResults.single,
          'beyaz peynir',
          mealName: 'Öğle yemeği',
        );

        // The correction is additive: the analyzed item survives and the draft
        // keeps the analysis provenance it was created with.
        expect(viewModel.draft?.items, hasLength(2));
        expect(viewModel.draft?.items.first.id, 'cheese');
        expect(viewModel.draft?.analysisRunId, 'analysis-run');
        expect(viewModel.draft?.mealName, 'Kahvaltı');
      },
    );

    test(
      'keeps manual additions distinct and allows predicted food removal',
      () async {
        final catalog = _FakeCatalogRepository();
        final ids = ['manual-1'].iterator;
        final viewModel = MealFlowViewModel(
          repository: _ImmediateRepository(draft),
          catalogRepository: catalog,
          manualItemIdFactory: () {
            ids.moveNext();
            return ids.current;
          },
        );

        await viewModel.analyze(_input('peynir'));
        await viewModel.searchCatalog('beyaz peynir', 'tr-TR');
        viewModel.addManualFood(
          viewModel.catalogResults.single,
          'beyaz peynir',
        );

        expect(viewModel.draft?.items, hasLength(2));
        expect(viewModel.draft?.items.last.matchMethod, 'manual');
        viewModel.removeItem('cheese');
        expect(viewModel.draft?.items.single.id, 'manual-1');
      },
    );

    test(
      'adds a catalog food that has no published portion without throwing',
      () async {
        final viewModel = MealFlowViewModel(
          repository: _ImmediateRepository(draft),
          catalogRepository: _FakePortionlessCatalogRepository(),
          manualItemIdFactory: () => 'manual-portionless',
        );

        await viewModel.analyze(_input('semizotu'));
        await viewModel.searchCatalog('semizotu', 'tr-TR');
        viewModel.addManualFood(viewModel.catalogResults.single, 'semizotu');

        final added = viewModel.draft!.items.last;
        // Falls back to the 100 g basis the nutrition is expressed in...
        expect(added.grams, 100);
        expect(added.portionLabel, '100 g');
        // ...and asks the user rather than presenting it as a known amount.
        expect(added.matchState, MatchState.checkAmount);
      },
    );
  });

  test('MealDetailViewModel recalculates nutrition after portion editing', () {
    const meal = LoggedMeal(
      id: 'breakfast',
      name: 'Kahvaltı',
      timeLabel: '09:05',
      items: [item],
    );
    final viewModel = MealDetailViewModel(meal: meal);

    final updated = viewModel.updatePortion(item, 50);

    expect(updated.items.single.grams, 50);
    expect(updated.items.single.matchState, MatchState.matched);
    expect(viewModel.nutrition.calories, closeTo(150, 0.001));
  });
}

class _ControllableRepository implements MealRepository {
  final _completer = Completer<MealDraft>();
  String? receivedInput;

  @override
  Future<MealDraft> analyze(MealAnalysisInput input) {
    receivedInput = input.text;
    return _completer.future;
  }

  void complete(MealDraft draft) => _completer.complete(draft);
}

class _ThrowingRepository implements MealRepository {
  @override
  Future<MealDraft> analyze(MealAnalysisInput input) async {
    throw StateError('network unavailable');
  }
}

class _ImmediateRepository implements MealRepository {
  const _ImmediateRepository(this.draft);

  final MealDraft draft;

  @override
  Future<MealDraft> analyze(MealAnalysisInput input) async => draft;
}

class _DomainFailureRepository implements MealRepository {
  const _DomainFailureRepository(this.error);

  final MealAnalysisException error;

  @override
  Future<MealDraft> analyze(MealAnalysisInput input) async => throw error;
}

/// A catalog food with no published portion — the Tier A batch ships these on
/// purpose, so the flow must handle null grams without throwing.
class _FakePortionlessCatalogRepository implements FoodCatalogRepository {
  @override
  Future<List<CatalogFoodCandidate>> search({
    required String query,
    required String locale,
  }) async => const [
    CatalogFoodCandidate(
      foodId: 'catalog-no-portion',
      name: 'Semizotu',
      matchedAlias: 'semizotu',
      score: 0.7,
      defaultGrams: null,
      defaultPortionLabel: null,
      caloriesPer100g: 16,
      proteinPer100g: 1.3,
      carbsPer100g: 3.4,
      fatPer100g: 0.1,
      nutritionSource: 'turkomp:02.01.0031',
    ),
  ];
}

class _FakeCatalogRepository implements FoodCatalogRepository {
  String? query;

  @override
  Future<List<CatalogFoodCandidate>> search({
    required String query,
    required String locale,
  }) async {
    this.query = query;
    return const [
      CatalogFoodCandidate(
        foodId: 'catalog-cheese',
        name: 'Beyaz Peynir',
        matchedAlias: 'beyaz peynir',
        score: 0.8,
        defaultGrams: 30,
        defaultPortionLabel: '1 porsiyon',
        caloriesPer100g: 289,
        proteinPer100g: 16,
        carbsPer100g: 2.5,
        fatPer100g: 24,
        nutritionSource: 'curated:test',
      ),
    ];
  }
}

MealAnalysisInput _input(String text) =>
    MealAnalysisInput(text: text, locale: 'tr-TR');
