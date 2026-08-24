import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../domain/meal_time_of_day.dart';
import '../domain/models.dart';
import '../domain/nutrition_goals.dart';
import '../sync/sync_status.dart';
import '../theme/app_theme.dart';
import '../util/formatters.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/daily_summary_card.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/liquid_glass_bottom_bar.dart';
import '../widgets/loading_placeholders.dart';
import '../widgets/meal_list_tile.dart';
import '../widgets/sync_status_banner.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    required this.meals,
    required this.goals,
    required this.day,
    required this.onAddMeal,
    required this.onMealTap,
    required this.onNavigationSelected,
    this.isLoading = false,
    this.syncStatus,
    this.onRetrySync,
    this.onDeleteMeal,
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

  /// True while the day has not been read yet. Distinct from "the day is
  /// empty", which is a claim this screen must not make until it is known.
  final bool isLoading;

  final SyncStatus? syncStatus;
  final Future<void> Function()? onRetrySync;

  /// Enables the rows' contextual delete. Absent where a meal list is meant to
  /// be read rather than edited.
  final ValueChanged<LoggedMeal>? onDeleteMeal;

  final bool showBottomNavigationBar;

  Nutrition get _total =>
      meals.fold(Nutrition.zero, (total, meal) => total + meal.nutrition);

  @override
  Widget build(BuildContext context) {
    final total = _total;
    final status = syncStatus;
    final retry = onRetrySync;

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
                  if (status != null && retry != null) ...[
                    SyncStatusBanner(status: status, onRetry: retry),
                    if (status.state != SyncState.settled)
                      const SizedBox(height: AppSpacing.sm),
                  ],
                  if (isLoading)
                    SkeletonGroup(
                      label: context.ota(
                        'todayLoading',
                        tr: 'Günün yükleniyor',
                        en: 'Loading your day',
                      ),
                      child: Column(
                        children: [
                          DailySummarySkeleton(showsGoalNote: goals.isDefault),
                          const SizedBox(height: AppSpacing.sm),
                          _QuickComposer(onTap: onAddMeal),
                          const SizedBox(height: AppSpacing.xl),
                          const MealListSkeleton(),
                        ],
                      ),
                    )
                  else ...[
                    DailySummaryCard(
                      total: total,
                      goals: goals,
                      onDetails: () => onNavigationSelected(3),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _QuickComposer(onTap: onAddMeal),
                    const SizedBox(height: AppSpacing.xl),
                    // No section heading over an empty day: it would be
                    // labelling nothing, directly above an empty state that
                    // already carries its own heading.
                    if (meals.isNotEmpty) ...[
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
                      ..._groupedMeals(context),
                    ] else
                      // Deliberately no button. The empty state's job on this
                      // screen is to explain the blank list, and the one action
                      // it would offer is the capture card sitting directly
                      // above it — a second copy would push the real one
                      // further from the thumb while saying the same thing.
                      // History and Analysis have no composer above them, so
                      // their empty states do carry the primary action.
                      EmptyStateView(
                        icon: Icons.restaurant_menu_rounded,
                        title: context.ota(
                          'todayEmptyTitle',
                          tr: 'Henüz öğün eklemedin',
                          en: 'No meals yet',
                        ),
                        body: context.ota(
                          'todayEmptyBody',
                          tr:
                              'Yukarıdan bir fotoğraf çek; günlük özetin '
                              'oluşmaya başlasın.',
                          en:
                              'Take a photo above and your daily summary will '
                              'start filling in.',
                        ),
                      ),
                  ],
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

  List<Widget> _groupedMeals(BuildContext context) {
    final groups = groupMealsByTimeOfDay(meals);
    final delete = onDeleteMeal;
    // A day with a single meal reads worse with a header over it than without:
    // the header would be labelling a group of one against nothing.
    final showHeaders = groups.length > 1;

    return [
      for (var index = 0; index < groups.length; index++) ...[
        // Only between groups: the first header already has the section
        // heading's gap above it, and stacking both pushed the first meal of
        // the day below the fold on a 844 px screen.
        if (index > 0) const SizedBox(height: AppSpacing.md),
        if (showHeaders) ...[
          _GroupHeader(group: groups[index]),
          const SizedBox(height: AppSpacing.xs),
        ],
        for (final meal in groups[index].meals)
          MealListTile(
            meal: meal,
            onTap: () => onMealTap(meal),
            onDelete: delete == null ? null : () => delete(meal),
          ),
      ],
    ];
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final MealTimeGroup group;

  @override
  Widget build(BuildContext context) {
    final label = switch (group.timeOfDay) {
      MealTimeOfDay.breakfast => context.ota(
        'mealTimeBreakfast',
        tr: 'Kahvaltı',
        en: 'Breakfast',
      ),
      MealTimeOfDay.lunch => context.ota(
        'mealTimeLunch',
        tr: 'Öğle',
        en: 'Lunch',
      ),
      MealTimeOfDay.dinner => context.ota(
        'mealTimeDinner',
        tr: 'Akşam',
        en: 'Dinner',
      ),
      _ => context.ota('mealTimeSnack', tr: 'Ara öğün', en: 'Snack'),
    };
    final calories = context.ota(
      'calorieAmount',
      tr: '{amount} kcal',
      en: '{amount} kcal',
      replacements: {
        'amount': formatNumber(context, group.nutrition.calories.round()),
      },
    );

    return Semantics(
      header: true,
      label: '$label, $calories',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.labelLarge),
            ),
            Text(calories, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
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
