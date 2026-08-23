import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../domain/models.dart';
import '../theme/app_theme.dart';
import '../util/formatters.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/app_surfaces.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/liquid_glass_bottom_bar.dart';
import '../widgets/loading_placeholders.dart';
import '../widgets/meal_list_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    required this.meals,
    required this.onAddMeal,
    required this.onMealTap,
    required this.onNavigationSelected,
    this.selectedDayIndex,
    this.onSelectedDayIndexChanged,
    this.isLoading = false,
    this.onDeleteMeal,
    this.showBottomNavigationBar = true,
    super.key,
  });

  final List<LoggedMeal> meals;
  final VoidCallback onAddMeal;
  final ValueChanged<LoggedMeal> onMealTap;
  final ValueChanged<int> onNavigationSelected;
  final int? selectedDayIndex;
  final ValueChanged<int>? onSelectedDayIndexChanged;

  /// True while history has not been read yet — see [TodayScreen.isLoading].
  final bool isLoading;

  final ValueChanged<LoggedMeal>? onDeleteMeal;
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
              padding: EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.page,
                AppSpacing.page,
                AppSpacing.pageBottom(context),
              ),
              sliver: SliverList.list(
                children: [
                  Text(
                    context.ota('historyTitle', tr: 'Geçmiş', en: 'History'),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (widget.isLoading)
                    SkeletonGroup(
                      label: context.ota(
                        'historyLoading',
                        tr: 'Geçmişin yükleniyor',
                        en: 'Loading your history',
                      ),
                      child: const Column(
                        children: [
                          SkeletonBox(width: null, height: 110, radius: 24),
                          SizedBox(height: AppSpacing.xl),
                          MealListSkeleton(rows: 4),
                        ],
                      ),
                    )
                  else if (selectedDay == null)
                    _EmptyHistory(onAddMeal: widget.onAddMeal)
                  else ...[
                    if (days.length > 1) ...[
                      _DayRail(
                        days: days,
                        selectedIndex: safeIndex,
                        onSelected: _selectDay,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    StandardCardSurface(
                      child: Column(
                        children: [
                          Text(
                            formatFullDate(context, selectedDay),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
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
                          const SizedBox(height: AppSpacing.xs),
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
                    const SizedBox(height: AppSpacing.xl),
                    for (final meal in selectedMeals)
                      MealListTile(
                        meal: meal,
                        onTap: () => widget.onMealTap(meal),
                        onDelete: widget.onDeleteMeal == null
                            ? null
                            : () => widget.onDeleteMeal!(meal),
                        subtitle: context.ota(
                          'mealFoodCount',
                          tr: '{time} · {count} yiyecek',
                          en: '{time} · {count} foods',
                          replacements: {
                            'time': meal.timeLabel,
                            'count': meal.items.length,
                          },
                        ),
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
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final day = days[index];
          final selected = index == selectedIndex;
          return Semantics(
            button: true,
            selected: selected,
            // The rail filters the day below it; the bare date read as a
            // heading rather than as a control.
            label: context.ota(
              'historyDayFilterSemantics',
              tr: '{date} gününü göster',
              en: 'Show {date}',
              replacements: {'date': formatFullDate(context, day)},
            ),
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
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          formatShortWeekday(context, day),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: selected
                                    ? AppColors.ink
                                    : AppColors.muted,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.micro),
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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onAddMeal});

  final VoidCallback onAddMeal;

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: Icons.calendar_month_rounded,
      title: context.ota(
        'historyEmptyTitle',
        tr: 'Henüz geçmiş öğün yok',
        en: 'No meal history yet',
      ),
      body: context.ota(
        'historyEmptyBody',
        tr: 'Kaydettiğin öğünler burada günlere göre görünecek.',
        en: 'Meals you log will appear here grouped by day.',
      ),
      actionKey: const Key('history-empty-action'),
      actionLabel: context.ota(
        'historyEmptyAction',
        tr: 'İlk öğünü ekle',
        en: 'Add your first meal',
      ),
      onAction: onAddMeal,
    );
  }
}
