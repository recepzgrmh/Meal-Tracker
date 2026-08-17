import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../domain/models.dart';

class TodayViewModel extends ChangeNotifier {
  TodayViewModel({List<LoggedMeal> initialMeals = const []})
    : _meals = List.of(initialMeals);

  final List<LoggedMeal> _meals;

  UnmodifiableListView<LoggedMeal> get meals => UnmodifiableListView(_meals);

  Nutrition get total =>
      _meals.fold(Nutrition.zero, (sum, meal) => sum + meal.nutrition);

  LoggedMeal logDraft(MealDraft draft, DateTime loggedAt) {
    final meal = LoggedMeal(
      id: 'meal-${loggedAt.microsecondsSinceEpoch}',
      name: draft.mealName,
      timeLabel:
          '${loggedAt.hour.toString().padLeft(2, '0')}:${loggedAt.minute.toString().padLeft(2, '0')}',
      items: draft.items,
      imageAsset: 'assets/images/breakfast.png',
    );
    _meals.insert(0, meal);
    notifyListeners();
    return meal;
  }

  void updateMeal(LoggedMeal updated) {
    final index = _meals.indexWhere((meal) => meal.id == updated.id);
    if (index == -1) return;
    _meals[index] = updated;
    notifyListeners();
  }

  LoggedMeal? deleteMeal(String id) {
    final index = _meals.indexWhere((meal) => meal.id == id);
    if (index == -1) return null;
    final removed = _meals.removeAt(index);
    notifyListeners();
    return removed;
  }

  void restoreMeal(LoggedMeal meal) {
    if (_meals.any((candidate) => candidate.id == meal.id)) return;
    _meals.insert(0, meal);
    notifyListeners();
  }
}
