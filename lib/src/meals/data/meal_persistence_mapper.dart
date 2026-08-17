import 'package:drift/drift.dart';

import '../../domain/models.dart';
import '../../local/app_database.dart';
import '../../local/meal_dao.dart';
import 'meal_remote_dto.dart';

class LocalMealWrite {
  const LocalMealWrite({required this.meal, required this.items});

  final LocalMealsCompanion meal;
  final List<LocalMealItemsCompanion> items;
}

class MealPersistenceMapper {
  const MealPersistenceMapper();

  LocalMealWrite remoteToLocal(MealRemoteDto remote) {
    return LocalMealWrite(
      meal: LocalMealsCompanion.insert(
        id: remote.id,
        userId: remote.userId,
        name: remote.name,
        rawInput: Value(remote.rawInput),
        eatenAt: remote.occurredAt,
        imageAsset: Value(remote.imagePath),
        syncStatus: const Value('synced'),
        localUpdatedAt: remote.updatedAt,
        remoteUpdatedAt: Value(remote.updatedAt),
      ),
      items: remote.items
          .map(
            (item) => LocalMealItemsCompanion.insert(
              id: item.id,
              mealId: remote.id,
              userId: remote.userId,
              foodId: Value(item.foodId),
              name: item.canonicalName,
              sourceText: item.sourceText,
              portionLabel: item.portionLabel,
              grams: item.grams,
              caloriesPer100g: item.caloriesPer100g,
              proteinPer100g: item.proteinPer100g,
              carbsPer100g: item.carbsPer100g,
              fatPer100g: item.fatPer100g,
              matchState: _matchStateForReview(item.reviewStatus).name,
              sourceName: item.nutritionSource,
              position: item.position,
            ),
          )
          .toList(growable: false),
    );
  }

  LocalMealWrite domainToLocal({
    required String userId,
    required LoggedMeal meal,
    required DateTime eatenAt,
    required DateTime updatedAt,
  }) {
    return LocalMealWrite(
      meal: LocalMealsCompanion.insert(
        id: meal.id,
        userId: userId,
        name: meal.name,
        eatenAt: eatenAt,
        imageAsset: Value(meal.imageAsset),
        syncStatus: const Value('pending'),
        localUpdatedAt: updatedAt,
      ),
      items: [
        for (final MapEntry(key: position, value: item)
            in meal.items.asMap().entries)
          LocalMealItemsCompanion.insert(
            id: item.id,
            mealId: meal.id,
            userId: userId,
            name: item.name,
            sourceText: item.sourceText,
            portionLabel: item.portionLabel,
            grams: item.grams,
            caloriesPer100g: item.nutritionPer100g.calories,
            proteinPer100g: item.nutritionPer100g.protein,
            carbsPer100g: item.nutritionPer100g.carbs,
            fatPer100g: item.nutritionPer100g.fat,
            matchState: item.matchState.name,
            sourceName: item.sourceName,
            position: position,
          ),
      ],
    );
  }

  LoggedMeal localToDomain(LocalMealBundle bundle) {
    final eatenAt = bundle.meal.eatenAt;
    return LoggedMeal(
      id: bundle.meal.id,
      name: bundle.meal.name,
      timeLabel:
          '${eatenAt.hour.toString().padLeft(2, '0')}:${eatenAt.minute.toString().padLeft(2, '0')}',
      imageAsset: bundle.meal.imageAsset,
      items: bundle.items
          .map(
            (item) => MealItem(
              id: item.id,
              name: item.name,
              sourceText: item.sourceText,
              portionLabel: item.portionLabel,
              grams: item.grams,
              nutritionPer100g: Nutrition(
                calories: item.caloriesPer100g,
                protein: item.proteinPer100g,
                carbs: item.carbsPer100g,
                fat: item.fatPer100g,
              ),
              matchState: MatchState.values.firstWhere(
                (state) => state.name == item.matchState,
                orElse: () => MatchState.checkType,
              ),
              sourceName: item.sourceName,
            ),
          )
          .toList(growable: false),
    );
  }

  MatchState _matchStateForReview(String reviewStatus) {
    return switch (reviewStatus) {
      'accepted' || 'corrected' => MatchState.matched,
      'rejected' => MatchState.notFound,
      _ => MatchState.checkAmount,
    };
  }
}
