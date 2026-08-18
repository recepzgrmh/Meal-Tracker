import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../domain/models.dart';
import '../theme/app_theme.dart';
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
    var selectedGrams = item.grams;
    final grams = await showModalBottomSheet<double>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 7),
                Text(
                  context.ota(
                    'portionEditBody',
                    tr: 'Miktarı değiştirince kalori ve makrolar yeniden hesaplanır.',
                    en: 'Calories and macros are recalculated when you change the amount.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    context.ota(
                      'gramAmount',
                      tr: '{amount} g',
                      en: '{amount} g',
                      replacements: {'amount': selectedGrams.round()},
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Slider(
                  key: const Key('portion-slider'),
                  value: selectedGrams.clamp(5, 500),
                  min: 5,
                  max: 500,
                  divisions: 99,
                  activeColor: AppColors.limeDark,
                  inactiveColor: AppColors.line,
                  onChanged: (value) =>
                      setSheetState(() => selectedGrams = value),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  key: const Key('save-portion-button'),
                  onPressed: () => Navigator.pop(context, selectedGrams),
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
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.destructive,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                context.ota(
                  'deleteMealConfirmTitle',
                  tr: 'Bu öğün silinsin mi?',
                  en: 'Delete this meal?',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 7),
              Text(
                context.ota(
                  'deleteMealConfirmBody',
                  tr: 'Günlük toplamların bu öğün olmadan yeniden hesaplanacak.',
                  en: 'Your daily totals will be recalculated without this meal.',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.destructive,
                  foregroundColor: AppColors.onDark,
                ),
                child: Text(
                  context.ota(
                    'deleteMealAction',
                    tr: 'Öğünü sil',
                    en: 'Delete meal',
                  ),
                ),
              ),
              const SizedBox(height: 6),
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
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                _MealImage(meal: _meal),
                const SizedBox(height: 14),
                _MealSummary(meal: _meal, nutrition: nutrition),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.ota(
                          'foodsTitle',
                          tr: 'Yiyecekler',
                          en: 'Foods',
                        ),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      context.ota(
                        'foodCount',
                        tr: '{count} yiyecek',
                        en: '{count} foods',
                        replacements: {'count': _meal.items.length},
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                _IngredientList(items: _meal.items, onTap: _editItem),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _confirmDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.destructive,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: Text(
                    context.ota(
                      'deleteMealAction',
                      tr: 'Öğünü sil',
                      en: 'Delete meal',
                    ),
                  ),
                ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.feature),
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: (constraints.maxWidth * 3 / 4).clamp(240, 360),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (meal.imageAsset != null)
                Hero(
                  tag: 'meal-image-${meal.id}',
                  child: Image.asset(
                    meal.imageAsset!,
                    fit: BoxFit.cover,
                    cacheWidth: 900,
                  ),
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
                left: 14,
                right: 14,
                bottom: 14,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(AppRadius.input),
                    ),
                    child: Text(
                      meal.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onDark,
                      ),
                    ),
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

class _MealSummary extends StatelessWidget {
  const _MealSummary({required this.meal, required this.nutrition});

  final LoggedMeal meal;
  final Nutrition nutrition;

  @override
  Widget build(BuildContext context) {
    return HeroCardSurface(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.ota(
                        'mealTimeToday',
                        tr: 'Bugün · {time}',
                        en: 'Today · {time}',
                        replacements: {'time': meal.timeLabel},
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                context.ota(
                  'calorieAmount',
                  tr: '{amount} kcal',
                  en: '{amount} kcal',
                  replacements: {'amount': nutrition.calories.round()},
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.line),
          const SizedBox(height: 14),
          _MacroStrip(nutrition: nutrition),
        ],
      ),
    );
  }
}

class _MacroStrip extends StatelessWidget {
  const _MacroStrip({required this.nutrition});

  final Nutrition nutrition;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
      ],
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
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
      ),
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
                indent: 15,
                endIndent: 15,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 13, 12, 13),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.portionLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                context.ota(
                  'calorieAmount',
                  tr: '{amount} kcal',
                  en: '{amount} kcal',
                  replacements: {'amount': item.nutrition.calories.round()},
                ),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
