import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../domain/models.dart';
import '../domain/nutrition_goals.dart';
import '../theme/app_theme.dart';
import '../util/formatters.dart';
import 'app_surfaces.dart';

// Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V4
// Component: daily nutrition summary · genre: vibrant health utility
// Reference DNA: central calorie arc · supporting side metrics · macro rail

const _pillRadius = 99.0;

class DailySummaryCard extends StatelessWidget {
  const DailySummaryCard({
    required this.total,
    required this.goals,
    required this.onDetails,
    super.key,
  });

  final Nutrition total;
  final NutritionGoals goals;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final remaining = (goals.calories - total.calories)
        .clamp(0, goals.calories)
        .toDouble();
    final calorieProgress = (total.calories / goals.calories).clamp(0.0, 1.0);
    final largeText = MediaQuery.textScalerOf(context).scale(14) >= 20;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = largeText || constraints.maxWidth < 300;
        return Semantics(
          button: true,
          label: context.ota(
            'dailySummaryDetails',
            tr: 'Detaylar',
            en: 'Details',
          ),
          child: GestureDetector(
            key: const Key('daily-summary-details'),
            behavior: HitTestBehavior.opaque,
            onTap: onDetails,
            child: _SummaryBody(
              stacked: stacked,
              remaining: remaining,
              calorieProgress: calorieProgress,
              total: total,
              goals: goals,
            ),
          ),
        );
      },
    );
  }
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({
    required this.stacked,
    required this.remaining,
    required this.calorieProgress,
    required this.total,
    required this.goals,
  });

  final bool stacked;
  final double remaining;
  final double calorieProgress;
  final Nutrition total;
  final NutritionGoals goals;

  @override
  Widget build(BuildContext context) {
    return HeroCardSurface(
      key: const Key('daily-summary-card'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          if (stacked) ...[
                _CalorieRing(
                  remaining: remaining,
                  progress: calorieProgress,
                  total: total,
                  goals: goals,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _SupportingMetric(
                        key: const Key('daily-consumed-stat'),
                        value: total.calories,
                        label: context.ota(
                          'caloriesConsumedLabel',
                          tr: 'Alınan',
                          en: 'Consumed',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _SupportingMetric(
                        key: const Key('daily-goal-stat'),
                        value: goals.calories,
                        label: context.ota(
                          'calorieGoalLabel',
                          tr: 'Hedef',
                          en: 'Goal',
                        ),
                      ),
                    ),
                  ],
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: _SupportingMetric(
                        key: const Key('daily-consumed-stat'),
                        value: total.calories,
                        label: context.ota(
                          'caloriesConsumedLabel',
                          tr: 'Alınan',
                          en: 'Consumed',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _CalorieRing(
                      remaining: remaining,
                      progress: calorieProgress,
                      total: total,
                      goals: goals,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _SupportingMetric(
                        key: const Key('daily-goal-stat'),
                        value: goals.calories,
                        label: context.ota(
                          'calorieGoalLabel',
                          tr: 'Hedef',
                          en: 'Goal',
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.md),
              _MacroRail(total: total, goals: goals, stacked: stacked),
              if (goals.isDefault) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(height: 1, color: AppColors.line),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.ota(
                    'calorieGoalDefaultNote',
                    tr: 'Önerilen hedefi profilinden değiştirebilirsin.',
                    en: 'You can change the suggested target in your profile.',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        );
  }
}

class _CalorieRing extends StatelessWidget {
  const _CalorieRing({
    required this.remaining,
    required this.progress,
    required this.total,
    required this.goals,
  });

  final double remaining;
  final double progress;
  final Nutrition total;
  final NutritionGoals goals;

  @override
  Widget build(BuildContext context) {
    final semantics = context.ota(
      'calorieSummarySemantics',
      tr: '{remaining} kcal kaldı. {current} / {goal} kcal alındı.',
      en: '{remaining} kcal left. {current} of {goal} kcal consumed.',
      replacements: {
        'remaining': formatNumber(context, remaining.round()),
        'current': formatNumber(context, total.calories.round()),
        'goal': formatNumber(context, goals.calories.round()),
      },
    );

    return Semantics(
      container: true,
      label: semantics,
      child: ExcludeSemantics(
        child: SizedBox.square(
          key: const Key('daily-calorie-ring'),
          dimension: 118,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _CalorieArcPainter(
                  progress: progress,
                  trackColor: AppColors.surfaceMuted,
                  progressColor: AppColors.brand,
                  highContrast: MediaQuery.highContrastOf(context),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatNumber(context, remaining.round()),
                      key: const Key('daily-remaining-calories'),
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 26,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      context.ota(
                        'caloriesRemainingRingLabel',
                        tr: 'kcal kaldı',
                        en: 'kcal left',
                      ),
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalorieArcPainter extends CustomPainter {
  const _CalorieArcPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.highContrast,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final bool highContrast;

  static const _startAngle = math.pi * 0.75;
  static const _sweepAngle = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = highContrast ? 14.0 : 12.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(strokeWidth / 2);
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, _startAngle, _sweepAngle, false, trackPaint);
    if (progress > 0) {
      canvas.drawArc(
        arcRect,
        _startAngle,
        _sweepAngle * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.highContrast != highContrast;
}

class _SupportingMetric extends StatelessWidget {
  const _SupportingMetric({
    required this.value,
    required this.label,
    super.key,
  });

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final formatted = formatNumber(context, value.round());
    return Semantics(
      container: true,
      label: '$label, $formatted kcal',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatted,
                maxLines: 1,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroRail extends StatelessWidget {
  const _MacroRail({
    required this.total,
    required this.goals,
    required this.stacked,
  });

  final Nutrition total;
  final NutritionGoals goals;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final macros = [
      _MacroMetric(
        label: context.l10n.macroCarbs,
        value: total.carbs,
        goal: goals.carbs,
        color: AppColors.carbs,
      ),
      _MacroMetric(
        label: context.l10n.macroProtein,
        value: total.protein,
        goal: goals.protein,
        color: AppColors.protein,
      ),
      _MacroMetric(
        label: context.l10n.macroFat,
        value: total.fat,
        goal: goals.fat,
        color: AppColors.fat,
      ),
    ];

    if (stacked) {
      return Column(
        children: [
          for (var index = 0; index < macros.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.md),
            macros[index],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < macros.length; index++) ...[
          if (index > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: macros[index]),
        ],
      ],
    );
  }
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
    final amounts = context.ota(
      'macroGoalProgress',
      tr: '{current} / {goal} g',
      en: '{current} / {goal} g',
      replacements: {'current': value.round(), 'goal': goal.round()},
    );
    return Semantics(
      container: true,
      label: context.ota(
        'macroGoalSemantics',
        tr: '{macro}: {current} / {goal} gram',
        en: '{macro}: {current} of {goal} grams',
        replacements: {
          'macro': label,
          'current': value.round(),
          'goal': goal.round(),
        },
      ),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              amounts,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 13,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(_pillRadius),
              child: LinearProgressIndicator(
                minHeight: AppSpacing.tiny,
                value: (value / goal).clamp(0.0, 1.0),
                backgroundColor: AppColors.surfaceMuted,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
