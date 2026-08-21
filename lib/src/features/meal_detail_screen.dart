import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../domain/models.dart';
import '../theme/app_theme.dart';
import '../util/formatters.dart';
import '../view_models/meal_detail_view_model.dart';
import '../widgets/app_surfaces.dart';

class MealDetailScreen extends StatefulWidget {
  const MealDetailScreen({
    super.key,
    required this.meal,
    required this.onUpdate,
    required this.onDelete,
  });

  final LoggedMeal meal;
  final ValueChanged<LoggedMeal> onUpdate;
  final VoidCallback onDelete;

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  late final MealDetailViewModel _viewModel;

  LoggedMeal get _meal => _viewModel.meal;

  @override
  void initState() {
    super.initState();
    _viewModel = MealDetailViewModel(meal: widget.meal);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _editItem(MealItem item) async {
    final grams = await showModalBottomSheet<double>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => _PortionSheet(
        item: item,
        previewNutrition: (grams) => _viewModel.previewNutrition(item, grams),
      ),
    );
    if (grams == null || !mounted) return;

    final updatedMeal = _viewModel.updatePortion(item, grams);
    widget.onUpdate(updatedMeal);
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xxs,
            AppSpacing.page,
            AppSpacing.x28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.destructive,
                size: 32,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.ota(
                  'deleteMealConfirmTitle',
                  tr: 'Bu öğün silinsin mi?',
                  en: 'Delete this meal?',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.ota(
                  'deleteMealConfirmBody',
                  tr: 'Günlük toplamların bu öğün olmadan yeniden hesaplanacak.',
                  en: 'Your daily totals will be recalculated without this meal.',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.destructive,
                  foregroundColor: AppColors.onDark,
                ),
                // Deliberately not the trigger's wording: the confirmation is
                // the answer to a question, not a repeat of the same button.
                child: Text(
                  context.ota(
                    'deleteMealConfirmAction',
                    tr: 'Evet, sil',
                    en: 'Yes, delete',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.tiny),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  context.ota('commonCancel', tr: 'Vazgeç', en: 'Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (shouldDelete == true) widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final nutrition = _viewModel.nutrition;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.canvas,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              tooltip: context.ota('commonBack', tr: 'Geri', en: 'Back'),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(
              context.ota(
                'mealDetailTitle',
                tr: 'Öğün detayı',
                en: 'Meal details',
              ),
            ),
            titleTextStyle: Theme.of(context).textTheme.titleMedium,
            centerTitle: true,
            actions: [
              // Deleting used to sit at the end of the scrolling content, where
              // a fling could land on it. An overflow entry keeps it reachable
              // without putting it in the swipe path.
              PopupMenuButton<void>(
                tooltip: context.ota(
                  'mealActionsMenu',
                  tr: 'Öğün işlemleri',
                  en: 'Meal actions',
                ),
                icon: const Icon(Icons.more_horiz_rounded),
                color: AppColors.surface,
                itemBuilder: (context) => [
                  PopupMenuItem<void>(
                    onTap: _confirmDelete,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppColors.destructive,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          context.ota(
                            'deleteMealAction',
                            tr: 'Öğünü sil',
                            en: 'Delete meal',
                          ),
                          style: const TextStyle(
                            color: AppColors.destructive,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.xs,
                AppSpacing.page,
                AppSpacing.x28,
              ),
              children: [
                _MealImage(meal: _meal),
                const SizedBox(height: AppSpacing.md),
                _MealSummary(meal: _meal, nutrition: nutrition),
                const SizedBox(height: AppSpacing.xl),
                _FoodsHeader(count: _meal.items.length),
                const SizedBox(height: AppSpacing.sm),
                _IngredientList(items: _meal.items, onTap: _editItem),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MealImage extends StatelessWidget {
  const _MealImage({required this.meal});

  final LoggedMeal meal;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: meal.imageAsset == null
          ? context.ota(
              'mealPhotoMissing',
              tr: '{meal} · fotoğraf yok',
              en: '{meal} · no photo',
              replacements: {'meal': meal.name},
            )
          : context.ota(
              'mealPhotoLabel',
              tr: '{meal} fotoğrafı',
              en: 'Photo of {meal}',
              replacements: {'meal': meal.name},
            ),
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.feature),
          child: LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: (constraints.maxWidth * 3 / 4).clamp(240, 360),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // No Hero here: the list screens never declared a matching
                  // tag, so the flight was one-sided and never ran.
                  if (meal.imageAsset != null)
                    Image.asset(
                      meal.imageAsset!,
                      fit: BoxFit.cover,
                      cacheWidth: 900,
                    )
                  else
                    const ColoredBox(
                      color: AppColors.surfaceMuted,
                      child: Icon(
                        Icons.restaurant_rounded,
                        size: 42,
                        color: AppColors.muted,
                      ),
                    ),
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(AppRadius.input),
                        ),
                        child: Text(
                          meal.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.onDark),
                        ),
                      ),
                    ),
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

class _FoodsHeader extends StatelessWidget {
  const _FoodsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(14) >= 20;
    final title = Text(
      context.ota('foodsTitle', tr: 'Yiyecekler', en: 'Foods'),
      style: Theme.of(context).textTheme.titleLarge,
    );
    final tally = Text(
      context.ota(
        'foodCount',
        tr: '{count} yiyecek',
        en: '{count} foods',
        replacements: {'count': count},
      ),
      style: Theme.of(context).textTheme.bodyMedium,
    );
    if (largeText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: AppSpacing.xxs),
          tally,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: title),
        tally,
      ],
    );
  }
}

class _MealSummary extends StatelessWidget {
  const _MealSummary({required this.meal, required this.nutrition});

  final LoggedMeal meal;
  final Nutrition nutrition;

  @override
  Widget build(BuildContext context) {
    final hasEstimates = meal.items.any(
      (item) => item.matchState != MatchState.matched,
    );
    final calories = context.ota(
      'calorieAmount',
      tr: '{amount} kcal',
      en: '{amount} kcal',
      replacements: {'amount': nutrition.calories.round()},
    );
    final largeText = MediaQuery.textScalerOf(context).scale(14) >= 20;
    final occurrence = Text(
      _occurrenceLabel(context, meal),
      style: Theme.of(context).textTheme.bodyMedium,
    );
    final total = Text(
      // The review step's `~` for anything the analysis had to estimate.
      hasEstimates ? '~$calories' : calories,
      style: Theme.of(context).textTheme.titleLarge,
    );
    return HeroCardSurface(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scaled up, the calorie total alone is wider than the card, so the
          // two halves stack instead of fighting over one line.
          if (largeText) ...[
            occurrence,
            const SizedBox(height: AppSpacing.xxs),
            total,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: occurrence),
                const SizedBox(width: AppSpacing.sm),
                total,
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          Container(height: 1, color: AppColors.line),
          const SizedBox(height: AppSpacing.md),
          _MacroStrip(nutrition: nutrition),
          if (hasEstimates) ...[
            const SizedBox(height: AppSpacing.sm),
            _EstimateChip(
              label: context.ota(
                'mealTotalApproximate',
                tr: 'Toplam yaklaşık — bazı miktarlar tahmin.',
                en: 'Total is approximate — some amounts are estimates.',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Today" only when it really is today; History opens meals from any day.
String _occurrenceLabel(BuildContext context, LoggedMeal meal) {
  final occurredAt = meal.occurredAt;
  if (occurredAt == null) return meal.timeLabel;

  final now = DateTime.now();
  final isToday =
      occurredAt.year == now.year &&
      occurredAt.month == now.month &&
      occurredAt.day == now.day;
  final time = formatTimeOfDay(context, occurredAt);
  return isToday
      ? context.ota(
          'mealTimeToday',
          tr: 'Bugün · {time}',
          en: 'Today · {time}',
          replacements: {'time': time},
        )
      : context.ota(
          'mealTimeOnDate',
          tr: '{date} · {time}',
          en: '{date} · {time}',
          replacements: {
            'date': formatFullDate(context, occurredAt),
            'time': time,
          },
        );
}

class _MacroStrip extends StatelessWidget {
  const _MacroStrip({required this.nutrition});

  final Nutrition nutrition;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(14) >= 20;
    final macros = <Widget>[
      _Macro(
        label: context.l10n.macroProtein,
        value: nutrition.protein,
        color: AppColors.protein,
      ),
      _Macro(
        label: context.l10n.macroCarbs,
        value: nutrition.carbs,
        color: AppColors.carbs,
      ),
      _Macro(
        label: context.l10n.macroFat,
        value: nutrition.fat,
        color: AppColors.fat,
      ),
    ];
    if (largeText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < macros.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.sm),
            macros[index],
          ],
        ],
      );
    }
    return Row(children: [for (final macro in macros) Expanded(child: macro)]);
  }
}

class _Macro extends StatelessWidget {
  const _Macro({required this.label, required this.value, required this.color});

  final String label;
  final double value;
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
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.tiny),
            Text(
              context.ota(
                'gramAmount',
                tr: '{amount} g',
                en: '{amount} g',
                replacements: {'amount': value.round()},
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}

class _IngredientList extends StatelessWidget {
  const _IngredientList({required this.items, required this.onTap});

  final List<MealItem> items;
  final ValueChanged<MealItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.compactCard),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _IngredientRow(
              item: items[index],
              onTap: () => onTap(items[index]),
            ),
            if (index < items.length - 1)
              const Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
                color: AppColors.separator,
              ),
          ],
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.item, required this.onTap});

  final MealItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Logging a meal used to erase what the review step admitted it was unsure
    // about; the estimate survives into the logged meal instead.
    final isEstimate = item.matchState != MatchState.matched;
    final portion = isEstimate ? '~${item.portionLabel}' : item.portionLabel;
    final calories = context.ota(
      'calorieAmount',
      tr: '{amount} kcal',
      en: '{amount} kcal',
      replacements: {'amount': item.nutrition.calories.round()},
    );
    final estimateNote = item.matchState == MatchState.checkAmount
        ? context.l10n.mealCheckAmount
        : context.l10n.mealCheckType;
    final largeText = MediaQuery.textScalerOf(context).scale(14) >= 20;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(portion, style: Theme.of(context).textTheme.bodyMedium),
        if (isEstimate) ...[
          const SizedBox(height: AppSpacing.tiny),
          _EstimateChip(label: estimateNote),
        ],
      ],
    );
    final caloriesText = Text(
      calories,
      style: Theme.of(context).textTheme.labelLarge,
    );
    const chevron = Icon(
      Icons.chevron_right_rounded,
      size: 20,
      color: AppColors.muted,
    );

    return Semantics(
      button: true,
      label: [
        item.name,
        portion,
        calories,
        if (isEstimate) estimateNote,
      ].join(', '),
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              // Scaled up, the calorie figure no longer fits beside the name,
              // so it moves under it rather than pushing the row off-screen.
              child: largeText
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        details,
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Expanded(child: caloriesText),
                            chevron,
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: details),
                        const SizedBox(width: AppSpacing.sm),
                        caloriesText,
                        const SizedBox(width: AppSpacing.tiny),
                        chevron,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The review step's palette, carried into the logged meal so an estimate reads
/// as the same concept in both places — a note, not an alarm.
class _EstimateChip extends StatelessWidget {
  const _EstimateChip({required this.label});

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
              maxLines: 2,
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

/// Portion editor.
///
/// Stateful — and owning its own controller — because a modal route keeps
/// rebuilding its content through the exit animation, so a controller disposed
/// when `showModalBottomSheet` returns would be used after disposal.
class _PortionSheet extends StatefulWidget {
  const _PortionSheet({required this.item, required this.previewNutrition});

  final MealItem item;
  final Nutrition Function(double grams) previewNutrition;

  @override
  State<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<_PortionSheet> {
  /// Slider granularity. The previous sheet stepped by 5 g, which claims a
  /// precision an estimate does not have; exact values go through the field.
  static const _step = 10.0;
  static const _minEntry = 1.0;
  static const _maxEntry = 2000.0;

  late final TextEditingController _controller = TextEditingController(
    text: '${widget.item.grams.round()}',
  );

  // The track is anchored on the item, so a portion outside the default
  // 10-500 g window stays reachable instead of being clamped out of sight.
  late final double _minGrams = math.min(
    10,
    (widget.item.grams / _step).floorToDouble() * _step,
  );
  late final double _maxGrams = math.max(
    500,
    (widget.item.grams / _step).ceilToDouble() * _step,
  );

  late double _grams = widget.item.grams;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _gramLabel(double grams) => context.ota(
    'gramAmount',
    tr: '{amount} g',
    en: '{amount} g',
    replacements: {'amount': grams.round()},
  );

  void _onSlide(double grams) {
    setState(() {
      _grams = grams;
      _error = null;
    });
    final text = '${grams.round()}';
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _onTyped(String raw) {
    final grams = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (grams == null) {
      setState(
        () => _error = context.ota(
          'portionInvalidNumber',
          tr: 'Sayı olarak bir miktar gir.',
          en: 'Enter the amount as a number.',
        ),
      );
      return;
    }
    if (grams < _minEntry || grams > _maxEntry) {
      setState(
        () => _error = context.ota(
          'portionOutOfRange',
          tr: '{min}-{max} g arasında bir miktar gir.',
          en: 'Enter an amount between {min} and {max} g.',
          replacements: {'min': _minEntry.round(), 'max': _maxEntry.round()},
        ),
      );
      return;
    }
    setState(() {
      _grams = grams;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.previewNutrition(_grams);
    final delta = _grams - widget.item.grams;
    return SafeArea(
      top: false,
      // The field, the slider and the reference line outgrow a small screen
      // once text is scaled up, so the sheet scrolls instead of overflowing.
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xxs,
            AppSpacing.page,
            AppSpacing.x28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.ota(
                  'portionEditBody',
                  tr: 'Miktarı değiştirince kalori ve makrolar yeniden hesaplanır.',
                  en: 'Calories and macros are recalculated when you change the amount.',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.feature),
                ),
                child: Column(
                  children: [
                    Text(
                      _gramLabel(_grams),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    // The sheet promises a recalculation; showing it live is
                    // the only way that promise is visible before committing.
                    Text(
                      context.ota(
                        'calorieAmount',
                        tr: '{amount} kcal',
                        en: '{amount} kcal',
                        replacements: {'amount': preview.calories.round()},
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Slider(
                key: const Key('portion-slider'),
                value: _grams.clamp(_minGrams, _maxGrams),
                min: _minGrams,
                max: _maxGrams,
                divisions: ((_maxGrams - _minGrams) / _step).round(),
                label: _gramLabel(_grams),
                semanticFormatterCallback: _gramLabel,
                activeColor: AppColors.limeDark,
                inactiveColor: AppColors.line,
                onChanged: _onSlide,
              ),
              Text(
                delta == 0
                    ? context.ota(
                        'portionSavedAmount',
                        tr: 'Kayıtlı miktar: {amount} g',
                        en: 'Saved amount: {amount} g',
                        replacements: {'amount': widget.item.grams.round()},
                      )
                    : context.ota(
                        'portionSavedAmountDelta',
                        tr: 'Kayıtlı miktar: {amount} g · {delta} g',
                        en: 'Saved amount: {amount} g · {delta} g',
                        replacements: {
                          'amount': widget.item.grams.round(),
                          'delta':
                              '${delta > 0 ? '+' : '−'}'
                              '${delta.abs().round()}',
                        },
                      ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.ota(
                  'orEnterGrams',
                  tr: 'veya gram gir',
                  en: 'or enter grams',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                key: const Key('portion-grams-input'),
                controller: _controller,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onChanged: _onTyped,
                decoration: InputDecoration(suffixText: 'g', errorText: _error),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                key: const Key('save-portion-button'),
                // A track that starts below 10 g (an item that small) can reach
                // zero, which is a deletion, not a portion.
                onPressed: _error == null && _grams >= _minEntry
                    ? () => Navigator.pop(context, _grams)
                    : null,
                child: Text(
                  context.ota(
                    'updateAmountAction',
                    tr: 'Miktarı güncelle',
                    en: 'Update amount',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
