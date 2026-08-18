import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/app.dart';

void main() {
  testWidgets('meal composer follows Turkish locale', (tester) async {
    await tester.pumpWidget(const MealClarityApp(locale: Locale('tr')));

    await tester.tap(find.byKey(const Key('quick-composer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-meal-text')));
    await tester.pumpAndSettle();

    expect(find.text('Ne yedin?'), findsOneWidget);
    expect(find.text('Öğünü analiz et'), findsOneWidget);
  });

  testWidgets('meal composer follows English locale', (tester) async {
    await tester.pumpWidget(const MealClarityApp(locale: Locale('en')));

    await tester.tap(find.byKey(const Key('quick-composer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-meal-text')));
    await tester.pumpAndSettle();

    expect(find.text('What did you eat?'), findsOneWidget);
    expect(find.text('Analyze meal'), findsOneWidget);
  });
}
