import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_skeleton.dart';
import 'app_surfaces.dart';

/// Stands in for [DailySummaryCard] until the first day of meals has actually
/// been read.
///
/// It mirrors the real card's structure — same surface, same 16 px padding,
/// same 118 px ring, same three-across macro rail — rather than showing a
/// generic block, so the content lands into the shape it was already occupying.
/// `today_screen_test.dart` pins the two heights together; if the real card
/// grows a row, that test fails instead of the layout quietly starting to jump.
class DailySummarySkeleton extends StatelessWidget {
  const DailySummarySkeleton({this.showsGoalNote = false, super.key});

  /// Mirrors `NutritionGoals.isDefault`, which makes the real card grow a
  /// divider and a two-line note. Guessing instead of being told would put the
  /// placeholder 60 px short for every user who has not set their own target —
  /// which is every new user, on the one launch where this is visible.
  final bool showsGoalNote;

  static const ringDimension = 118.0;

  @override
  Widget build(BuildContext context) {
    return HeroCardSurface(
      key: const Key('daily-summary-skeleton'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox(width: 64, height: 20),
              const Spacer(),
              const SkeletonBox(width: 72, height: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const SkeletonBox.square(
                dimension: ringDimension,
                radius: ringDimension / 2,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(width: 96, height: 30),
                    const SizedBox(height: AppSpacing.xs),
                    const SkeletonBox(width: 64, height: 16),
                    const SizedBox(height: AppSpacing.md),
                    const SkeletonBox(width: 96, height: 30),
                    const SizedBox(height: AppSpacing.xs),
                    const SkeletonBox(width: 64, height: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (var index = 0; index < 3; index++) ...[
                if (index > 0) const SizedBox(width: AppSpacing.xs),
                const Expanded(child: SkeletonBox(width: null, height: 58)),
              ],
            ],
          ),
          if (showsGoalNote) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(height: 1, color: AppColors.line),
            const SizedBox(height: AppSpacing.xs),
            const Center(child: SkeletonBox(width: 240, height: 16)),
            const SizedBox(height: AppSpacing.xxs),
            const Center(child: SkeletonBox(width: 160, height: 16)),
          ],
        ],
      ),
    );
  }
}

/// Stands in for a run of [MealListTile]s.
///
/// The geometry is copied from the tile rather than approximated: an 88 px
/// thumbnail inside 12 px padding with an 8 px gap below, which is exactly
/// 120 px per row. A placeholder that is a few pixels off is a placeholder that
/// makes the whole list twitch the moment real meals arrive.
class MealListSkeleton extends StatelessWidget {
  const MealListSkeleton({this.rows = 3, super.key});

  final int rows;

  static const rowHeight = 120.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('meal-list-skeleton'),
      children: [
        for (var index = 0; index < rows; index++) const _SkeletonRow(),
      ],
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.compactCard),
          border: Border.all(color: AppColors.line),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            const SkeletonBox.square(dimension: 88, radius: AppRadius.medium),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SkeletonBox(width: 148, height: 20),
                  const SizedBox(height: AppSpacing.xs),
                  const SkeletonBox(width: 92, height: 16),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const SkeletonBox(width: 40, height: 20),
          ],
        ),
      ),
    );
  }
}
