import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../domain/models.dart';
import '../domain/nutrition_goals.dart';
import '../theme/app_theme.dart';
import '../util/formatters.dart';
import '../widgets/daily_summary_card.dart';
import '../widgets/liquid_glass_bottom_bar.dart';
import '../widgets/meal_list_tile.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    required this.meals,
    required this.goals,
    required this.day,
    required this.onAddMeal,
    required this.onMealTap,
    required this.onNavigationSelected,
    this.showBottomNavigationBar = true,
    super.key,
  });

  final List<LoggedMeal> meals;
  final NutritionGoals goals;

  /// The day this screen represents. Owned by the shell so the header cannot
  /// freeze on the date of the first build when the app stays open past
  /// midnight.
  final DateTime day;

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
              padding: EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.lg,
                AppSpacing.page,
                AppSpacing.pageBottom(context),
              ),
              sliver: SliverList.list(
                children: [
                  _TodayHeader(day: day),
                  const SizedBox(height: AppSpacing.lg),
                  DailySummaryCard(
                    total: total,
                    goals: goals,
                    onDetails: () => onNavigationSelected(3),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _QuickComposer(onTap: onAddMeal),
                  const SizedBox(height: AppSpacing.xl),
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
                  const SizedBox(height: AppSpacing.sm),
                  if (meals.isEmpty)
                    _EmptyMeals(onAddMeal: onAddMeal)
                  else
                    ...meals.map(
                      (meal) => MealListTile(
                        meal: meal,
                        onTap: () => onMealTap(meal),
                      ),
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
  const _TodayHeader({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.ota('todayTitle', tr: 'Bugün', en: 'Today'),
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpacing.tiny),
        Text(
          formatHeaderDate(context, day),
          style: Theme.of(context).textTheme.bodyMedium,
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
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
                const SizedBox(width: AppSpacing.sm),
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
                      const SizedBox(height: AppSpacing.micro),
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

class _EmptyMeals extends StatelessWidget {
  const _EmptyMeals({required this.onAddMeal});

  final VoidCallback onAddMeal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
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
          const SizedBox(height: AppSpacing.tiny),
          Text(
            context.ota(
              'todayEmptyBody',
              tr: 'İlk kaydınla günlük özetin oluşmaya başlayacak.',
              en: 'Your daily summary will appear after your first entry.',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
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
