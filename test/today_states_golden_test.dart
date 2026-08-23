import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/l10n/generated/app_localizations.dart';
import 'package:meal_clarity/src/domain/models.dart';
import 'package:meal_clarity/src/domain/nutrition_goals.dart';
import 'package:meal_clarity/src/features/today_screen.dart';
import 'package:meal_clarity/src/sync/sync_status.dart';
import 'package:meal_clarity/src/theme/app_theme.dart';

/// Visual baselines for the states Today can be in.
///
/// Rendered from [TodayScreen] with an injected day and fixed meals rather than
/// through the app shell: the shell reads the wall clock for its header and its
/// demo seed, which is what made the older whole-app baselines expire overnight.
///
/// Every case also runs with `disableAnimations`, which both exercises the
/// reduced-motion path and holds the loading placeholder still — a pulsing
/// skeleton has no single frame to compare against.
void main() {
  const item = MealItem(
    id: 'item',
    name: 'Yumurta',
    sourceText: 'yumurta',
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

  final day = DateTime(2026, 8, 22);

  LoggedMeal meal(
    String id,
    String name,
    int hour, {
    String? imageAsset,
    bool isPending = false,
    MatchState matchState = MatchState.matched,
  }) => LoggedMeal(
    id: id,
    name: name,
    timeLabel: '${hour.toString().padLeft(2, '0')}:15',
    occurredAt: DateTime(2026, 8, 22, hour, 15),
    imageAsset: imageAsset,
    isPending: isPending,
    items: [item.copyWith(matchState: matchState)],
  );

  Future<void> pumpToday(
    WidgetTester tester, {
    required List<LoggedMeal> meals,
    bool isLoading = false,
    SyncStatus? syncStatus,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          disableAnimations: true,
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
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
            onRetrySync: syncStatus == null ? null : () async {},
            onDeleteMeal: (_) {},
            onAddMeal: () {},
            onMealTap: (_) {},
            onNavigationSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('today grouped by part of the day', (tester) async {
    await pumpToday(
      tester,
      meals: [
        meal('a', 'Kahvaltı', 8, imageAsset: 'assets/images/breakfast.png'),
        meal(
          'b',
          'Öğle Yemeği',
          12,
          imageAsset: 'assets/images/chicken-salad.png',
        ),
        meal(
          'c',
          'Ara Öğün',
          16,
          imageAsset: 'assets/images/banana-yogurt.png',
        ),
      ],
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_grouped.png'),
    );
  }, tags: ['golden']);

  testWidgets('today empty', (tester) async {
    await pumpToday(tester, meals: const []);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_empty.png'),
    );
  }, tags: ['golden']);

  testWidgets('today loading placeholders', (tester) async {
    await pumpToday(tester, meals: const [], isLoading: true);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_loading.png'),
    );
  }, tags: ['golden']);

  testWidgets('today with meals waiting to upload', (tester) async {
    await pumpToday(
      tester,
      meals: [
        meal('a', 'Kahvaltı', 8, isPending: true),
        meal('b', 'Öğle Yemeği', 12, isPending: true),
      ],
      syncStatus: const SyncStatus(
        state: SyncState.waiting,
        pending: 2,
        blocked: 0,
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_pending_sync.png'),
    );
  }, tags: ['golden']);

  testWidgets('today after the queue gave up', (tester) async {
    await pumpToday(
      tester,
      meals: [meal('a', 'Kahvaltı', 8, isPending: true)],
      syncStatus: const SyncStatus(
        state: SyncState.failed,
        pending: 0,
        blocked: 1,
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_sync_failed.png'),
    );
  }, tags: ['golden']);

  testWidgets('today with photos that cannot be loaded', (tester) async {
    await pumpToday(
      tester,
      meals: [
        // A bundled asset that is not in the bundle, and a server storage path
        // that is not an asset at all. Both must land on the placeholder rather
        // than taking the row down.
        meal('a', 'Kahvaltı', 8, imageAsset: 'assets/images/missing.png'),
        meal('b', 'Akşam Yemeği', 20, imageAsset: 'user-42/meal-b.jpg'),
      ],
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_broken_photos.png'),
    );
  }, tags: ['golden']);
}
