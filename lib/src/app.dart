import 'package:flutter/material.dart';

import 'data/meal_repository.dart';
import 'data/mock_seed_data.dart';
import 'domain/models.dart';
import 'features/meal_detail_screen.dart';
import 'features/meal_flow.dart';
import 'features/today_screen.dart';
import 'theme/app_theme.dart';
import 'view_models/today_view_model.dart';

class MealClarityApp extends StatelessWidget {
  const MealClarityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meal Clarity',
      theme: buildTheme(),
      home: const MealClarityShell(),
    );
  }
}

class MealClarityShell extends StatefulWidget {
  const MealClarityShell({super.key});

  @override
  State<MealClarityShell> createState() => _MealClarityShellState();
}

class _MealClarityShellState extends State<MealClarityShell> {
  final MealRepository _repository = MockMealRepository();
  late final TodayViewModel _todayViewModel;

  @override
  void initState() {
    super.initState();
    _todayViewModel = TodayViewModel(initialMeals: buildMockMeals());
  }

  @override
  void dispose() {
    _todayViewModel.dispose();
    super.dispose();
  }

  Future<void> _startMealFlow(BuildContext context) async {
    final draft = await Navigator.of(context).push<MealDraft>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MealFlow(repository: _repository),
      ),
    );
    if (draft == null || !mounted) return;

    final loggedMeal = _todayViewModel.logDraft(draft, DateTime.now());

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text('${draft.mealName} kaydedildi'),
        action: SnackBarAction(
          label: 'Geri al',
          textColor: AppColors.lime,
          onPressed: () => _todayViewModel.deleteMeal(loggedMeal.id),
        ),
      ),
    );
  }

  Future<void> _openMeal(BuildContext context, LoggedMeal meal) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MealDetailScreen(
          meal: meal,
          onUpdate: _todayViewModel.updateMeal,
          onDelete: () {
            _todayViewModel.deleteMeal(meal.id);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _todayViewModel,
      builder: (context, _) => TodayScreen(
        meals: _todayViewModel.meals,
        onAddMeal: () => _startMealFlow(context),
        onMealTap: (meal) => _openMeal(context, meal),
      ),
    );
  }
}
