import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/l10n/generated/app_localizations.dart';
import 'package:meal_clarity/src/catalog/food_catalog_repository.dart';
import 'package:meal_clarity/src/data/meal_repository.dart';
import 'package:meal_clarity/src/domain/meal_analysis_input.dart';
import 'package:meal_clarity/src/domain/models.dart';
import 'package:meal_clarity/src/features/meal_detail_screen.dart';
import 'package:meal_clarity/src/features/meal_flow.dart';
import 'package:meal_clarity/src/theme/app_theme.dart';

import '../support/clarification.dart';

/// The review and detail affordances for server-side AI estimates: the item
/// exists, is clearly marked as a model guess rather than a catalog match,
/// stays replaceable through the manual search, and keeps its marker after
/// the meal is logged.
const _estimateItem = MealItem(
  id: 'est-1',
  analysisItemKey: 'item-1',
  estimateId: '0190aaaa-bbbb-7ccc-8ddd-eeeeffff0001',
  matchMethod: 'ai_estimate',
  sourceName: '',
  name: 'Kısır',
  sourceText: 'ev yapımı kısır',
  portionLabel: '150 g',
  grams: 150,
  nutritionPer100g: Nutrition(
    calories: 190,
    protein: 4.2,
    carbs: 30.1,
    fat: 6.4,
  ),
  matchState: MatchState.checkAmount,
);

const _groundedItem = MealItem(
  id: 'egg-1',
  analysisItemKey: 'item-2',
  foodId: 'food-egg',
  matchMethod: 'exact',
  sourceName: 'Curated food catalog · exact-alias-v1',
  name: 'Yumurta',
  sourceText: '2 yumurta',
  portionLabel: '2 adet',
  grams: 100,
  nutritionPer100g: Nutrition(
    calories: 155,
    protein: 12.6,
    carbs: 1.1,
    fat: 10.6,
  ),
  matchState: MatchState.matched,
);

const _reviewDraft = MealDraft(
  inputText: 'ev yapımı kısır, 2 yumurta ve maydanoz',
  mealName: 'Akşam yemeği',
  analysisRunId: 'analysis-run',
  traceId: 'trace-id',
  unmatchedText: ['maydanoz', 'ev yapımı sos'],
  items: [_estimateItem, _groundedItem],
);

void main() {
  Future<void> pumpReview(
    WidgetTester tester, {
    MealDraft draft = _reviewDraft,
    FoodCatalogRepository? catalog,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(),
        home: MealFlow(
          repository: _FakeRepository(draft),
          catalogRepository: catalog,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('meal-input')),
      draft.inputText,
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('analyze-button')));
    await tester.tap(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();
    // The flow now asks its portion question before the review screen is
    // reachable. These tests are about the review screen, so the question is
    // answered elsewhere and skipped here.
    await dismissClarificationSheets(tester);
  }

  testWidgets(
    'an estimate row is marked as an AI estimate with approximate numbers',
    (tester) async {
      await pumpReview(tester);

      // The AI chip appears exactly once — on the estimate row, not on the
      // catalog-grounded one.
      expect(find.byKey(const Key('ai-estimate-chip')), findsOneWidget);
      expect(find.text('Yapay zekâ tahmini'), findsOneWidget);
      // All of the estimate's numbers carry the `~`.
      expect(find.text('~150 g'), findsOneWidget);
      expect(find.text('~285 kcal'), findsOneWidget);
      // The grounded row's numbers stay exact.
      expect(find.text('100 g'), findsOneWidget);
      expect(find.text('155 kcal'), findsOneWidget);
      // The portion-clarification affordance survives on the estimate row.
      expect(find.text('Miktarı kontrol et'), findsOneWidget);
    },
  );

  testWidgets('catalog-grounded rows carry their source, estimates do not', (
    tester,
  ) async {
    await pumpReview(tester);

    final provenance = find.byKey(const Key('provenance-label'));
    expect(provenance, findsOneWidget);
    expect(
      tester.widget<Text>(provenance).data,
      'Kaynak: Curated food catalog · exact-alias-v1',
    );
  });

  testWidgets('unmatched foods are named in a non-blocking warning', (
    tester,
  ) async {
    await pumpReview(tester);

    await tester.ensureVisible(find.byKey(const Key('unmatched-warning')));
    expect(
      find.text('Eşleştirilemedi: maydanoz, ev yapımı sos'),
      findsOneWidget,
    );
    // Warning only — logging stays possible.
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('review-primary-button')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('the unmatched warning opens the manual catalog search', (
    tester,
  ) async {
    final catalog = _FakeCatalog();
    await pumpReview(tester, catalog: catalog);

    await tester.ensureVisible(
      find.byKey(const Key('unmatched-search-button')),
    );
    await tester.tap(find.byKey(const Key('unmatched-search-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manual-catalog-query')), findsOneWidget);
  });

  testWidgets('replacing an estimate swaps it for the picked catalog food', (
    tester,
  ) async {
    final catalog = _FakeCatalog();
    await pumpReview(tester, catalog: catalog);

    await tester.ensureVisible(find.byKey(const Key('replace-estimate-est-1')));
    await tester.tap(find.byKey(const Key('replace-estimate-est-1')));
    await tester.pumpAndSettle();

    // The search is seeded with what the user actually typed for this item.
    expect(catalog.lastQuery, 'ev yapımı kısır');
    await tester.tap(find.byKey(const Key('catalog-result-food-bulgur')));
    await tester.pumpAndSettle();

    // Replaced in place: still two rows, no AI chip left, the catalog food
    // (and its provenance) in the estimate's slot.
    expect(find.byKey(const Key('ai-estimate-chip')), findsNothing);
    expect(find.text('Bulgur pilavı'), findsOneWidget);
    expect(find.byKey(const Key('replace-estimate-est-1')), findsNothing);
    expect(find.byKey(const Key('provenance-label')), findsNWidgets(2));
  });

  testWidgets('the replace affordance meets the 48 px touch target', (
    tester,
  ) async {
    await pumpReview(tester, catalog: _FakeCatalog());

    await tester.ensureVisible(find.byKey(const Key('replace-estimate-est-1')));
    final size = tester.getSize(find.byKey(const Key('replace-estimate-est-1')));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('the AI-estimate marker persists into the logged meal detail', (
    tester,
  ) async {
    // Portion already confirmed (matched), yet the nutrition stays a guess.
    final meal = LoggedMeal(
      id: 'meal-1',
      name: 'Akşam yemeği',
      timeLabel: '19:30',
      items: [
        _estimateItem.copyWith(matchState: MatchState.matched),
        _groundedItem,
      ],
    );
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(),
        home: MealDetailScreen(
          meal: meal,
          onUpdate: (_) {},
          onDelete: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail-ai-estimate-chip')), findsOneWidget);
    expect(find.text('Yapay zekâ tahmini'), findsOneWidget);
    expect(find.text('~150 g'), findsOneWidget);
    // The meal total admits the approximation too.
    expect(find.textContaining('~'), findsWidgets);
  });
}

class _FakeRepository implements MealRepository {
  const _FakeRepository(this.draft);

  final MealDraft draft;

  @override
  Future<MealDraft> analyze(MealAnalysisInput input) async => draft;
}

class _FakeCatalog implements FoodCatalogRepository {
  String? lastQuery;

  @override
  Future<List<CatalogFoodCandidate>> search({
    required String query,
    required String locale,
  }) async {
    lastQuery = query;
    return const [
      CatalogFoodCandidate(
        foodId: 'food-bulgur',
        name: 'Bulgur Pilavı',
        matchedAlias: 'bulgur',
        score: 0.9,
        defaultGrams: 180,
        defaultPortionLabel: '1 porsiyon',
        caloriesPer100g: 120,
        proteinPer100g: 3.1,
        carbsPer100g: 24.5,
        fatPer100g: 1.2,
        nutritionSource: 'turkomp:01.02.0007',
      ),
    ];
  }
}
