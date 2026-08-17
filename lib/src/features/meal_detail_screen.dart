import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../theme/app_theme.dart';

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
  late LoggedMeal _meal = widget.meal;

  Future<void> _editItem(MealItem item) async {
    var selectedGrams = item.grams;
    final grams = await showModalBottomSheet<double>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
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
              const SizedBox(height: 8),
              Text(
                'Miktarı değiştirince öğün toplamı yeniden hesaplanır.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '${selectedGrams.round()} g',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
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
                child: const Text('Miktarı güncelle'),
              ),
            ],
          ),
        ),
      ),
    );
    if (grams == null || !mounted) return;

    final updatedItem = item.copyWith(
      grams: grams,
      portionLabel: '${grams.round()} g',
      matchState: MatchState.matched,
    );
    final updatedMeal = _meal.copyWith(
      items: _meal.items
          .map((candidate) => candidate.id == item.id ? updatedItem : candidate)
          .toList(growable: false),
    );
    setState(() => _meal = updatedMeal);
    widget.onUpdate(updatedMeal);
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFD93025),
              size: 34,
            ),
            const SizedBox(height: 12),
            Text(
              'Bu öğün silinsin mi?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Günlük toplamların bu öğün olmadan yeniden hesaplanacak.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD93025),
                foregroundColor: Colors.white,
              ),
              child: const Text('Öğünü sil'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
          ],
        ),
      ),
    );
    if (shouldDelete == true) widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final nutrition = _meal.nutrition;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 286,
            backgroundColor: AppColors.canvas,
            surfaceTintColor: Colors.transparent,
            leading: IconButton.filledTonal(
              tooltip: 'Geri',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_meal.imageAsset != null)
                    Hero(
                      tag: 'meal-image-${_meal.id}',
                      child: Image.asset(
                        _meal.imageAsset!,
                        fit: BoxFit.cover,
                        cacheWidth: 900,
                      ),
                    )
                  else
                    const ColoredBox(color: Color(0xFFF0F3E5)),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x55000000), Colors.transparent],
                        stops: [0, 0.45],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xDDFFFFFF),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'Katalog görseli',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              22,
              24,
              22,
              28 + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverList.list(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _meal.name,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Bugün · ${_meal.timeLabel}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${nutrition.calories.round()} kcal',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _MacroStrip(nutrition: nutrition),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Yiyecekler',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Düzenlemek için dokun',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < _meal.items.length;
                        index++
                      ) ...[
                        _IngredientRow(
                          item: _meal.items[index],
                          onTap: () => _editItem(_meal.items[index]),
                        ),
                        if (index < _meal.items.length - 1)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _confirmDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD93025),
                    side: const BorderSide(color: Color(0xFFF2C2BE)),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Öğünü sil'),
                ),
              ],
            ),
          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _Macro(
            label: 'Protein',
            value: nutrition.protein,
            color: AppColors.protein,
          ),
          _Macro(
            label: 'Karbonhidrat',
            value: nutrition.carbs,
            color: AppColors.carbs,
          ),
          _Macro(label: 'Yağ', value: nutrition.fat, color: AppColors.fat),
        ],
      ),
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
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${value.round()} g',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 9),
          Container(
            width: 34,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
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
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      title: Text(item.name, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(item.portionLabel),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${item.nutrition.calories.round()} kcal',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.edit_outlined, size: 19, color: AppColors.muted),
        ],
      ),
    );
  }
}
