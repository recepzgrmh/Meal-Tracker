import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';

typedef MealIdFactory = String Function();

class TodayViewModel extends ChangeNotifier {
  TodayViewModel({
    List<LoggedMeal> initialMeals = const [],
    MealIdFactory? idFactory,
    bool hasLoaded = true,
  }) : _meals = List.of(initialMeals),
       _idFactory = idFactory ?? const Uuid().v4,
       _hasLoaded = hasLoaded;

  final List<LoggedMeal> _meals;
  final MealIdFactory _idFactory;
  bool _hasLoaded;

  UnmodifiableListView<LoggedMeal> get meals => UnmodifiableListView(_meals);

  /// False until the meal source has answered at least once.
  ///
  /// Without this the shell could not tell "the day is empty" from "the day has
  /// not been read yet", so a cold start rendered the *empty state* — "no meals
  /// yet", with a button offering to add the first one — over a day that
  /// already had meals in it, until the first Drift emission replaced it. An
  /// empty state is a claim about the data; it must not be made before the data
  /// exists.
  bool get hasLoaded => _hasLoaded;

  Nutrition get total =>
      _meals.fold(Nutrition.zero, (sum, meal) => sum + meal.nutrition);

  LoggedMeal logDraft(MealDraft draft, DateTime loggedAt) {
    final meal = LoggedMeal(
      id: _idFactory(),
      name: draft.mealName,
      timeLabel:
          '${loggedAt.hour.toString().padLeft(2, '0')}:${loggedAt.minute.toString().padLeft(2, '0')}',
      // Previously left null while the rendered time was kept, which dropped
      // every freshly logged meal out of anything that groups or filters by
      // date — History's day rail included — until a sync round trip put the
      // timestamp back.
      occurredAt: loggedAt,
      items: draft.items
          .map(
            (item) => item.copyWith(
              // The production analyzer/manual picker already assigns the
              // durable client UUID. Legacy/mock drafts may still contain
              // semantic IDs such as "egg"; upgrade only those at the local
              // boundary so Supabase always receives a valid UUID.
              id: _isUuid(item.id) ? item.id : _idFactory(),
            ),
          )
          .toList(growable: false),
      imageAsset: draft.imageUrl,
      isPending: true,
    );
    _meals.insert(0, meal);
    _hasLoaded = true;
    notifyListeners();
    return meal;
  }

  void replaceAll(List<LoggedMeal> meals) {
    _meals
      ..clear()
      ..addAll(meals);
    _hasLoaded = true;
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

bool _isUuid(String value) => RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
).hasMatch(value);
