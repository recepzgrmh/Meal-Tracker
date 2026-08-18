import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/app.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MealClarityApp());
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
    await tester.tap(find.text('Öğün Ekle').last);
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
    await tester.ensureVisible(find.byKey(const Key('review-edit-button')));
    await tester.tap(find.byKey(const Key('review-edit-button')));
    await tester.pumpAndSettle();

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
