import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/app.dart';
import 'package:meal_clarity/src/data/meal_repository.dart';
import 'package:meal_clarity/src/domain/meal_analysis_input.dart';
import 'package:meal_clarity/src/domain/models.dart';
import 'package:meal_clarity/src/domain/nutrition_goals.dart';
import 'package:meal_clarity/src/features/analysis_screen.dart';

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
    await tester.pump();
    expect(find.text('Yiyecekler bulunuyor'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('3 yiyecek bulduk'), findsOneWidget);
    expect(find.text('Öğünün hazır'), findsOneWidget);
    expect(find.text('Bulunan yiyecekler'), findsOneWidget);
    expect(find.text('Miktarı kontrol et'), findsOneWidget);

    await tester.tap(find.byKey(const Key('review-edit-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('portion-title')), findsOneWidget);

    await tester.tap(find.byKey(const Key('portion-30')));
    await tester.pumpAndSettle();
    expect(find.text('Öğünü kaydet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('review-primary-button')));
    await tester.pumpAndSettle();

    expect(find.text('Kahvaltı kaydedildi'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -340));
    await tester.pumpAndSettle();
    expect(find.text('Kahvaltı'), findsOneWidget);

    await tester.tap(find.text('Analiz'));
    await tester.pumpAndSettle();
    expect(find.text('Henüz yeterli veri yok'), findsOneWidget);
    expect(find.text('1 / 3 aktif gün'), findsOneWidget);
    expect(find.byKey(const Key('calorie-trend-chart')), findsNothing);
  });

  testWidgets(
    'shell routes composer analysis through the injected repository',
    (tester) async {
      final repository = _InjectedRepository();
      await tester.pumpWidget(
        MaterialApp(home: MealClarityShell(analysisRepository: repository)),
      );

      await tester.tap(find.byKey(const Key('quick-composer')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-meal-text')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('meal-input')),
        'iki yumurta',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('analyze-button')));
      await tester.tap(find.byKey(const Key('analyze-button')));
      await tester.pumpAndSettle();

      expect(repository.input, 'iki yumurta');
      expect(find.text('Sunucudan Yumurta'), findsOneWidget);
    },
  );

  testWidgets('meal detail supports deterministic portion editing', (
    tester,
  ) async {
    await tester.pumpWidget(const MealClarityApp());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -650));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('meal-lunch')));
    await tester.pumpAndSettle();
    expect(find.text('Katalog görseli'), findsNothing);
    expect(find.text('Öğle Yemeği'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Tavuklu salata'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Tavuklu salata'));
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

  testWidgets('bottom bar exposes five destinations and routes them', (
    tester,
  ) async {
    await tester.pumpWidget(const MealClarityApp());

    expect(find.text('Günlük'), findsOneWidget);
    expect(find.text('Geçmiş'), findsOneWidget);
    // Visible label is shortened to fit five destinations; the full phrase is
    // what assistive tech announces.
    expect(find.text('Ekle'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const Key('nav-destination-2'))).label,
      'Öğün Ekle',
    );
    expect(find.text('Analiz'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    await tester.tap(find.text('Analiz'));
    await tester.pumpAndSettle();
    expect(find.text('Henüz yeterli veri yok'), findsOneWidget);
    expect(find.byKey(const Key('calorie-trend-chart')), findsNothing);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Günlük hedef'), findsOneWidget);
    expect(find.text('2.100 kcal'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-destination-2')));
    await tester.pumpAndSettle();
    expect(
      find.text('Yemeğini göster,\ngerisini birlikte halledelim.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('add-meal-camera')), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-meal-text')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('meal-input')), findsOneWidget);
  });

  testWidgets('daily summary exposes real metrics and opens analysis details', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MealClarityApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('daily-summary-card')), findsOneWidget);
    expect(find.byKey(const Key('daily-summary-title')), findsOneWidget);
    expect(find.byKey(const Key('daily-calorie-ring')), findsOneWidget);
    expect(find.byKey(const Key('daily-consumed-stat')), findsOneWidget);
    expect(find.byKey(const Key('daily-goal-stat')), findsOneWidget);
    expect(find.text('Alınan'), findsOneWidget);
    expect(find.text('Hedef'), findsOneWidget);
    expect(find.text('Detaylar'), findsOneWidget);
    expect(find.text('Yakılan'), findsNothing);

    await tester.tap(find.byKey(const Key('daily-summary-details')));
    await tester.pumpAndSettle();

    expect(
      tester
          .getSemantics(find.byKey(const Key('nav-destination-3')))
          .toString(),
      contains('isSelected'),
    );
    expect(find.text('Henüz yeterli veri yok'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('daily summary remains scrollable in landscape', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MealClarityApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('daily-summary-card')), findsOneWidget);
    expect(find.byKey(const Key('daily-summary-details')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('primary tabs support horizontal swipe navigation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MealClarityApp());
    await tester.pumpAndSettle();

    final pages = find.byKey(const Key('primary-tab-page-view'));
    await tester.drag(pages, const Offset(-260, 0));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.byKey(const Key('nav-destination-1')))
          .toString(),
      contains('isSelected'),
    );

    await tester.drag(pages, const Offset(-260, 0));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.byKey(const Key('nav-destination-3')))
          .toString(),
      contains('isSelected'),
    );

    await tester.drag(pages, const Offset(260, 0));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.byKey(const Key('nav-destination-1')))
          .toString(),
      contains('isSelected'),
    );
  });

  testWidgets('bottom navigation skips intermediate destinations', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MealClarityApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-destination-4')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      tester
          .getSemantics(find.byKey(const Key('nav-destination-4')))
          .toString(),
      contains('isSelected'),
    );
    expect(
      tester
          .getSemantics(find.byKey(const Key('nav-destination-1')))
          .toString(),
      isNot(contains('isSelected')),
    );
    expect(
      tester
          .getSemantics(find.byKey(const Key('nav-destination-3')))
          .toString(),
      isNot(contains('isSelected')),
    );
    expect(find.text('Profil'), findsWidgets);
  });

  testWidgets('bottom navigation uses one interruptible sliding indicator', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MealClarityApp());
    await tester.pumpAndSettle();

    AnimatedAlign indicator() => tester.widget<AnimatedAlign>(
      find.byKey(const Key('bottom-nav-selection-indicator')),
    );

    expect(indicator().alignment, Alignment.centerLeft);
    final surfaceRect = tester.getRect(
      find.byKey(const Key('liquid-glass-navigation-surface')),
    );
    final fillRect = tester.getRect(
      find.byKey(const Key('bottom-nav-selection-fill')),
    );
    // The selection fills the bar's content box; only the 1 px outline stays
    // visible around it.
    expect(fillRect.left, closeTo(surfaceRect.left + 1, 0.01));
    expect(fillRect.top, closeTo(surfaceRect.top + 1, 0.01));
    expect(fillRect.height, closeTo(surfaceRect.height - 2, 0.01));
    expect(fillRect.width, closeTo((surfaceRect.width - 2) / 5, 0.01));

    await tester.tap(find.byKey(const Key('nav-destination-1')));
    await tester.pump(const Duration(milliseconds: 40));
    expect(indicator().alignment, const Alignment(-0.5, 0));
    final pages = tester.widget<PageView>(
      find.byKey(const Key('primary-tab-page-view')),
    );
    expect(pages.controller!.page, 1);

    await tester.tap(find.byKey(const Key('nav-destination-3')));
    await tester.pump(const Duration(milliseconds: 40));
    expect(indicator().alignment, const Alignment(0.5, 0));
    expect(
      tester
          .getSemantics(find.byKey(const Key('nav-destination-3')))
          .toString(),
      contains('isSelected'),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('selected bottom tab can be held and scrubbed to a destination', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MealClarityApp());
    await tester.pumpAndSettle();

    AnimatedAlign indicator() => tester.widget<AnimatedAlign>(
      find.byKey(const Key('bottom-nav-selection-indicator')),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('nav-destination-0'))),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(
      tester.getCenter(find.byKey(const Key('nav-destination-3'))),
    );
    await tester.pump();

    expect((indicator().alignment as Alignment).x, closeTo(0.5, 0.01));
    expect(indicator().duration, Duration.zero);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      tester
          .getSemantics(find.byKey(const Key('nav-destination-3')))
          .toString(),
      contains('isSelected'),
    );
    expect(find.text('Analiz'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('analysis period survives tab changes', (tester) async {
    await tester.pumpWidget(const MealClarityApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-destination-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('analysis-period-30')));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.byKey(const Key('analysis-period-30')))
          .toString(),
      contains('isSelected'),
    );

    await tester.tap(find.byKey(const Key('nav-destination-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-destination-3')));
    await tester.pumpAndSettle();

    expect(
      tester
          .getSemantics(find.byKey(const Key('analysis-period-30')))
          .toString(),
      contains('isSelected'),
    );
  });

  testWidgets('analysis period indicator replaces interrupted selection', (
    tester,
  ) async {
    await tester.pumpWidget(const MealClarityApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-destination-3')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('analysis-period-30')));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.byKey(const Key('analysis-period-90')));
    await tester.pump(const Duration(milliseconds: 40));

    final indicator = tester.widget<AnimatedAlign>(
      find.byKey(const Key('analysis-period-indicator')),
    );
    expect(indicator.alignment, Alignment.centerRight);
    expect(
      tester
          .getSemantics(find.byKey(const Key('analysis-period-90')))
          .toString(),
      contains('isSelected'),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('navigation and period selection respect reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MealClarityApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-destination-3')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('analysis-period-90')));
    await tester.pump();

    final indicator = tester.widget<AnimatedAlign>(
      find.byKey(const Key('analysis-period-indicator')),
    );
    expect(indicator.duration, Duration.zero);
    expect(indicator.alignment, Alignment.centerRight);
    expect(tester.takeException(), isNull);
  });

  testWidgets('primary tabs remain usable at 200 percent text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MealClarityApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    for (final index in [1, 3, 4, 0]) {
      await tester.tap(find.byKey(Key('nav-destination-$index')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await tester.tap(find.byKey(const Key('nav-destination-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('add-meal-camera')), findsOneWidget);
    expect(find.byKey(const Key('add-meal-gallery')), findsOneWidget);
    expect(find.byKey(const Key('add-meal-text')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('add meal sheet centers copy and camera action fills width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MealClarityApp());

    await tester.tap(find.byKey(const Key('nav-destination-2')));
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(find.text('Öğün ekle'));
    final subtitle = tester.widget<Text>(
      find.text('Yemeğini göster,\ngerisini birlikte halledelim.'),
    );
    expect(title.textAlign, TextAlign.center);
    expect(subtitle.textAlign, TextAlign.center);
    expect(
      tester.getSize(find.byKey(const Key('add-meal-camera'))).width,
      greaterThanOrEqualTo(350),
    );
  });

  testWidgets('text analysis loading state fills and centers the body', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MealClarityApp());

    await tester.tap(find.byKey(const Key('quick-composer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-meal-text')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('meal-input')), 'iki yumurta');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('analyze-button')));
    await tester.tap(find.byKey(const Key('analyze-button')));
    await tester.pump();

    final loading = find.byKey(const Key('analysis-loading-center'));
    expect(loading, findsOneWidget);
    expect(tester.getSize(loading).height, greaterThan(600));
    expect(tester.getCenter(loading).dx, closeTo(195, 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets('shell respects notches, side cutouts, and the home indicator', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const safeInsets = EdgeInsets.fromLTRB(20, 59, 20, 34);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: safeInsets,
            viewPadding: safeInsets,
          ),
          child: const MealClarityShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final surface = find.byKey(const Key('liquid-glass-navigation-surface'));
    expect(tester.getSize(surface).height, 62);
    expect(tester.getBottomRight(surface).dy, lessThanOrEqualTo(844 - 34));
    expect(
      tester.getTopLeft(find.text('Bugün').first).dy,
      greaterThanOrEqualTo(59),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('analysis only draws a trend after three active days', (
    tester,
  ) async {
    final now = DateTime.now();
    const item = MealItem(
      id: 'egg',
      name: 'Yumurta',
      sourceText: 'yumurta',
      portionLabel: '2 adet',
      grams: 100,
      nutritionPer100g: Nutrition(
        calories: 155,
        protein: 13,
        carbs: 1,
        fat: 11,
      ),
      matchState: MatchState.matched,
    );
    final meals = List.generate(
      3,
      (index) => LoggedMeal(
        id: 'meal-$index',
        name: 'Kahvaltı',
        timeLabel: '08:30',
        items: const [item],
        occurredAt: now.subtract(Duration(days: index)),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AnalysisScreen(
          meals: meals,
          goals: NutritionGoals.fallback,
          onAddMeal: () {},
          onMealTap: (_) {},
          onNavigationSelected: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calorie-trend-chart')), findsOneWidget);
    expect(find.text('Henüz yeterli veri yok'), findsNothing);
  });

  for (final width in [320.0, 360.0, 375.0, 390.0, 430.0]) {
    testWidgets('primary dashboard and add meal fit at ${width.round()} px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MealClarityApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('quick-composer')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('add-meal-camera')), findsOneWidget);
      expect(find.byKey(const Key('add-meal-gallery')), findsOneWidget);
      expect(find.byKey(const Key('add-meal-text')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

class _InjectedRepository implements MealRepository {
  String? input;

  @override
  Future<MealDraft> analyze(MealAnalysisInput input) async {
    this.input = input.text;
    return const MealDraft(
      inputText: 'iki yumurta',
      mealName: 'Kahvaltı',
      analysisRunId: 'analysis-run',
      traceId: 'trace-id',
      items: [
        MealItem(
          id: 'item-1',
          foodId: 'food-1',
          name: 'Sunucudan Yumurta',
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
        ),
      ],
    );
  }
}
