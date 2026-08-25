import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/l10n/generated/app_localizations.dart';
import 'package:meal_clarity/src/data/meal_repository.dart';
import 'package:meal_clarity/src/domain/meal_analysis_input.dart';
import 'package:meal_clarity/src/domain/models.dart';
import 'package:meal_clarity/src/features/meal_flow.dart';
import 'package:meal_clarity/src/theme/app_theme.dart';

/// The server flags every item it resolved through the language model, so a
/// multi-item meal produced one auto-opening modal sheet per item — five
/// questions before the review screen was ever visible, ordered by nothing.
/// These assert the friction budget: the single most consequential question
/// is asked, the rest stay visible on the review screen, and anything still
/// unresolved is raised once at the only irreversible step.

MealItem _item({
  required String id,
  required String name,
  required double grams,
  required double caloriesPer100g,
}) => MealItem(
  id: id,
  analysisItemKey: id,
  foodId: 'food-$id',
  matchMethod: 'llm',
  sourceName: 'Curated food catalog',
  name: name,
  canonicalName: name,
  sourceText: name,
  portionLabel: '$grams g',
  grams: grams,
  nutritionPer100g: Nutrition(
    calories: caloriesPer100g,
    protein: 1,
    carbs: 1,
    fat: 1,
  ),
  matchState: MatchState.checkAmount,
);

// Ascending calorie impact, deliberately listed smallest-first so ordering by
// list position and ordering by impact cannot be confused.
final _draft = MealDraft(
  inputText: 'karışık tabak',
  mealName: 'Akşam yemeği',
  analysisRunId: 'analysis-run',
  traceId: 'trace-id',
  items: [
    _item(id: 'garnish', name: 'Maydanoz', grams: 10, caloriesPer100g: 36),
    _item(id: 'salad', name: 'Salata', grams: 80, caloriesPer100g: 25),
    _item(id: 'rice', name: 'Pilav', grams: 180, caloriesPer100g: 130),
    _item(id: 'meat', name: 'Kuzu Pirzola', grams: 200, caloriesPer100g: 294),
  ],
);

void main() {
  Future<void> pumpFlow(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(),
        home: MealFlow(repository: _FakeRepository(_draft)),
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

  testWidgets('four flagged items produce exactly one modal sheet', (
    tester,
  ) async {
    await pumpFlow(tester);

    var opened = 0;
    for (var guard = 0; guard < 8; guard += 1) {
      if (find.byType(ModalBarrier).evaluate().length < 2) break;
      opened += 1;
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
    }

    // One, not four and not two. A modal per uncertain item is what produces
    // alert fatigue, and a review that gets rubber-stamped launders a guess
    // into something the user appears to have confirmed.
    expect(opened, 1);
  });

  testWidgets('the highest-calorie item is asked about first', (tester) async {
    await pumpFlow(tester);

    // Asserted on the sheet's own title, not on the item name: the review
    // screen behind the sheet lists every item, so a bare name match would pass
    // no matter which question opened.
    //
    // 200 g at 294 kcal/100 g is the biggest number in the meal, and it is last
    // in the item list — so this fails if the queue follows list order.
    expect(find.text('Kuzu Pirzola miktarı'), findsOneWidget);
    expect(find.text('Maydanoz miktarı'), findsNothing);
  });

  testWidgets('unasked items stay flagged on the review screen', (
    tester,
  ) async {
    await pumpFlow(tester);

    for (var guard = 0; guard < 8; guard += 1) {
      if (find.byType(ModalBarrier).evaluate().length < 2) break;
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
    }

    // Nothing was resolved by dismissing, so all four remain open questions the
    // user can still reach by tapping the row.
    expect(find.text('Miktarı kontrol et'), findsNWidgets(4));
  });

  testWidgets('logging with unchecked details asks once before committing', (
    tester,
  ) async {
    await pumpFlow(tester);
    // Walk past the one proactive question without answering it.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('review-primary-button')));
    await tester.tap(find.byKey(const Key('review-primary-button')));
    await tester.pumpAndSettle();

    // Logging is the one step that cannot be undone by tapping again, so it is
    // the one that names what was never checked.
    expect(find.text('Kontrol edilmemiş noktalar var'), findsOneWidget);
    expect(find.byKey(const Key('unreviewed-proceed')), findsOneWidget);
    expect(find.byKey(const Key('unreviewed-check')), findsOneWidget);
    // Every open item is named, not just counted.
    expect(find.textContaining('Kuzu Pirzola'), findsWidgets);
    expect(find.textContaining('Maydanoz'), findsWidgets);
  });

  testWidgets('the confirmation is a gate the user can always pass', (
    tester,
  ) async {
    await pumpFlow(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('review-primary-button')));
    await tester.tap(find.byKey(const Key('review-primary-button')));
    await tester.pumpAndSettle();

    // "Let me check" returns to the review screen rather than logging.
    await tester.tap(find.byKey(const Key('unreviewed-check')));
    await tester.pumpAndSettle();
    expect(find.text('Kontrol edilmemiş noktalar var'), findsNothing);
    expect(find.byKey(const Key('review-primary-button')), findsOneWidget);
  });
}

class _FakeRepository implements MealRepository {
  const _FakeRepository(this.draft);

  final MealDraft draft;

  @override
  Future<MealDraft> analyze(MealAnalysisInput input) async => draft;
}
