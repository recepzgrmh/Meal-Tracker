import 'package:flutter/material.dart';

import 'data/meal_repository.dart';
import 'domain/models.dart';
import 'features/meal_flow.dart';
import 'features/meal_detail_screen.dart';
import 'features/today_screen.dart';
import 'theme/app_theme.dart';

class MealClarityApp extends StatefulWidget {
  const MealClarityApp({super.key});

  @override
  State<MealClarityApp> createState() => _MealClarityAppState();
}

class _MealClarityAppState extends State<MealClarityApp> {
  final MealRepository _repository = MockMealRepository();
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final List<LoggedMeal> _meals = [
    LoggedMeal(
      id: 'lunch',
      name: 'Öğle Yemeği',
      timeLabel: '12:34',
      imageAsset: 'assets/images/chicken-salad.png',
      items: const [
        MealItem(
          id: 'chicken-salad',
          name: 'Tavuklu Salata',
          sourceText: 'tavuklu salata',
          portionLabel: '1 büyük kase',
          grams: 350,
          nutritionPer100g: Nutrition(
            calories: 174.3,
            protein: 12,
            carbs: 8,
            fat: 10,
          ),
          matchState: MatchState.matched,
        ),
      ],
    ),
    LoggedMeal(
      id: 'snack',
      name: 'Ara Öğün',
      timeLabel: '16:15',
      imageAsset: 'assets/images/banana-yogurt.png',
      items: const [
        MealItem(
          id: 'banana-yogurt',
          name: 'Muzlu Yoğurt',
          sourceText: 'muzlu yoğurt',
          portionLabel: '1 kase · 250 g',
          grams: 250,
          nutritionPer100g: Nutrition(
            calories: 76,
            protein: 3,
            carbs: 12,
            fat: 2,
          ),
          matchState: MatchState.matched,
        ),
      ],
    ),
  ];

  Future<void> _startMealFlow() async {
    final draft = await _navigatorKey.currentState!.push<MealDraft>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MealFlow(repository: _repository),
      ),
    );
    if (draft == null || !mounted) return;

    final mealId = 'meal-${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();
    final timeLabel =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      _meals.insert(
        0,
        LoggedMeal(
          id: mealId,
          name: draft.mealName,
          timeLabel: timeLabel,
          items: draft.items,
          imageAsset: 'assets/images/breakfast.png',
        ),
      );
    });

    _messengerKey.currentState!.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text('${draft.mealName} kaydedildi'),
        action: SnackBarAction(
          label: 'Geri al',
          textColor: AppColors.lime,
          onPressed: () =>
              setState(() => _meals.removeWhere((meal) => meal.id == mealId)),
        ),
      ),
    );
  }

  Future<void> _openMeal(LoggedMeal meal) async {
    await _navigatorKey.currentState!.push<void>(
      MaterialPageRoute(
        builder: (_) => MealDetailScreen(
          meal: meal,
          onUpdate: (updated) {
            setState(() {
              final index = _meals.indexWhere((item) => item.id == updated.id);
              if (index != -1) _meals[index] = updated;
            });
          },
          onDelete: () {
            setState(() => _meals.removeWhere((item) => item.id == meal.id));
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
      home: TodayScreen(
        meals: _meals,
        onAddMeal: _startMealFlow,
        onMealTap: _openMeal,
      ),
    );
  }
}
