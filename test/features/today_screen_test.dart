import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/l10n/generated/app_localizations.dart';
import 'package:meal_clarity/src/domain/models.dart';
import 'package:meal_clarity/src/domain/nutrition_goals.dart';
import 'package:meal_clarity/src/features/today_screen.dart';
import 'package:meal_clarity/src/sync/sync_status.dart';
import 'package:meal_clarity/src/theme/app_theme.dart';
import 'package:meal_clarity/src/widgets/daily_summary_card.dart';
import 'package:meal_clarity/src/widgets/empty_state_view.dart';
import 'package:meal_clarity/src/widgets/meal_list_tile.dart';

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

  // Fixed so nothing in this file depends on when it runs: the grouping is
  // derived from the clock, and "now" would move meals between sections.
  final day = DateTime(2026, 8, 22);

  LoggedMeal mealAt(String id, int hour, {bool isPending = false}) =>
      LoggedMeal(
        id: id,
        name: id,
        timeLabel: '${hour.toString().padLeft(2, '0')}:00',
        occurredAt: DateTime(2026, 8, 22, hour),
        items: const [item],
        isPending: isPending,
      );

  Future<void> pump(
    WidgetTester tester, {
    List<LoggedMeal> meals = const [],
    bool isLoading = false,
    SyncStatus? syncStatus,
    ValueChanged<LoggedMeal>? onDeleteMeal,
    Future<void> Function()? onRetrySync,
    VoidCallback? onAddMeal,
    Size size = const Size(390, 1400),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TodayScreen(
          meals: meals,
          goals: NutritionGoals.fallback,
          day: day,
          isLoading: isLoading,
          syncStatus: syncStatus,
          onRetrySync: onRetrySync,
          onDeleteMeal: onDeleteMeal,
          onAddMeal: onAddMeal ?? () {},
          onMealTap: (_) {},
          onNavigationSelected: (_) {},
          showBottomNavigationBar: false,
        ),
      ),
    );
    await tester.pump();
  }

  group('loading', () {
    testWidgets('shows placeholders and never claims the day is empty', (
      tester,
    ) async {
      await pump(tester, isLoading: true);

      expect(find.byKey(const Key('meal-list-skeleton')), findsOneWidget);
      expect(find.byKey(const Key('daily-summary-skeleton')), findsOneWidget);
      // The whole point: an empty state is a claim about data we have not read.
      expect(find.byType(EmptyStateView), findsNothing);
      expect(find.byType(DailySummaryCard), findsNothing);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('announces the wait once rather than per placeholder', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, isLoading: true);

      expect(find.bySemanticsLabel('Günün yükleniyor'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      handle.dispose();
    });

    testWidgets('placeholder card occupies the height the real card will', (
      tester,
    ) async {
      // Pins the no-layout-shift promise. If the summary card grows a row, this
      // fails instead of the content quietly starting to jump on every launch.
      await pump(tester, isLoading: true);
      final skeletonHeight = tester
          .getSize(find.byKey(const Key('daily-summary-skeleton')))
          .height;
      await tester.pump(const Duration(seconds: 1));

      await pump(tester, meals: [mealAt('a', 8)]);
      final realHeight = tester
          .getSize(find.byKey(const Key('daily-summary-card')))
          .height;

      expect((skeletonHeight - realHeight).abs(), lessThanOrEqualTo(8));
    });

    testWidgets('placeholder holds still when the user asked for less motion', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: buildTheme(),
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TodayScreen(
              meals: const [],
              goals: NutritionGoals.fallback,
              day: day,
              isLoading: true,
              onAddMeal: () {},
              onMealTap: (_) {},
              onNavigationSelected: (_) {},
              showBottomNavigationBar: false,
            ),
          ),
        ),
      );
      await tester.pump();

      // No pending frames means nothing is animating.
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('empty state', () {
    testWidgets('explains the blank day without a second heading', (
      tester,
    ) async {
      await pump(tester);

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('Henüz öğün eklemedin'), findsOneWidget);
      // A section heading over an empty list labels nothing.
      expect(find.text('Bugünün öğünleri'), findsNothing);
    });

    testWidgets('does not duplicate the action already on screen', (
      tester,
    ) async {
      var added = 0;
      await pump(tester, onAddMeal: () => added++);

      // The capture card sits directly above and is the primary action.
      expect(
        find.descendant(
          of: find.byType(EmptyStateView),
          matching: find.byType(FilledButton),
        ),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('quick-composer')));
      expect(added, 1);
    });

    testWidgets('the capture card stays reachable above the fold', (
      tester,
    ) async {
      // On a stock phone the one action an empty day offers must not need a
      // scroll to reach.
      await pump(tester, size: const Size(390, 844));

      final composer = tester.getRect(find.byKey(const Key('quick-composer')));
      expect(composer.bottom, lessThan(844));
    });
  });

  group('grouping', () {
    testWidgets('splits the day into the parts that contain food', (
      tester,
    ) async {
      await pump(
        tester,
        meals: [mealAt('sabah', 8), mealAt('ogle', 12), mealAt('aksam', 20)],
      );

      expect(find.text('Kahvaltı'), findsOneWidget);
      expect(find.text('Öğle'), findsOneWidget);
      expect(find.text('Akşam'), findsOneWidget);
      expect(find.text('Ara öğün'), findsNothing);
      expect(find.byType(MealListTile), findsNWidgets(3));
    });

    testWidgets('a single group carries no header', (tester) async {
      await pump(tester, meals: [mealAt('sabah', 8), mealAt('kahve', 9)]);

      expect(find.text('Kahvaltı'), findsNothing);
      expect(find.byType(MealListTile), findsNWidgets(2));
    });

    testWidgets('a header totals its own group', (tester) async {
      await pump(
        tester,
        meals: [mealAt('a', 8), mealAt('b', 9), mealAt('c', 20)],
      );

      // Two 100 kcal meals in the morning, one in the evening.
      expect(find.text('200 kcal'), findsOneWidget);
      expect(find.text('100 kcal'), findsOneWidget);
    });
  });

  group('sync status', () {
    testWidgets('says nothing when there is nothing outstanding', (
      tester,
    ) async {
      await pump(
        tester,
        meals: [mealAt('a', 8)],
        syncStatus: SyncStatus.settled,
        onRetrySync: () async {},
      );

      expect(find.byKey(const Key('sync-status-banner')), findsNothing);
    });

    testWidgets('reports a queue that is still waiting, without alarm', (
      tester,
    ) async {
      await pump(
        tester,
        meals: [mealAt('a', 8, isPending: true)],
        syncStatus: const SyncStatus(
          state: SyncState.waiting,
          pending: 2,
          blocked: 0,
        ),
        onRetrySync: () async {},
      );

      expect(find.byKey(const Key('sync-status-banner')), findsOneWidget);
      expect(find.text('2 öğün gönderilmeyi bekliyor.'), findsOneWidget);
      expect(find.byKey(const Key('sync-retry-button')), findsNothing);
    });

    testWidgets('only a failed queue asks the user to do something', (
      tester,
    ) async {
      var retries = 0;
      await pump(
        tester,
        meals: [mealAt('a', 8, isPending: true)],
        syncStatus: const SyncStatus(
          state: SyncState.failed,
          pending: 0,
          blocked: 1,
        ),
        onRetrySync: () async => retries++,
      );

      expect(find.text('Bazı öğünler gönderilemedi.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('sync-retry-button')));
      await tester.pump();
      expect(retries, 1);
    });

    testWidgets('a pending meal is marked on its own row', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, meals: [mealAt('a', 8, isPending: true)]);

      expect(
        find.bySemanticsLabel(RegExp('kaydedildi, gönderilmeyi bekliyor')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a synced meal is not marked', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, meals: [mealAt('a', 8)]);

      expect(
        find.bySemanticsLabel(RegExp('gönderilmeyi bekliyor')),
        findsNothing,
      );
      handle.dispose();
    });
  });
}
