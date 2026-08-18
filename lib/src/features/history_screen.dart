import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_surfaces.dart';
import '../widgets/liquid_glass_bottom_bar.dart';
import '../../l10n/l10n.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    required this.meals,
    required this.onMealTap,
    required this.onNavigationSelected,
    this.selectedDayIndex,
    this.onSelectedDayIndexChanged,
    this.showBottomNavigationBar = true,
    super.key,
  });

  final List<LoggedMeal> meals;
  final ValueChanged<LoggedMeal> onMealTap;
  final ValueChanged<int> onNavigationSelected;
  final int? selectedDayIndex;
  final ValueChanged<int>? onSelectedDayIndexChanged;
  final bool showBottomNavigationBar;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _localSelectedDayIndex = 0;

  int get _selectedDayIndex =>
      widget.selectedDayIndex ?? _localSelectedDayIndex;

  void _selectDay(int index) {
    setState(() => _localSelectedDayIndex = index);
    widget.onSelectedDayIndexChanged?.call(index);
  }

  List<DateTime> get _days {
    final values = widget.meals
        .map((meal) => meal.occurredAt)
        .whereType<DateTime>()
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet()
        .toList(growable: false);
    values.sort((left, right) => right.compareTo(left));
    return values;
  }

  List<LoggedMeal> _mealsFor(DateTime day) => widget.meals
      .where((meal) {
        final date = meal.occurredAt;
        return date != null &&
            date.year == day.year &&
            date.month == day.month &&
            date.day == day.day;
      })
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final days = _days;
    final safeIndex = days.isEmpty
        ? 0
        : _selectedDayIndex.clamp(0, days.length - 1);
    final selectedDay = days.isEmpty ? null : days[safeIndex];
    final selectedMeals = selectedDay == null
        ? const <LoggedMeal>[]
        : _mealsFor(selectedDay);
    final nutrition = selectedMeals.fold(
      Nutrition.zero,
      (total, meal) => total + meal.nutrition,
    );
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 96),
              sliver: SliverList.list(
                children: [
                  Text(
                    context.ota('historyTitle', tr: 'Geçmiş', en: 'History'),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 24),
                  if (selectedDay == null)
                    const _EmptyHistory()
                  else ...[
                    if (days.length > 1) ...[
                      _DayRail(
                        days: days,
                        selectedIndex: safeIndex,
                        onSelected: _selectDay,
                      ),
                      const SizedBox(height: 16),
                    ],
                    StandardCardSurface(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        children: [
                          Text(
                            _formatHistoryDate(
                              selectedDay,
                              Localizations.localeOf(context).languageCode,
                            ),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.ota(
                              'calorieAmount',
                              tr: '{amount} kcal',
                              en: '{amount} kcal',
                              replacements: {
                                'amount': nutrition.calories.round(),
                              },
                            ),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 7),
                          Text(
                            context.ota(
                              'historySummary',
                              tr: '{count} öğün · {protein} g protein',
                              en: '{count} meals · {protein} g protein',
                              replacements: {
                                'count': selectedMeals.length,
                                'protein': nutrition.protein.round(),
                              },
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    for (
                      var index = 0;
                      index < selectedMeals.length;
                      index++
                    ) ...[
                      _HistoryMealCard(
                        meal: selectedMeals[index],
                        onTap: () => widget.onMealTap(selectedMeals[index]),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNavigationBar
          ? LiquidGlassBottomBar(
              selectedIndex: 1,
              onDestinationSelected: widget.onNavigationSelected,
            )
          : null,
    );
  }
}

class _DayRail extends StatelessWidget {
  const _DayRail({
    required this.days,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<DateTime> days;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final selected = index == selectedIndex;
          return Semantics(
            button: true,
            selected: selected,
            label: _formatHistoryDate(day, languageCode),
            child: Material(
              color: selected ? AppColors.lime : AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                side: BorderSide(
                  color: selected ? AppColors.limeDark : AppColors.line,
                ),
              ),
              child: InkWell(
                key: Key('history-day-$index'),
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.circular(AppRadius.input),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 64),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _shortWeekday(day, languageCode),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: selected
                                    ? AppColors.ink
                                    : AppColors.muted,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${day.day}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _shortWeekday(DateTime date, String languageCode) {
  const tr = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return (languageCode == 'en' ? en : tr)[date.weekday - 1];
}

String _formatHistoryDate(DateTime date, String languageCode) {
  const trWeekdays = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];
  const trMonths = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
  const enWeekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const enMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final english = languageCode == 'en';
  final weekdays = english ? enWeekdays : trWeekdays;
  final months = english ? enMonths : trMonths;
  return '${date.day} ${months[date.month - 1]}, '
      '${weekdays[date.weekday - 1]}';
}

class _HistoryMealCard extends StatelessWidget {
  const _HistoryMealCard({required this.meal, required this.onTap});

  final LoggedMeal meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.compactCard),
          boxShadow: AppShadows.card,
        ),
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.compactCard),
            side: const BorderSide(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    child: SizedBox.square(
                      dimension: 88,
                      child: meal.imageAsset == null
                          ? const ColoredBox(
                              color: AppColors.canvas,
                              child: Icon(Icons.restaurant_rounded),
                            )
                          : Image.asset(meal.imageAsset!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          context.ota(
                            'mealFoodCount',
                            tr: '{time} · {count} yiyecek',
                            en: '{time} · {count} foods',
                            replacements: {
                              'time': meal.timeLabel,
                              'count': meal.items.length,
                            },
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${meal.nutrition.calories.round()}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'kcal',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Text(
            context.ota(
              'historyEmptyTitle',
              tr: 'Henüz geçmiş öğün yok',
              en: 'No meal history yet',
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            context.ota(
              'historyEmptyBody',
              tr: 'Kaydettiğin öğünler burada günlere göre görünecek.',
              en: 'Meals you log will appear here grouped by day.',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
