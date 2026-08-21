import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../domain/models.dart';
import '../theme/app_theme.dart';

/// One logged meal, rendered identically on Today, History and Analysis.
///
/// The three screens previously each had their own row widget, so the same meal
/// appeared with a thumbnail and a shadow on Today, a different radius on
/// History, and as a flat borderless strip on Analysis. They also exposed no
/// button semantics, so a screen reader announced four disconnected fragments
/// and never said the row was tappable.
class MealListTile extends StatelessWidget {
  const MealListTile({
    required this.meal,
    required this.onTap,
    this.subtitle,
    this.showThumbnail = true,
    super.key,
  });

  final LoggedMeal meal;
  final VoidCallback onTap;

  /// Secondary line. Defaults to the meal time.
  final String? subtitle;

  /// Analysis lists many meals at once and stays compact.
  final bool showThumbnail;

  /// True when any food in the meal is still an unreviewed estimate.
  bool get _hasEstimates =>
      meal.items.any((item) => item.matchState != MatchState.matched);

  @override
  Widget build(BuildContext context) {
    final detail = subtitle ?? meal.timeLabel;
    final calories = meal.nutrition.calories.round();
    final estimateNote = context.ota(
      'mealContainsEstimates',
      tr: 'tahmin içeriyor',
      en: 'contains estimates',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        button: true,
        label: [
          meal.name,
          detail,
          context.ota(
            'calorieAmount',
            tr: '{amount} kcal',
            en: '{amount} kcal',
            replacements: {'amount': calories},
          ),
          if (_hasEstimates) estimateNote,
        ].join(', '),
        child: ExcludeSemantics(
          child: DecoratedBox(
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
                  padding: EdgeInsets.all(
                    showThumbnail ? AppSpacing.sm : AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      if (showThumbnail) ...[
                        _Thumbnail(asset: meal.imageAsset),
                        const SizedBox(width: AppSpacing.sm),
                      ],
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
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (_hasEstimates) ...[
                              const SizedBox(height: AppSpacing.tiny),
                              _EstimateBadge(label: estimateNote),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$calories',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'kcal',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
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
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.asset});

  final String? asset;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: SizedBox.square(
        dimension: 88,
        child: asset == null
            ? const ColoredBox(
                color: AppColors.surfaceMuted,
                child: Icon(Icons.restaurant_rounded, size: 24),
              )
            : Image.asset(asset!, fit: BoxFit.cover, cacheWidth: 240),
      ),
    );
  }
}

/// Carries the "this is still an estimate" signal out of the review step and
/// into the logged meal, where it used to be dropped entirely.
class _EstimateBadge extends StatelessWidget {
  const _EstimateBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.micro,
      ),
      decoration: BoxDecoration(
        color: AppColors.reviewSurface,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tune_rounded, size: 13, color: AppColors.reviewInk),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.reviewInk,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
