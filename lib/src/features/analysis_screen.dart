import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../domain/models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_surfaces.dart';
import '../widgets/liquid_glass_bottom_bar.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({
    required this.meals,
    required this.onMealTap,
    required this.onNavigationSelected,
    this.selectedDays,
    this.onSelectedDaysChanged,
    this.showBottomNavigationBar = true,
    super.key,
  });

  final List<LoggedMeal> meals;
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
    setState(() => _localSelectedDays = days);
    widget.onSelectedDaysChanged?.call(days);
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
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 104),
              sliver: SliverList.list(
                children: [
                  Text(
                    context.ota('analysisTitle', tr: 'Analiz', en: 'Analysis'),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 18),
                  _PeriodSelector(
                    selectedDays: _selectedDays,
                    onChanged: _selectDays,
                  ),
                  const SizedBox(height: 18),
                  if (meals.isEmpty)
                    const _EmptyAnalysis()
                  else if (activeDays < 3)
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
                    ),
                    const SizedBox(height: 12),
                    _InsightStrip(
                      currentCalories: average,
                      previousCalories: previousAverage,
                      hasPreviousData: previousMeals.isNotEmpty,
                    ),
                    if (activeDays < 7) ...[
                      const SizedBox(height: 10),
                      Text(
                        context.ota(
                          'analysisEarlyTrend',
                          tr: 'Bu ilk eğilim; daha fazla aktif gün eklendikçe daha güvenilir olacak.',
                          en: 'This is an early trend; it will become more reliable as you add active days.',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 24),
                    _Overview(
                      mealCount: meals.length,
                      activeDays: activeDays,
                      averageCalories: average,
                      averageProtein: averageProtein,
                      highestMeal: highestMeal!,
                    ),
                    const SizedBox(height: 26),
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
                    const SizedBox(height: 11),
                    for (final meal in meals)
                      _AnalysisMealRow(
                        meal: meal,
                        onTap: () => widget.onMealTap(meal),
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
    return Container(
      key: const Key('analysis-period-selector'),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Row(
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
    );
  }
}

class _PeriodSegment extends StatelessWidget {
  const _PeriodSegment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
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
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: selected ? Border.all(color: AppColors.separator) : null,
              boxShadow: selected ? AppShadows.card : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? AppColors.ink : AppColors.muted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
              const SizedBox(height: 12),
              Text(
                context.ota(
                  'analysisInsufficientTitle',
                  tr: 'Henüz yeterli veri yok',
                  en: 'Not enough data yet',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                context.ota(
                  'analysisInsufficientBody',
                  tr: 'Beslenme değişimini gösterebilmemiz için birkaç farklı günde öğün kaydetmen gerekiyor.',
                  en: 'Log meals on a few different days so we can show how your nutrition changes.',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              if (largeText)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CurrentMetric(
                      value: '${nutrition.calories.round()} kcal',
                      label: context.ota(
                        'metricCalories',
                        tr: 'Kalori',
                        en: 'Calories',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CurrentMetric(
                      value: '${nutrition.protein.round()} g',
                      label: context.l10n.macroProtein,
                    ),
                    const SizedBox(height: 14),
                    _CurrentMetric(
                      value: '$mealCount',
                      label: context.ota(
                        'metricMeals',
                        tr: 'Öğün',
                        en: 'Meals',
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 7,
                          value: activeDays / 3,
                          backgroundColor: AppColors.line,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.limeDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.ota(
                        'activeDaysProgress',
                        tr: '{count} / 3 aktif gün',
                        en: '{count} / 3 active days',
                        replacements: {'count': activeDays},
                      ),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _CurrentMetric(
                      value: '${nutrition.calories.round()} kcal',
                      label: context.ota(
                        'metricCalories',
                        tr: 'Kalori',
                        en: 'Calories',
                      ),
                    ),
                  ),
                  Expanded(
                    child: _CurrentMetric(
                      value: '${nutrition.protein.round()} g',
                      label: context.l10n.macroProtein,
                    ),
                  ),
                  Expanded(
                    child: _CurrentMetric(
                      value: '$mealCount',
                      label: context.ota(
                        'metricMeals',
                        tr: 'Öğün',
                        en: 'Meals',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
        const SizedBox(height: 3),
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
  });

  final int days;
  final List<double> values;
  final double averageCalories;

  @override
  Widget build(BuildContext context) {
    return HeroCardSurface(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
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
          const SizedBox(height: 5),
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
          const SizedBox(height: 18),
          Semantics(
            label: context.ota(
              'calorieTrendSemantics',
              tr: '{days} günlük kalori trendi',
              en: '{days}-day calorie trend',
              replacements: {'days': days},
            ),
            child: SizedBox(
              key: const Key('calorie-trend-chart'),
              height: 132,
              width: double.infinity,
              child: CustomPaint(painter: _TrendPainter(values)),
            ),
          ),
          const SizedBox(height: 8),
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
  const _TrendPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var row = 0; row < 3; row++) {
      final y = size.height * row / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final maxValue = math.max(2100.0, values.fold(0.0, math.max));
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

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.values != values;
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.trending_up_rounded,
            size: 18,
            color: AppColors.muted,
          ),
          const SizedBox(width: 8),
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
          const SizedBox(height: 14),
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
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _OverviewGroup(
                  title: context.ota(
                    'dailyAverageTitle',
                    tr: 'Günlük ortalama',
                    en: 'Daily average',
                  ),
                  primary: '${averageCalories.round()} kcal',
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
                    primary: '${averageCalories.round()} kcal',
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
          const SizedBox(height: 18),
          Text(
            context.ota(
              'highestCalorieMeal',
              tr: 'En yüksek kalorili öğün',
              en: 'Highest-calorie meal',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
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
    margin: const EdgeInsets.symmetric(horizontal: 18),
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
        const SizedBox(height: 5),
        Text(primary, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(secondary, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _AnalysisMealRow extends StatelessWidget {
  const _AnalysisMealRow({required this.meal, required this.onTap});

  final LoggedMeal meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meal.timeLabel,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  context.ota(
                    'calorieAmount',
                    tr: '{amount} kcal',
                    en: '{amount} kcal',
                    replacements: {'amount': meal.nutrition.calories.round()},
                  ),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyAnalysis extends StatelessWidget {
  const _EmptyAnalysis();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.feature),
      ),
      child: Column(
        children: [
          const Icon(Icons.show_chart_rounded, size: 38),
          const SizedBox(height: 13),
          Text(
            context.ota(
              'analysisEmptyTitle',
              tr: 'Bu dönemde kayıt yok',
              en: 'No entries in this period',
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            context.ota(
              'analysisEmptyBody',
              tr: 'Öğün ekledikçe kalori trendin ve dönem karşılaştırman burada oluşacak.',
              en: 'Your calorie trend and period comparison will appear here as you add meals.',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
