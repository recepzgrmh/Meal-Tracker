import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';

typedef MealIdFactory = String Function();

class TodayViewModel extends ChangeNotifier {
  TodayViewModel({
    List<LoggedMeal> initialMeals = const [],
    MealIdFactory? idFactory,
  }) : _meals = List.of(initialMeals),
       _idFactory = idFactory ?? const Uuid().v4;

  final List<LoggedMeal> _meals;
  final MealIdFactory _idFactory;

  UnmodifiableListView<LoggedMeal> get meals => UnmodifiableListView(_meals);

  Nutrition get total =>
      _meals.fold(Nutrition.zero, (sum, meal) => sum + meal.nutrition);

  LoggedMeal logDraft(MealDraft draft, DateTime loggedAt) {
    final meal = LoggedMeal(
      id: _idFactory(),
      name: draft.mealName,
      timeLabel:
          '${loggedAt.hour.toString().padLeft(2, '0')}:${loggedAt.minute.toString().padLeft(2, '0')}',
      items: draft.items
          .map((item) => item.copyWith(id: _idFactory()))
          .toList(growable: false),
      imageAsset: 'assets/images/breakfast.png',
    );
    _meals.insert(0, meal);
    notifyListeners();
    return meal;
  }

  void replaceAll(List<LoggedMeal> meals) {
    _meals
      ..clear()
      ..addAll(meals);
    notifyListeners();
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
