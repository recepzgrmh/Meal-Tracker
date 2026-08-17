import 'package:flutter/material.dart';

import 'data/meal_repository.dart';
import 'data/mock_seed_data.dart';
import 'domain/models.dart';
import 'features/meal_detail_screen.dart';
import 'features/meal_flow.dart';
import 'features/today_screen.dart';
import 'theme/app_theme.dart';
import 'view_models/today_view_model.dart';

class MealClarityApp extends StatefulWidget {
  const MealClarityApp({super.key});

  @override
  State<MealClarityApp> createState() => _MealClarityAppState();
}

class _MealClarityAppState extends State<MealClarityApp> {
  final MealRepository _repository = MockMealRepository();
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
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

  Future<void> _startMealFlow() async {
    final draft = await _navigatorKey.currentState!.push<MealDraft>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MealFlow(repository: _repository),
      ),
    );
    if (draft == null || !mounted) return;

    final loggedMeal = _todayViewModel.logDraft(draft, DateTime.now());

    _messengerKey.currentState!.showSnackBar(
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

  Future<void> _openMeal(LoggedMeal meal) async {
    await _navigatorKey.currentState!.push<void>(
      MaterialPageRoute(
        builder: (_) => MealDetailScreen(
          meal: meal,
          onUpdate: _todayViewModel.updateMeal,
          onDelete: () {
            _todayViewModel.deleteMeal(meal.id);
            _navigatorKey.currentState!.pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Meal Clarity',
      theme: buildTheme(),
      home: ListenableBuilder(
        listenable: _todayViewModel,
        builder: (context, _) => TodayScreen(
          meals: _todayViewModel.meals,
          onAddMeal: _startMealFlow,
          onMealTap: _openMeal,
        ),
      ),
    );
  }
}
