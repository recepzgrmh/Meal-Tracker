import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../domain/models.dart';
import '../domain/nutrition_goals.dart';
import '../theme/app_theme.dart';
import '../widgets/app_surfaces.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/liquid_glass_bottom_bar.dart';
import '../widgets/meal_list_tile.dart';

/// Fully rounded ends for a progress track. `AppRadius` stops at 28 because its
/// steps describe cards; a pill only needs "at least half the track height".
const _pillRadius = 99.0;

/// A line through one or two days is noise, not a trend, so the chart only
/// appears once the period holds this many days with entries.
const _trendMinimumActiveDays = 3;

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({
    required this.meals,
    required this.goals,
    required this.onAddMeal,
    required this.onMealTap,
    required this.onNavigationSelected,
    this.selectedDays,
    this.onSelectedDaysChanged,
    this.showBottomNavigationBar = true,
    super.key,
  });

  final List<LoggedMeal> meals;
  final NutritionGoals goals;
  final VoidCallback onAddMeal;
  final ValueChanged<LoggedMeal> onMealTap;
  final ValueChanged<int> onNavigationSelected;
  final int? selectedDays;
  final ValueChanged<int>? onSelectedDaysChanged;
  final bool showBottomNavigationBar;

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  late int _localSelectedDays;

  int get _selectedDays => widget.selectedDays ?? _localSelectedDays;

  @override
  void initState() {
    super.initState();
    _localSelectedDays = widget.selectedDays ?? 7;
  }

  void _selectDays(int days) {
    if (days == _selectedDays) return;
    final onChanged = widget.onSelectedDaysChanged;
    if (widget.selectedDays == null || onChanged == null) {
      setState(() => _localSelectedDays = days);
    }
    onChanged?.call(days);
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _dateOf(LoggedMeal meal) {
    final value = meal.occurredAt ?? _today;
    return DateTime(value.year, value.month, value.day);
  }

  List<LoggedMeal> get _periodMeals {
    final start = _today.subtract(Duration(days: _selectedDays - 1));
    return widget.meals
        .where((meal) => !_dateOf(meal).isBefore(start))
        .toList(growable: false);
  }

  List<LoggedMeal> get _previousPeriodMeals {
    final currentStart = _today.subtract(Duration(days: _selectedDays - 1));
    final previousStart = currentStart.subtract(Duration(days: _selectedDays));
    return widget.meals
        .where((meal) {
          final date = _dateOf(meal);
          return !date.isBefore(previousStart) && date.isBefore(currentStart);
        })
        .toList(growable: false);
  }

  Nutrition _sum(Iterable<LoggedMeal> meals) =>
      meals.fold(Nutrition.zero, (total, meal) => total + meal.nutrition);

  List<double> get _dailyCalories {
    final start = _today.subtract(Duration(days: _selectedDays - 1));
    return List.generate(_selectedDays, (index) {
      final day = start.add(Duration(days: index));
      return _periodMeals
          .where((meal) => _dateOf(meal) == day)
          .fold(0.0, (total, meal) => total + meal.nutrition.calories);
    });
  }

  @override
  Widget build(BuildContext context) {
    final meals = _periodMeals;
    final total = _sum(meals);
    final activeDays = _dailyCalories.where((value) => value > 0).length;
    final average = activeDays == 0 ? 0.0 : total.calories / activeDays;
    final averageProtein = activeDays == 0 ? 0.0 : total.protein / activeDays;
    final previousMeals = _previousPeriodMeals;
    final previousTotal = _sum(previousMeals);
    final previousActiveDays = previousMeals.map(_dateOf).toSet().length;
    final previousAverage = previousActiveDays == 0
        ? 0.0
        : previousTotal.calories / previousActiveDays;
    final highestMeal = meals.isEmpty
        ? null
        : meals.reduce(
            (left, right) => left.nutrition.calories >= right.nutrition.calories
                ? left
                : right,
          );

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.lg,
                AppSpacing.page,
                AppSpacing.pageBottom(context),
              ),
              sliver: SliverList.list(
                children: [
                  Text(
                    context.ota('analysisTitle', tr: 'Analiz', en: 'Analysis'),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PeriodSelector(
                    selectedDays: _selectedDays,
                    onChanged: _selectDays,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (meals.isEmpty)
                    _EmptyAnalysis(onAddMeal: widget.onAddMeal)
                  else if (activeDays < _trendMinimumActiveDays)
                    _InsufficientAnalysis(
                      activeDays: activeDays,
                      mealCount: meals.length,
                      nutrition: total,
                    )
                  else ...[
                    _TrendPanel(
                      days: _selectedDays,
                      values: _dailyCalories,
                      averageCalories: average,
                      goalCalories: widget.goals.calories,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _InsightStrip(
                      currentCalories: average,
                      previousCalories: previousAverage,
                      hasPreviousData: previousMeals.isNotEmpty,
                    ),
                    if (activeDays < 7) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        context.ota(
                          'analysisEarlyTrend',
                          tr: 'Bu ilk eğilim; daha fazla aktif gün eklendikçe daha güvenilir olacak.',
                          en: 'This is an early trend; it will become more reliable as you add active days.',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    _Overview(
                      mealCount: meals.length,
                      activeDays: activeDays,
                      averageCalories: average,
                      averageProtein: averageProtein,
                      highestMeal: highestMeal!,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.ota(
                              'analysisPeriodMeals',
                              tr: 'Dönemdeki öğünler',
                              en: 'Meals in this period',
                            ),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Text(
                          context.ota(
                            'recordCount',
                            tr: '{count} kayıt',
                            en: '{count} entries',
                            replacements: {'count': meals.length},
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final meal in meals)
                      MealListTile(
                        meal: meal,
                        onTap: () => widget.onMealTap(meal),
                        showThumbnail: false,
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNavigationBar
          ? LiquidGlassBottomBar(
              selectedIndex: 3,
              onDestinationSelected: widget.onNavigationSelected,
            )
          : null,
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selectedDays, required this.onChanged});

  final int selectedDays;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Container(
      key: const Key('analysis-period-selector'),
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              key: const Key('analysis-period-indicator'),
              alignment: switch (selectedDays) {
                30 => Alignment.center,
                90 => Alignment.centerRight,
                _ => Alignment.centerLeft,
              },
              duration: reduceMotion ? Duration.zero : AppMotion.fast,
              curve: Curves.easeOutCubic,
              child: FractionallySizedBox(
                widthFactor: 1 / 3,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(color: AppColors.separator),
                    boxShadow: AppShadows.card,
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              _PeriodSegment(
                key: const Key('analysis-period-7'),
                label: context.ota('period7Days', tr: '7 Gün', en: '7 Days'),
                selected: selectedDays == 7,
                onTap: () => onChanged(7),
              ),
              _PeriodSegment(
                key: const Key('analysis-period-30'),
                label: context.ota('period30Days', tr: '30 Gün', en: '30 Days'),
                selected: selectedDays == 30,
                onTap: () => onChanged(30),
              ),
              _PeriodSegment(
                key: const Key('analysis-period-90'),
                label: context.ota('period3Months', tr: '3 Ay', en: '3 Months'),
                selected: selectedDays == 90,
                onTap: () => onChanged(90),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodSegment extends StatelessWidget {
  const _PeriodSegment({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppTouchTarget.minimum,
            ),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppMotion.fast,
                curve: Curves.easeOutCubic,
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: selected ? AppColors.ink : AppColors.muted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(label, textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InsufficientAnalysis extends StatelessWidget {
  const _InsufficientAnalysis({
    required this.activeDays,
    required this.mealCount,
    required this.nutrition,
  });

  final int activeDays;
  final int mealCount;
  final Nutrition nutrition;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(14) >= 20;
    final metrics = [
      _CurrentMetric(
        value: context.ota(
          'calorieAmount',
          tr: '{amount} kcal',
          en: '{amount} kcal',
          replacements: {'amount': nutrition.calories.round()},
        ),
        label: context.ota('metricCalories', tr: 'Kalori', en: 'Calories'),
      ),
      _CurrentMetric(
        value: context.ota(
          'gramAmount',
          tr: '{amount} g',
          en: '{amount} g',
          replacements: {'amount': nutrition.protein.round()},
        ),
        label: context.l10n.macroProtein,
      ),
      _CurrentMetric(
        value: '$mealCount',
        label: context.ota('metricMeals', tr: 'Öğün', en: 'Meals'),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeroCardSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.ota(
                  'nutritionTrendTitle',
                  tr: 'Beslenme trendin',
                  en: 'Your nutrition trend',
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.ota(
                  'analysisInsufficientTitle',
                  tr: 'Henüz yeterli veri yok',
                  en: 'Not enough data yet',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.ota(
                  'analysisInsufficientBody',
                  tr: 'Beslenme değişimini gösterebilmemiz için birkaç farklı günde öğün kaydetmen gerekiyor.',
                  en: 'Log meals on a few different days so we can show how your nutrition changes.',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              // The large-text branch used to drop the progress entirely and
              // show unrelated metrics; it now stacks the same information.
              _ActiveDaysProgress(activeDays: activeDays, stacked: largeText),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        StandardCardSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activeDays == 1
                    ? context.ota(
                        'todayEntry',
                        tr: 'Bugünkü kayıt',
                        en: "Today's entry",
                      )
                    : context.ota(
                        'currentEntries',
                        tr: 'Mevcut kayıtlar',
                        en: 'Current entries',
                      ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              if (largeText)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < metrics.length; index++) ...[
                      if (index > 0) const SizedBox(height: AppSpacing.md),
                      metrics[index],
                    ],
                  ],
                )
              else
                Row(
                  children: [
                    for (final metric in metrics) Expanded(child: metric),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveDaysProgress extends StatelessWidget {
  const _ActiveDaysProgress({required this.activeDays, required this.stacked});

  final int activeDays;

  /// Large text cannot fit a bar and its label side by side.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(_pillRadius),
      child: LinearProgressIndicator(
        minHeight: AppSpacing.xs,
        value: activeDays / _trendMinimumActiveDays,
        backgroundColor: AppColors.line,
        valueColor: const AlwaysStoppedAnimation(AppColors.limeDark),
      ),
    );
    final label = Text(
      context.ota(
        'activeDaysProgress',
        tr: '{count} / 3 aktif gün',
        en: '{count} / 3 active days',
        replacements: {'count': activeDays},
      ),
      style: Theme.of(context).textTheme.labelLarge,
    );
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: double.infinity, child: bar),
        const SizedBox(height: AppSpacing.sm),
        label,
      ],
    );
    if (stacked) return column;

    // Stacking was decided by text scale alone, but the label is laid out at
    // its natural width next to an Expanded bar — so a narrow screen, or a
    // locale whose phrasing is longer than Turkish, leaves the bar negative
    // space and the row paints an overflow stripe. Width decides too, the same
    // way DailySummaryCard already does it.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 260) return column;
        return Row(
          children: [
            Expanded(child: bar),
            const SizedBox(width: AppSpacing.sm),
            label,
          ],
        );
      },
    );
  }
}

class _CurrentMetric extends StatelessWidget {
  const _CurrentMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xxs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _TrendPanel extends StatelessWidget {
  const _TrendPanel({
    required this.days,
    required this.values,
    required this.averageCalories,
    required this.goalCalories,
  });

  final int days;
  final List<double> values;
  final double averageCalories;
  final double goalCalories;

  /// Longest range read out day by day. Beyond this the label summarises
  /// rather than reciting ninety numbers.
  static const _perDayReadoutLimit = 7;

  /// Relative change below which the period counts as flat.
  static const _flatThreshold = 0.05;

  double _mean(Iterable<double> input) {
    final logged = input.where((value) => value > 0).toList(growable: false);
    if (logged.isEmpty) return 0;
    return logged.reduce((left, right) => left + right) / logged.length;
  }

  /// The chart is a [CustomPaint], so assistive tech previously got the range
  /// name and nothing else. This puts the actual numbers into the label.
  String _describe(BuildContext context) {
    final headline = context.ota(
      'calorieTrendSemantics',
      tr: '{days} günlük kalori trendi',
      en: '{days}-day calorie trend',
      replacements: {'days': days},
    );
    final logged = values.where((value) => value > 0).toList(growable: false);
    if (logged.isEmpty) return headline;
    if (values.length <= _perDayReadoutLimit) {
      final readout = values
          .map(
            (value) => context.ota(
              'calorieAmount',
              tr: '{amount} kcal',
              en: '{amount} kcal',
              replacements: {'amount': value.round()},
            ),
          )
          .join(', ');
      return '$headline: $readout';
    }
    final half = values.length ~/ 2;
    final opening = _mean(values.take(half));
    final closing = _mean(values.skip(half));
    final change = opening == 0 ? 0.0 : (closing - opening) / opening;
    final direction = change.abs() < _flatThreshold
        ? context.ota(
            'trendDirectionSteady',
            tr: 'dönem boyunca sabit',
            en: 'steady across the period',
          )
        : change > 0
        ? context.ota(
            'trendDirectionRising',
            tr: 'dönem boyunca yükseliyor',
            en: 'rising across the period',
          )
        : context.ota(
            'trendDirectionFalling',
            tr: 'dönem boyunca düşüyor',
            en: 'falling across the period',
          );
    return context.ota(
      'calorieTrendSummarySemantics',
      tr: '{headline}: ortalama {average} kcal, en düşük {lowest} kcal, en yüksek {highest} kcal, {direction}',
      en: '{headline}: {average} kcal average, {lowest} kcal lowest, {highest} kcal highest, {direction}',
      replacements: {
        'headline': headline,
        'average': averageCalories.round(),
        'lowest': logged.reduce(math.min).round(),
        'highest': logged.reduce(math.max).round(),
        'direction': direction,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return HeroCardSurface(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.ota(
              'dailyCaloriesTitle',
              tr: 'Günlük kalori',
              en: 'Daily calories',
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.tiny),
          Text.rich(
            TextSpan(
              text: '${averageCalories.round()}',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
              children: [
                TextSpan(
                  text: context.ota(
                    'averageCaloriesSuffix',
                    tr: ' kcal ortalama',
                    en: ' kcal average',
                  ),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            container: true,
            label: _describe(context),
            child: SizedBox(
              key: const Key('calorie-trend-chart'),
              height: 132,
              width: double.infinity,
              child: CustomPaint(
                painter: _TrendPainter(
                  values: values,
                  goalCalories: goalCalories,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.ota(
                  'daysAgo',
                  tr: '{days} gün önce',
                  en: '{days} days ago',
                  replacements: {'days': days},
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                context.ota('todayTitle', tr: 'Bugün', en: 'Today'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({required this.values, required this.goalCalories});

  final List<double> values;

  /// The chart's ceiling, so a day at target lands at the top gridline. This
  /// used to be a hard-coded 2100 regardless of what the user asked for.
  final double goalCalories;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var row = 0; row < 3; row++) {
      final y = size.height * row / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final maxValue = math.max(goalCalories, values.fold(0.0, math.max));
    if (maxValue <= 0) return;
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * index / (values.length - 1);
      final y = size.height - (values[index] / maxValue * size.height);
      points.add(Offset(x, y));
    }
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      path.lineTo(points[index].dx, points[index].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.limeDark
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (var index = 0; index < points.length; index++) {
      if (values[index] <= 0) continue;
      canvas.drawCircle(points[index], 4, Paint()..color = AppColors.limeDark);
      canvas.drawCircle(points[index], 2, Paint()..color = AppColors.surface);
    }
  }

  // `!=` on a List is identity comparison, so an in-place update of the same
  // length never repainted.
  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.goalCalories != goalCalories ||
      !listEquals(oldDelegate.values, values);
}

class _InsightStrip extends StatelessWidget {
  const _InsightStrip({
    required this.currentCalories,
    required this.previousCalories,
    required this.hasPreviousData,
  });

  final double currentCalories;
  final double previousCalories;
  final bool hasPreviousData;

  @override
  Widget build(BuildContext context) {
    final difference = previousCalories == 0
        ? 0
        : ((currentCalories - previousCalories) / previousCalories * 100)
              .round();
    final message = !hasPreviousData
        ? context.ota(
            'comparisonWaiting',
            tr: 'Karşılaştırma için önceki dönem kayıtlarını bekliyoruz.',
            en: 'Waiting for previous-period entries to compare.',
          )
        : difference == 0
        ? context.ota(
            'comparisonSame',
            tr: 'Günlük kalori ortalaman önceki dönemle aynı seviyede.',
            en: 'Your daily calorie average is unchanged from the previous period.',
          )
        : difference > 0
        ? context.ota(
            'comparisonHigher',
            tr: 'Günlük kalori ortalaman önceki döneme göre %{percent} daha yüksek.',
            en: 'Your daily calorie average is {percent}% higher than the previous period.',
            replacements: {'percent': difference.abs()},
          )
        : context.ota(
            'comparisonLower',
            tr: 'Günlük kalori ortalaman önceki döneme göre %{percent} daha düşük.',
            en: 'Your daily calorie average is {percent}% lower than the previous period.',
            replacements: {'percent': difference.abs()},
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          const Icon(
            Icons.trending_up_rounded,
            size: 18,
            color: AppColors.muted,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.mealCount,
    required this.activeDays,
    required this.averageCalories,
    required this.averageProtein,
    required this.highestMeal,
  });

  final int mealCount;
  final int activeDays;
  final double averageCalories;
  final double averageProtein;
  final LoggedMeal highestMeal;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(14) >= 20;
    final averageLabel = context.ota(
      'calorieAmount',
      tr: '{amount} kcal',
      en: '{amount} kcal',
      replacements: {'amount': averageCalories.round()},
    );
    return StandardCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.ota(
              'periodSummaryTitle',
              tr: 'Dönem özeti',
              en: 'Period summary',
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          if (largeText)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OverviewGroup(
                  key: const Key('analysis-meal-count'),
                  title: context.ota(
                    'activityTitle',
                    tr: 'Aktivite',
                    en: 'Activity',
                  ),
                  primary: context.ota(
                    'activeDaysCount',
                    tr: '{count} aktif gün',
                    en: '{count} active days',
                    replacements: {'count': activeDays},
                  ),
                  secondary: context.ota(
                    'mealCount',
                    tr: '{count} öğün',
                    en: '{count} meals',
                    replacements: {'count': mealCount},
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.md),
                _OverviewGroup(
                  title: context.ota(
                    'dailyAverageTitle',
                    tr: 'Günlük ortalama',
                    en: 'Daily average',
                  ),
                  primary: averageLabel,
                  secondary: context.ota(
                    'proteinAmount',
                    tr: '{amount} g protein',
                    en: '{amount} g protein',
                    replacements: {'amount': averageProtein.round()},
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _OverviewGroup(
                    key: const Key('analysis-meal-count'),
                    title: context.ota(
                      'activityTitle',
                      tr: 'Aktivite',
                      en: 'Activity',
                    ),
                    primary: context.ota(
                      'activeDaysCount',
                      tr: '{count} aktif gün',
                      en: '{count} active days',
                      replacements: {'count': activeDays},
                    ),
                    secondary: context.ota(
                      'mealCount',
                      tr: '{count} öğün',
                      en: '{count} meals',
                      replacements: {'count': mealCount},
                    ),
                  ),
                ),
                const _VerticalDivider(),
                Expanded(
                  child: _OverviewGroup(
                    title: context.ota(
                      'dailyAverageTitle',
                      tr: 'Günlük ortalama',
                      en: 'Daily average',
                    ),
                    primary: averageLabel,
                    secondary: context.ota(
                      'proteinAmount',
                      tr: '{amount} g protein',
                      en: '{amount} g protein',
                      replacements: {'amount': averageProtein.round()},
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.ota(
              'highestCalorieMeal',
              tr: 'En yüksek kalorili öğün',
              en: 'Highest-calorie meal',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            context.ota(
              'highestMealSummary',
              tr: '{meal} · {calories} kcal',
              en: '{meal} · {calories} kcal',
              replacements: {
                'meal': highestMeal.name,
                'calories': highestMeal.nutrition.calories.round(),
              },
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 46,
    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    color: AppColors.line,
  );
}

class _OverviewGroup extends StatelessWidget {
  const _OverviewGroup({
    required this.title,
    required this.primary,
    required this.secondary,
    super.key,
  });

  final String title;
  final String primary;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.tiny),
        Text(primary, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.micro),
        Text(secondary, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _EmptyAnalysis extends StatelessWidget {
  const _EmptyAnalysis({required this.onAddMeal});

  final VoidCallback onAddMeal;

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: Icons.show_chart_rounded,
      title: context.ota(
        'analysisEmptyTitle',
        tr: 'Bu dönemde kayıt yok',
        en: 'No entries in this period',
      ),
      body: context.ota(
        'analysisEmptyBody',
        tr: 'Öğün ekledikçe kalori trendin ve dönem karşılaştırman burada oluşacak.',
        en: 'Your calorie trend and period comparison will appear here as you add meals.',
      ),
      actionKey: const Key('analysis-empty-action'),
      actionLabel: context.ota(
        'analysisEmptyAction',
        tr: 'Öğün ekle',
        en: 'Add a meal',
      ),
      onAction: onAddMeal,
    );
  }
}
