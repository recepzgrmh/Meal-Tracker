import 'package:flutter/foundation.dart';

import '../domain/models.dart';

class MealDetailViewModel extends ChangeNotifier {
  MealDetailViewModel({required LoggedMeal meal}) : _meal = meal;

  LoggedMeal _meal;

  LoggedMeal get meal => _meal;
  Nutrition get nutrition => _meal.nutrition;

  /// True while any food in the meal is still an unreviewed estimate — or an
  /// AI-estimated one, which stays approximate however carefully it was
  /// reviewed — so the screen keeps admitting that the total is approximate.
  bool get hasEstimates => _meal.items.any(
    (item) => item.matchState != MatchState.matched || item.isAiEstimate,
  );

  /// What [item] would contribute at [grams], without touching stored state.
  ///
  /// The portion sheet promises that calories are recalculated, so it has to
  /// show the new number while the slider moves — long before anything is
  /// committed.
  Nutrition previewNutrition(MealItem item, double grams) =>
      item.nutritionPer100g.scale(grams / 100);

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
