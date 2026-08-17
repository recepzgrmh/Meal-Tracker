import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../theme/app_theme.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    super.key,
    required this.meals,
    required this.onAddMeal,
    required this.onMealTap,
  });

  final List<LoggedMeal> meals;
  final VoidCallback onAddMeal;
  final ValueChanged<LoggedMeal> onMealTap;

  Nutrition get _total =>
      meals.fold(Nutrition.zero, (total, meal) => total + meal.nutrition);

  @override
  Widget build(BuildContext context) {
    final total = _total;
    const calorieGoal = 2100.0;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
              sliver: SliverList.list(
                children: [
                  const _TodayHeader(),
                  const SizedBox(height: 28),
                  _CalorieSummary(total: total, goal: calorieGoal),
                  const SizedBox(height: 26),
                  _MacroSummary(total: total),
                  const SizedBox(height: 30),
                  _QuickComposer(onTap: onAddMeal),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Bugünün öğünleri',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${meals.length} öğün',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...meals.map(
                    (meal) => _MealRow(meal, onTap: () => onMealTap(meal)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _TodayBottomBar(onAddMeal: onAddMeal),
    );
  }
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text('Bugün', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(width: 7),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 27),
            ],
          ),
        ),
        Semantics(
          label: 'Takvimi aç',
          button: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {},
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.calendar_today_rounded, size: 21),
            ),
          ),
        ),
      ],
    );
  }
}

class _CalorieSummary extends StatelessWidget {
  const _CalorieSummary({required this.total, required this.goal});

  final Nutrition total;
  final double goal;

  @override
  Widget build(BuildContext context) {
    final calories = total.calories.round();
    final remaining = (goal - total.calories).clamp(0, goal).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kalori', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatNumber(calories),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(
                '/ ${_formatNumber(goal.round())} kcal',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: (total.calories / goal).clamp(0, 1),
            backgroundColor: AppColors.line,
            valueColor: const AlwaysStoppedAnimation(AppColors.lime),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          '$remaining kcal kaldı',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _MacroSummary extends StatelessWidget {
  const _MacroSummary({required this.total});

  final Nutrition total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MacroCell(
            label: 'Protein',
            value: total.protein,
            goal: 160,
            color: AppColors.protein,
          ),
        ),
        const _VerticalDivider(),
        Expanded(
          child: _MacroCell(
            label: 'Karbonhidrat',
            value: total.carbs,
            goal: 240,
            color: AppColors.carbs,
          ),
        ),
        const _VerticalDivider(),
        Expanded(
          child: _MacroCell(
            label: 'Yağ',
            value: total.fat,
            goal: 70,
            color: AppColors.fat,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: AppColors.line,
    );
  }
}

class _MacroCell extends StatelessWidget {
  const _MacroCell({
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            text: '${value.round()}',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            children: [
              TextSpan(
                text: ' / ${goal.round()} g',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 5,
            value: (value / goal).clamp(0, 1),
            backgroundColor: AppColors.line,
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
    return Semantics(
      button: true,
      label: 'Ne yediğini yaz',
      child: InkWell(
        key: const Key('quick-composer'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(18, 19, 14, 19),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ne yedin?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Kendi cümlelerinle anlat',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.lime,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_none_rounded, size: 25),
              ),
            ],
          ),
        ),
      ),
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
      child: Semantics(
        button: true,
        label: '${meal.name}, ${meal.nutrition.calories.round()} kalori',
        child: InkWell(
          key: Key('meal-${meal.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: meal.imageAsset == null
                      ? Container(
                          width: 56,
                          height: 56,
                          color: const Color(0xFFF0F3E5),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            color: AppColors.limeDark,
                          ),
                        )
                      : Image.asset(
                          meal.imageAsset!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          cacheWidth: 168,
                        ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
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
                Text(
                  '${meal.nutrition.calories.round()} kcal',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayBottomBar extends StatelessWidget {
  const _TodayBottomBar({required this.onAddMeal});

  final VoidCallback onAddMeal;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 4),
            child: FilledButton.icon(
              key: const Key('add-meal-button'),
              onPressed: onAddMeal,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Öğün ekle'),
            ),
          ),
          NavigationBar(
            height: 72,
            selectedIndex: 0,
            backgroundColor: AppColors.surface,
            indicatorColor: const Color(0xFFEAF7B8),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Bugün',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_rounded),
                label: 'Geçmiş',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                label: 'Profil',
              ),
            ],
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
