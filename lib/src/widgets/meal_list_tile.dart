import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../domain/models.dart';
import '../theme/app_theme.dart';
import '../util/haptics.dart';
import 'meal_photo.dart';

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
    this.onDelete,
    super.key,
  });

  final LoggedMeal meal;
  final VoidCallback onTap;

  /// Secondary line. Defaults to the meal time.
  final String? subtitle;

  /// Analysis lists many meals at once and stays compact.
  final bool showThumbnail;

  /// Enables the row's contextual delete when supplied. Screens that only
  /// display meals — Analysis reads as a report, not a workspace — leave it
  /// off.
  ///
  /// The gesture is a long press rather than a swipe. Today, History and
  /// Analysis all live inside the shell's horizontally paged `PageView`, and a
  /// `Dismissible` on the row wins that drag in the gesture arena: on History,
  /// where meal rows cover the middle of the screen, swiping to change tab
  /// started swiping the row under the finger away instead. Page navigation is
  /// the primary gesture and this is an accelerator, so the accelerator moved
  /// off the contested axis rather than the other way round.
  final VoidCallback? onDelete;

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
    final pendingNote = context.ota(
      'mealPendingSync',
      tr: 'kaydedildi, gönderilmeyi bekliyor',
      en: 'saved, waiting to upload',
    );
    final delete = onDelete;

    final semanticLabel = [
      meal.name,
      detail,
      context.ota(
        'calorieAmount',
        tr: '{amount} kcal',
        en: '{amount} kcal',
        replacements: {'amount': calories},
      ),
      if (_hasEstimates) estimateNote,
      if (meal.isPending) pendingNote,
    ].join(', ');

    final row = ExcludeSemantics(
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
            onLongPress: delete == null
                ? null
                : () => _showActions(context, delete),
            child: Padding(
              padding: EdgeInsets.all(
                showThumbnail ? AppSpacing.sm : AppSpacing.md,
              ),
              child: Row(
                children: [
                  if (showThumbnail) ...[
                    _Thumbnail(source: meal.imageAsset),
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
                        Row(
                          children: [
                            if (meal.isPending) ...[
                              const Icon(
                                Icons.cloud_upload_outlined,
                                size: 14,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                            ],
                            Flexible(
                              child: Text(
                                detail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
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
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        button: true,
        label: semanticLabel,
        // The InkWell's own tap action is inside the ExcludeSemantics that
        // stops the row being announced as four separate fragments, so the
        // action has to be re-published here. Without it the node claimed to be
        // a button while advertising nothing a screen reader could invoke.
        onTap: onTap,
        // A long press is a gesture no screen-reader or switch-control user can
        // reach. `onDismiss` publishes the same destructive action directly to
        // assistive technology, so the accelerator is available to everyone
        // rather than only to people who can press and hold.
        onDismiss: delete == null
            ? null
            : () {
                AppHaptics.committed();
                delete();
              },
        child: row,
      ),
    );
  }

  /// Confirms the destructive action before it happens.
  ///
  /// A long press alone is not enough authorisation to delete something: the
  /// press can be an accidentally held tap. The sheet turns it into press, read
  /// which meal, then choose — while dismissing it costs one tap anywhere. The
  /// removal itself is still undoable afterwards.
  Future<void> _showActions(BuildContext context, VoidCallback delete) async {
    AppHaptics.selection();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Text(
                meal.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            ListTile(
              key: const Key('meal-action-delete'),
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.destructive,
              ),
              title: Text(
                context.ota('commonDelete', tr: 'Sil', en: 'Delete'),
                style: const TextStyle(
                  color: AppColors.destructive,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => Navigator.pop(sheetContext, true),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    AppHaptics.committed();
    delete();
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.source});

  final String? source;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: SizedBox.square(
        dimension: 88,
        child: MealPhoto(
          source: source,
          placeholderIconSize: 24,
          cacheWidth: 240,
        ),
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
