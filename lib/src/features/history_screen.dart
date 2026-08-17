import 'dart:collection';

import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    required this.meals,
    required this.onMealTap,
    required this.onTodayTap,
    this.onProfileTap,
    super.key,
  });

  final List<LoggedMeal> meals;
  final ValueChanged<LoggedMeal> onMealTap;
  final VoidCallback onTodayTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final groups = _groupMeals(meals);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 36),
              sliver: SliverList.list(
                children: [
                  Text(
                    'Geçmiş',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Öğünlerin cihazında saklanır ve bağlantı geldiğinde güvenle eşitlenir.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  if (groups.isEmpty)
                    const _EmptyHistory()
                  else
                    for (final entry in groups.entries) ...[
                      _DayHeader(date: entry.key, meals: entry.value),
                      const SizedBox(height: 10),
                      for (final meal in entry.value)
                        _HistoryMealCard(
                          meal: meal,
                          onTap: () => onMealTap(meal),
                        ),
                      const SizedBox(height: 22),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: 1,
        backgroundColor: AppColors.surface,
        indicatorColor: const Color(0xFFEAF7B8),
        onDestinationSelected: (index) {
          if (index == 0) onTodayTap();
          if (index == 2) onProfileTap?.call();
        },
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
    );
  }

  SplayTreeMap<DateTime, List<LoggedMeal>> _groupMeals(List<LoggedMeal> meals) {
    final groups = SplayTreeMap<DateTime, List<LoggedMeal>>(
      (left, right) => right.compareTo(left),
    );
    for (final meal in meals) {
      final occurredAt = meal.occurredAt;
      if (occurredAt == null) continue;
      final day = DateTime(occurredAt.year, occurredAt.month, occurredAt.day);
      groups.putIfAbsent(day, () => []).add(meal);
    }
    return groups;
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, required this.meals});

  final DateTime date;
  final List<LoggedMeal> meals;

  @override
  Widget build(BuildContext context) {
    final calories = meals.fold<double>(
      0,
      (total, meal) => total + meal.nutrition.calories,
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            _formatDay(date),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Text(
          '${calories.round()} kcal',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _HistoryMealCard extends StatelessWidget {
  const _HistoryMealCard({required this.meal, required this.onTap});

  final LoggedMeal meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.all(12),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox.square(
              dimension: 58,
              child: meal.imageAsset == null
                  ? const ColoredBox(
                      color: AppColors.canvas,
                      child: Icon(Icons.restaurant_rounded),
                    )
                  : Image.asset(meal.imageAsset!, fit: BoxFit.cover),
            ),
          ),
          title: Text(
            meal.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text('${meal.timeLabel} · ${meal.items.length} yiyecek'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${meal.nutrition.calories.round()} kcal'),
              const Icon(Icons.chevron_right_rounded),
            ],
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
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Icon(Icons.history_toggle_off_rounded, size: 42),
          const SizedBox(height: 12),
          Text(
            'Henüz geçmiş öğün yok',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'Kaydettiğin öğünler burada günlere göre görünecek.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

String _formatDay(DateTime date) {
  const months = [
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
  return '${date.day} ${months[date.month - 1]}';
}
