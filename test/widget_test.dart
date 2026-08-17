import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/app.dart';
import 'package:meal_clarity/src/domain/models.dart';

void main() {
  test('meal nutrition is always derived from its items', () {
    const item = MealItem(
      id: 'cheese',
      name: 'White cheese',
      sourceText: 'cheese',
      portionLabel: '30 g',
      grams: 30,
      nutritionPer100g: Nutrition(
        calories: 290,
        protein: 16,
        carbs: 2.5,
        fat: 24,
      ),
      matchState: MatchState.matched,
    );
    const meal = LoggedMeal(
      id: 'breakfast',
      name: 'Breakfast',
      timeLabel: '08:42',
      items: [item, item],
    );

    expect(meal.nutrition.calories, 174);
    expect(meal.nutrition.protein, closeTo(9.6, 0.001));
  });

  testWidgets('user can analyze, clarify, and log a meal', (tester) async {
    await tester.pumpWidget(const MealClarityApp());

    await tester.tap(find.byKey(const Key('quick-composer')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('meal-input')),
      '2 yumurta, biraz beyaz peynir ve yarım simit',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('analyze-button')));
    await tester.tap(find.byKey(const Key('analyze-button')));
    await tester.pump();
    expect(find.text('Yiyecekler bulunuyor'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('3 yiyecek bulduk'), findsOneWidget);
    expect(find.text('Miktarı kontrol et'), findsOneWidget);

    await tester.tap(find.byKey(const Key('review-primary-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('portion-title')), findsOneWidget);

    await tester.tap(find.byKey(const Key('portion-30')));
    await tester.pumpAndSettle();
    expect(find.text('Öğünü kaydet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('review-primary-button')));
    await tester.pumpAndSettle();

    expect(find.text('Kahvaltı kaydedildi'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Kahvaltı'), findsOneWidget);
  });

  testWidgets('meal detail supports deterministic portion editing', (
    tester,
  ) async {
    await tester.pumpWidget(const MealClarityApp());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -650));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('meal-lunch')));
    await tester.pumpAndSettle();
    expect(find.text('Katalog görseli'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Tavuklu Salata'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Tavuklu Salata'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('portion-slider')), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('portion-slider')),
      const Offset(-120, 0),
    );
    await tester.tap(find.byKey(const Key('save-portion-button')));
    await tester.pumpAndSettle();

    expect(find.text('350 g'), findsNothing);
  });
}
