import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../domain/models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_surfaces.dart';
import '../widgets/liquid_glass_bottom_bar.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    super.key,
    required this.meals,
    required this.onAddMeal,
    required this.onMealTap,
    required this.onNavigationSelected,
    this.showBottomNavigationBar = true,
  });

  final List<LoggedMeal> meals;
  final VoidCallback onAddMeal;
  final ValueChanged<LoggedMeal> onMealTap;
  final ValueChanged<int> onNavigationSelected;
  final bool showBottomNavigationBar;

  Nutrition get _total =>
      meals.fold(Nutrition.zero, (total, meal) => total + meal.nutrition);

  @override
  Widget build(BuildContext context) {
    final total = _total;
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 104),
              sliver: SliverList.list(
                children: [
                  const _TodayHeader(),
                  const SizedBox(height: 18),
                  _DailySummary(total: total),
                  const SizedBox(height: 12),
                  _QuickComposer(onTap: onAddMeal),
                  const SizedBox(height: 26),
                  _SectionHeader(
                    title: context.ota(
                      'todayMealsTitle',
                      tr: 'Bugünün öğünleri',
                      en: "Today's meals",
                    ),
                    detail: context.ota(
                      'mealCount',
                      tr: '{count} öğün',
                      en: '{count} meals',
                      replacements: {'count': meals.length},
                    ),
                  ),
                  const SizedBox(height: 11),
                  if (meals.isEmpty)
                    _EmptyMeals(onAddMeal: onAddMeal)
                  else
                    ...meals.map(
                      (meal) => _MealRow(meal, onTap: () => onMealTap(meal)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: showBottomNavigationBar
          ? LiquidGlassBottomBar(
              selectedIndex: 0,
              onDestinationSelected: onNavigationSelected,
            )
          : null,
    );
  }
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.ota('todayTitle', tr: 'Bugün', en: 'Today'),
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 5),
        Text(
          _formatHeaderDate(now, Localizations.localeOf(context).languageCode),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _DailySummary extends StatelessWidget {
  const _DailySummary({required this.total});

  static const calorieGoal = 2100.0;
  final Nutrition total;

  @override
  Widget build(BuildContext context) {
    final remaining = (calorieGoal - total.calories)
        .clamp(0, calorieGoal)
        .toDouble();
    final largeText = MediaQuery.textScalerOf(context).scale(14) >= 20;
    return HeroCardSurface(
      color: AppColors.brandSoft,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (largeText) ...[
            _RemainingCalories(remaining: remaining),
            const SizedBox(height: 10),
            _CalorieGoalProgress(total: total),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _RemainingCalories(remaining: remaining)),
                _CalorieGoalProgress(total: total),
              ],
            ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: (total.calories / calorieGoal).clamp(0, 1),
              backgroundColor: AppColors.surfaceMuted,
              valueColor: const AlwaysStoppedAnimation(AppColors.limeDark),
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.line),
          const SizedBox(height: 13),
          if (largeText)
            Column(
              children: [
                _MacroMetric(
                  label: context.l10n.macroProtein,
                  value: total.protein,
                  goal: 160,
                  color: AppColors.protein,
                ),
                const SizedBox(height: 16),
                _MacroMetric(
                  label: context.l10n.macroCarbs,
                  value: total.carbs,
                  goal: 240,
                  color: AppColors.carbs,
                ),
                const SizedBox(height: 16),
                _MacroMetric(
                  label: context.l10n.macroFat,
                  value: total.fat,
                  goal: 70,
                  color: AppColors.fat,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _MacroMetric(
                    label: context.l10n.macroProtein,
                    value: total.protein,
                    goal: 160,
                    color: AppColors.protein,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _MacroMetric(
                    label: context.l10n.macroCarbs,
                    value: total.carbs,
                    goal: 240,
                    color: AppColors.carbs,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _MacroMetric(
                    label: context.l10n.macroFat,
                    value: total.fat,
                    goal: 70,
                    color: AppColors.fat,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RemainingCalories extends StatelessWidget {
  const _RemainingCalories({required this.remaining});

  final double remaining;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      text: _formatNumber(remaining.round()),
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 40,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
      ),
      children: [
        TextSpan(
          text: context.ota(
            'caloriesRemainingSuffix',
            tr: ' kcal kaldı',
            en: ' kcal left',
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
  );
}

class _CalorieGoalProgress extends StatelessWidget {
  const _CalorieGoalProgress({required this.total});

  final Nutrition total;

  @override
  Widget build(BuildContext context) => Text(
    context.ota(
      'calorieGoalProgress',
      tr: '{current} / 2.100',
      en: '{current} / 2,100',
      replacements: {'current': _formatNumber(total.calories.round())},
    ),
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.ink,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _MacroMetric extends StatelessWidget {
  const _MacroMetric({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  final String label;
  final double value;
  final double goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 4),
        Text(
          context.ota(
            'macroGoalProgress',
            tr: '{current} / {goal} g',
            en: '{current} / {goal} g',
            replacements: {'current': value.round(), 'goal': goal.round()},
          ),
          maxLines: 1,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: (value / goal).clamp(0, 1),
            backgroundColor: AppColors.surfaceMuted,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _QuickComposer extends StatelessWidget {
  const _QuickComposer({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.compactCard),
          border: Border.all(color: AppColors.line),
          boxShadow: AppShadows.card,
        ),
        child: InkWell(
          key: const Key('quick-composer'),
          borderRadius: BorderRadius.circular(AppRadius.compactCard),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.limeSoft,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                  ),
                  child: const Icon(Icons.photo_camera_outlined, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.ota(
                          'quickAddTitle',
                          tr: 'Yemeğini göster',
                          en: 'Show your meal',
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.ota(
                          'quickAddBody',
                          tr: 'Fotoğrafla başla; gerekirse düzelt',
                          en: 'Start with a photo, adjust if needed',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Text(detail, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow(this.meal, {required this.onTap});

  final LoggedMeal meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
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
            key: Key('meal-${meal.id}'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    child: meal.imageAsset == null
                        ? Container(
                            width: 88,
                            height: 88,
                            color: AppColors.surfaceMuted,
                            child: const Icon(
                              Icons.restaurant_rounded,
                              size: 21,
                            ),
                          )
                        : Image.asset(
                            meal.imageAsset!,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            cacheWidth: 240,
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
                        const SizedBox(height: 3),
                        Text(
                          meal.timeLabel,
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

class _EmptyMeals extends StatelessWidget {
  const _EmptyMeals({required this.onAddMeal});

  final VoidCallback onAddMeal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            context.ota(
              'todayEmptyTitle',
              tr: 'Henüz öğün eklemedin',
              en: 'No meals yet',
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            context.ota(
              'todayEmptyBody',
              tr: 'İlk kaydınla günlük özetin oluşmaya başlayacak.',
              en: 'Your daily summary will appear after your first entry.',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onAddMeal,
            child: Text(
              context.ota(
                'todayEmptyAction',
                tr: 'İlk öğünü ekle',
                en: 'Add your first meal',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNumber(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
}

String _formatHeaderDate(DateTime date, String languageCode) {
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
  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}
