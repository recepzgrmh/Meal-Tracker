import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meal_clarity/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('logs an ambiguous meal from input to daily overview', (
    tester,
  ) async {
    await tester.pumpWidget(const MealClarityApp());

    await tester.tap(find.byKey(const Key('quick-composer')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('meal-input')),
      '2 yumurta, biraz beyaz peynir ve yarım simit',
    );
    FocusManager.instance.primaryFocus?.unfocus();
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
    await tester.tap(find.byKey(const Key('review-primary-button')));
    await tester.pumpAndSettle();

    expect(find.text('Kahvaltı kaydedildi'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -650));
    await tester.pumpAndSettle();
    expect(find.text('Kahvaltı'), findsOneWidget);
  });
}
