import 'package:flutter/foundation.dart';

import '../domain/models.dart';

class MealDetailViewModel extends ChangeNotifier {
  MealDetailViewModel({required LoggedMeal meal}) : _meal = meal;

  LoggedMeal _meal;

  LoggedMeal get meal => _meal;
  Nutrition get nutrition => _meal.nutrition;

  LoggedMeal updatePortion(MealItem item, double grams) {
    final updatedItem = item.copyWith(
      grams: grams,
      portionLabel: '${grams.round()} g',
      matchState: MatchState.matched,
    );
    _meal = _meal.copyWith(
      items: _meal.items
          .map((candidate) => candidate.id == item.id ? updatedItem : candidate)
          .toList(growable: false),
    );
    notifyListeners();
    return _meal;
  }
}
