import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/app.dart';
import 'package:meal_clarity/src/widgets/meal_list_tile.dart';

/// Removing a meal from a list, and getting it back.
///
/// Driven through the shell so the wiring under test is the real one — the tile
/// confirms, the shell removes and offers the undo, the undo restores — but
/// against the in-memory demo data rather than Drift. A widget test that drives
/// a real database has to fight `flutter_test`'s fake clock for every query,
/// and the persistence half of this story is covered where it belongs:
/// `cached_meal_repository_test.dart` and `sync_status_test.dart`.
void main() {
  // Late morning, so the demo meals (12:34 and 16:15) group predictably and the
  // header date never moves.
  DateTime frozenNow() => DateTime(2026, 8, 22, 10);

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MealClarityApp(clock: frozenNow));
    await tester.pumpAndSettle();
  }

  Finder tileWithText(String text) => find.widgetWithText(MealListTile, text);

  testWidgets('a meal can be removed from Today and brought back', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(tileWithText('Öğle Yemeği'), findsOneWidget);

    await tester.longPress(find.byKey(const Key('meal-lunch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('meal-action-delete')));
    await tester.pumpAndSettle();

    expect(tileWithText('Öğle Yemeği'), findsNothing);
    expect(find.text('Öğle Yemeği silindi'), findsOneWidget);
    // The other meal is untouched.
    expect(tileWithText('Ara Öğün'), findsOneWidget);

    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();

    expect(tileWithText('Öğle Yemeği'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('backing out of the sheet leaves the meal in place', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.longPress(find.byKey(const Key('meal-lunch')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 60));
    await tester.pumpAndSettle();

    expect(tileWithText('Öğle Yemeği'), findsOneWidget);
    expect(find.textContaining('silindi'), findsNothing);
  });

  testWidgets('deleting twice in a row leaves one undo, not a queue', (
    tester,
  ) async {
    await pumpApp(tester);

    for (final id in ['meal-lunch', 'meal-snack']) {
      await tester.longPress(find.byKey(Key(id)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('meal-action-delete')));
      await tester.pumpAndSettle();
    }

    // The second bar replaced the first rather than waiting behind it, so the
    // undo on screen is the one for what just happened.
    expect(find.text('Ara Öğün silindi'), findsOneWidget);
    expect(find.text('Öğle Yemeği silindi'), findsNothing);
    expect(find.text('Geri al'), findsOneWidget);

    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();
    expect(tileWithText('Ara Öğün'), findsOneWidget);
  });

  testWidgets('emptying the day falls through to the empty state', (
    tester,
  ) async {
    await pumpApp(tester);

    for (final id in ['meal-lunch', 'meal-snack']) {
      await tester.longPress(find.byKey(Key(id)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('meal-action-delete')));
      await tester.pumpAndSettle();
    }

    expect(find.byType(MealListTile), findsNothing);
    expect(find.text('Henüz öğün eklemedin'), findsOneWidget);
    expect(find.byKey(const Key('quick-composer')), findsOneWidget);
  });

  testWidgets('a meal removed from History is restored to its own day', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav-destination-1')));
    await tester.pumpAndSettle();
    expect(tileWithText('Öğle Yemeği'), findsOneWidget);

    await tester.longPress(find.byKey(const Key('meal-lunch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('meal-action-delete')));
    await tester.pumpAndSettle();
    expect(tileWithText('Öğle Yemeği'), findsNothing);

    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();

    expect(tileWithText('Öğle Yemeği'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
