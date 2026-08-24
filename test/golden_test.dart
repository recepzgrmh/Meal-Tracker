import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/app.dart';

import 'support/clarification.dart';

void main() {
  // Today renders the real date in its header and seeds its demo meals off the
  // clock, so these baselines used to stop matching the moment the day rolled
  // over — three of them were already failing before anyone touched the UI.
  // Freezing "now" makes the screenshots depend on the code alone.
  DateTime frozenNow() => DateTime(2026, 8, 22, 18, 30);

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MealClarityApp(clock: frozenNow));
    await tester.pumpAndSettle();
  }

  testWidgets('today screen visual baseline', (tester) async {
    await pumpApp(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today.png'),
    );
  }, tags: ['golden']);

  testWidgets('meal detail visual baseline', (tester) async {
    await pumpApp(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -520));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('meal-lunch')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/meal_detail.png'),
    );
  }, tags: ['golden']);

  testWidgets('add meal visual baseline', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav-destination-2')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/add_meal.png'),
    );
  }, tags: ['golden']);

  testWidgets('AI review visual baseline', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('quick-composer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-meal-text')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('meal-input')),
      '2 yumurta, biraz beyaz peynir ve yarım simit',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('analyze-button')));
    await tester.tap(find.byKey(const Key('analyze-button')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    // Analysis walks its open questions first now; this baseline is of the
    // review screen behind them, which the next test covers directly.
    await dismissClarificationSheets(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/ai_review.png'),
    );
  }, tags: ['golden']);

  testWidgets('portion clarification visual baseline', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('quick-composer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-meal-text')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('meal-input')),
      '2 yumurta, biraz beyaz peynir ve yarım simit',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('analyze-button')));
    await tester.tap(find.byKey(const Key('analyze-button')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    // No tap needed any more: the portion question is what the user meets
    // straight after analysis, so this baseline is now of the real flow rather
    // than of a sheet reached by tapping a flagged row.
    expect(find.byKey(const Key('portion-title')), findsOneWidget);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/portion_clarification.png'),
    );
  }, tags: ['golden']);

  testWidgets('history visual baseline', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Geçmiş').last);
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/history.png'),
    );
  }, tags: ['golden']);

  testWidgets('analysis visual baseline', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Analiz').last);
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/analysis.png'),
    );
  }, tags: ['golden']);

  testWidgets('profile visual baseline', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/profile.png'),
    );
  }, tags: ['golden']);
}
