import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/l10n/generated/app_localizations.dart';
import 'package:meal_clarity/src/catalog/food_catalog_repository.dart';
import 'package:meal_clarity/src/data/meal_repository.dart';
import 'package:meal_clarity/src/domain/meal_analysis_input.dart';
import 'package:meal_clarity/src/domain/models.dart';
import 'package:meal_clarity/src/features/meal_flow.dart';
import 'package:meal_clarity/src/theme/app_theme.dart';

/// The identity ("which food was this?") clarification sheet, which had no test
/// at all. Answering it swaps the food, and the amount that was resolved for the
/// *previous* food cannot survive that swap: 180 g of pilav is not 180 g of the
/// thing the user actually meant.
const _ambiguousItem = MealItem(
  id: 'item-1',
  analysisItemKey: 'item-1',
  foodId: 'food-pilav-generic',
  matchMethod: 'alias',
  sourceName: 'Curated food catalog · alias-v1',
  name: 'Pilav',
  canonicalName: 'Pilav',
  sourceText: 'pilav',
  portionLabel: '1 porsiyon',
  grams: 180,
  nutritionPer100g: Nutrition(
    calories: 130,
    protein: 2.4,
    carbs: 28.0,
    fat: 0.3,
  ),
  matchState: MatchState.checkType,
  portionOptions: [
    FoodPortionOption(label: 'az', grams: 120),
    FoodPortionOption(label: '1 porsiyon', grams: 180),
    FoodPortionOption(label: 'fazla', grams: 260),
  ],
);

const _draft = MealDraft(
  inputText: 'pilav',
  mealName: 'Akşam yemeği',
  analysisRunId: 'analysis-run',
  traceId: 'trace-id',
  items: [_ambiguousItem],
);

void main() {
  Future<void> pumpFlow(
    WidgetTester tester,
    FoodCatalogRepository catalog,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(),
        home: MealFlow(
          repository: const _FakeRepository(_draft),
          catalogRepository: catalog,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('meal-input')),
      _draft.inputText,
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('analyze-button')));
    await tester.tap(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();
  }

  testWidgets('an identity question opens with the catalog alternatives', (
    tester,
  ) async {
    await pumpFlow(tester, _FakeCatalog());

    expect(find.text('Hangisine daha yakındı?'), findsOneWidget);
    expect(find.byKey(const Key('variant-food-bulgur-pilavi')), findsOneWidget);
  });

  testWidgets('choosing a different food re-asks for the amount instead of '
      'keeping the previous food\'s grams', (tester) async {
    await pumpFlow(tester, _FakeCatalog());

    await tester.tap(find.byKey(const Key('variant-food-bulgur-pilavi')));
    await tester.pumpAndSettle();

    // The swap must not silently reuse 180 g — that belonged to the food the
    // user just rejected, and scaling the new food's macros by it produced a
    // wrong calorie count on an item marked resolved.
    expect(find.text('180 g'), findsNothing);
    expect(find.text('~150 g'), findsOneWidget);

    // 83 kcal/100 g at the new food's own 150 g default. Proves the macros were
    // recomputed against the food the user actually chose.
    expect(find.text('125 kcal'), findsWidgets);

    // And the amount is an open question again rather than silently accepted.
    expect(find.text('Miktarı kontrol et'), findsOneWidget);
  });
}

class _FakeRepository implements MealRepository {
  const _FakeRepository(this.draft);

  final MealDraft draft;

  @override
  Future<MealDraft> analyze(MealAnalysisInput input) async => draft;
}

class _FakeCatalog implements FoodCatalogRepository {
  @override
  Future<List<CatalogFoodCandidate>> search({
    required String query,
    required String locale,
  }) async {
    return const [
      CatalogFoodCandidate(
        foodId: 'food-bulgur-pilavi',
        name: 'Bulgur Pilavı',
        matchedAlias: 'bulgur pilavı',
        score: 0.91,
        defaultGrams: 150,
        defaultPortionLabel: '1 porsiyon',
        caloriesPer100g: 83,
        proteinPer100g: 3.1,
        carbsPer100g: 18.6,
        fatPer100g: 0.2,
        nutritionSource: 'turkomp:01.02.0007',
      ),
    ];
  }
}
