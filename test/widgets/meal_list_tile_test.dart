import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/l10n/generated/app_localizations.dart';
import 'package:meal_clarity/src/domain/models.dart';
import 'package:meal_clarity/src/theme/app_theme.dart';
import 'package:meal_clarity/src/widgets/meal_list_tile.dart';
import 'package:meal_clarity/src/widgets/meal_photo.dart';

void main() {
  const item = MealItem(
    id: 'egg',
    name: 'Yumurta',
    sourceText: 'yumurta',
    portionLabel: '1 adet',
    grams: 100,
    nutritionPer100g: Nutrition(calories: 100, protein: 10, carbs: 1, fat: 5),
    matchState: MatchState.matched,
  );

  LoggedMeal meal({String? imageAsset}) => LoggedMeal(
    id: 'meal-1',
    name: 'Kahvaltı',
    timeLabel: '08:30',
    imageAsset: imageAsset,
    occurredAt: DateTime(2026, 8, 22, 8, 30),
    items: const [item],
  );

  Future<void> pumpTile(
    WidgetTester tester, {
    required LoggedMeal value,
    VoidCallback? onDelete,
    VoidCallback? onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MealListTile(
            meal: value,
            onTap: onTap ?? () {},
            onDelete: onDelete,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('image robustness', () {
    testWidgets('a meal with no photo renders the placeholder', (tester) async {
      await pumpTile(tester, value: meal());

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a bundled asset renders as an image', (tester) async {
      await pumpTile(
        tester,
        value: meal(imageAsset: 'assets/images/chicken-salad.png'),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a server storage path degrades instead of throwing', (
      tester,
    ) async {
      // `MealRemoteDto.imagePath` lands in this field verbatim, so any meal
      // synced down with a photo used to reach `Image.asset` with something
      // that is not an asset — which throws out of build and takes the row with
      // it.
      await pumpTile(
        tester,
        value: meal(imageAsset: 'user-42/meal-1/original.jpg'),
      );

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    });

    testWidgets('a missing asset falls back rather than breaking the row', (
      tester,
    ) async {
      await pumpTile(
        tester,
        value: meal(imageAsset: 'assets/images/does-not-exist.png'),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
      expect(find.text('Kahvaltı'), findsOneWidget);
    });

    testWidgets('a network photo shows the placeholder until it arrives', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(
            body: SizedBox.square(
              dimension: 88,
              child: MealPhoto(
                source: 'https://example.invalid/meal.jpg',
                placeholderIconSize: 24,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('contextual delete', () {
    testWidgets('is absent when the screen cannot delete', (tester) async {
      await pumpTile(tester, value: meal());
      await tester.longPress(find.byKey(const Key('meal-meal-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('meal-action-delete')), findsNothing);
    });

    testWidgets('a long press asks before removing anything', (tester) async {
      var deletes = 0;
      await pumpTile(tester, value: meal(), onDelete: () => deletes++);

      await tester.longPress(find.byKey(const Key('meal-meal-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('meal-action-delete')), findsOneWidget);
      // Holding the row is not yet consent.
      expect(deletes, 0);

      await tester.tap(find.byKey(const Key('meal-action-delete')));
      await tester.pumpAndSettle();
      expect(deletes, 1);
    });

    testWidgets('dismissing the sheet leaves the meal alone', (tester) async {
      var deletes = 0;
      await pumpTile(tester, value: meal(), onDelete: () => deletes++);

      await tester.longPress(find.byKey(const Key('meal-meal-1')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(200, 40));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('meal-action-delete')), findsNothing);
      expect(deletes, 0);
    });

    testWidgets('a long press does not also open the meal', (tester) async {
      var taps = 0;
      await pumpTile(
        tester,
        value: meal(),
        onTap: () => taps++,
        onDelete: () {},
      );

      await tester.longPress(find.byKey(const Key('meal-meal-1')));
      await tester.pumpAndSettle();

      expect(taps, 0);
    });
  });

  group('semantics', () {
    testWidgets('the row is one announceable, tappable button', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTile(tester, value: meal());

      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('Kahvaltı')),
      );
      expect(node.label, contains('Kahvaltı'));
      expect(node.label, contains('08:30'));
      expect(node.label, contains('100 kcal'));
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'a node that claims to be a button must expose a tap',
      );
      handle.dispose();
    });

    testWidgets('delete reaches assistive tech without a long press', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var deletes = 0;
      await pumpTile(tester, value: meal(), onDelete: () => deletes++);

      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('Kahvaltı')),
      );
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.dismiss),
        isTrue,
      );

      // The suggested replacement, `rootPipelineOwner`, owns a different tree
      // and its semantics owner does not resolve ids from this one — invoking
      // through it silently does nothing.
      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        node.id,
        SemanticsAction.dismiss,
      );
      await tester.pump();
      expect(deletes, 1);
      handle.dispose();
    });
  });
}
