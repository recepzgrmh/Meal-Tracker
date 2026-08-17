import 'package:drift/drift.dart';

import 'app_database.dart';

class LocalMealBundle {
  const LocalMealBundle({required this.meal, required this.items});

  final LocalMeal meal;
  final List<LocalMealItem> items;
}

class MealDao {
  const MealDao(this.database);

  final AppDatabase database;

  Stream<List<LocalMealBundle>> watchDay({
    required String userId,
    required DateTime day,
  }) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final query =
        database.select(database.localMeals).join([
            leftOuterJoin(
              database.localMealItems,
              database.localMealItems.mealId.equalsExp(database.localMeals.id) &
                  database.localMealItems.userId.equals(userId),
            ),
          ])
          ..where(
            database.localMeals.userId.equals(userId) &
                database.localMeals.eatenAt.isBiggerOrEqualValue(start) &
                database.localMeals.eatenAt.isSmallerThanValue(end),
          )
          ..orderBy([
            OrderingTerm.asc(database.localMeals.eatenAt),
            OrderingTerm.asc(database.localMealItems.position),
          ]);

    return query.watch().map(_groupRows);
  }

  Stream<List<LocalMealBundle>> watchHistory(String userId) {
    final query =
        database.select(database.localMeals).join([
            leftOuterJoin(
              database.localMealItems,
              database.localMealItems.mealId.equalsExp(database.localMeals.id) &
                  database.localMealItems.userId.equals(userId),
            ),
          ])
          ..where(database.localMeals.userId.equals(userId))
          ..orderBy([
            OrderingTerm.desc(database.localMeals.eatenAt),
            OrderingTerm.asc(database.localMealItems.position),
          ]);
    return query.watch().map(_groupRows);
  }

  Future<LocalMealBundle?> getMeal({
    required String userId,
    required String mealId,
  }) async {
    final query =
        database.select(database.localMeals).join([
            leftOuterJoin(
              database.localMealItems,
              database.localMealItems.mealId.equalsExp(database.localMeals.id) &
                  database.localMealItems.userId.equals(userId),
            ),
          ])
          ..where(
            database.localMeals.userId.equals(userId) &
                database.localMeals.id.equals(mealId),
          )
          ..orderBy([OrderingTerm.asc(database.localMealItems.position)]);
    final rows = await query.get();
    return rows.isEmpty ? null : _groupRows(rows).single;
  }

  Future<void> putMeal({
    required LocalMealsCompanion meal,
    required List<LocalMealItemsCompanion> items,
    SyncOperationsCompanion? operation,
  }) {
    return database.transaction(() async {
      await database.into(database.localMeals).insertOnConflictUpdate(meal);
      final mealId = meal.id.value;
      final userId = meal.userId.value;
      await (database.delete(database.localMealItems)..where(
            (row) => row.mealId.equals(mealId) & row.userId.equals(userId),
          ))
          .go();
      if (items.isNotEmpty) {
        await database.batch((batch) {
          batch.insertAll(database.localMealItems, items);
        });
      }
      if (operation != null) {
        await database
            .into(database.syncOperations)
            .insert(operation, mode: InsertMode.insertOrIgnore);
      }
    });
  }

  Future<void> deleteMeal({
    required String userId,
    required String mealId,
    required SyncOperationsCompanion operation,
  }) {
    return database.transaction(() async {
      await (database.delete(database.localMeals)
            ..where((row) => row.userId.equals(userId) & row.id.equals(mealId)))
          .go();
      await database
          .into(database.syncOperations)
          .insert(operation, mode: InsertMode.insertOrIgnore);
    });
  }

  Future<void> replaceWindow({
    required String userId,
    required DateTime from,
    required DateTime to,
    required List<LocalMealsCompanion> meals,
    required List<LocalMealItemsCompanion> items,
  }) {
    return database.transaction(() async {
      final replaceable =
          await (database.select(database.localMeals)..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.eatenAt.isBiggerOrEqualValue(from) &
                    row.eatenAt.isSmallerThanValue(to) &
                    row.syncStatus.equals('synced'),
              ))
              .get();
      final protectedIds =
          await (database.selectOnly(database.localMeals)
                ..addColumns([database.localMeals.id])
                ..where(
                  database.localMeals.userId.equals(userId) &
                      database.localMeals.eatenAt.isBiggerOrEqualValue(from) &
                      database.localMeals.eatenAt.isSmallerThanValue(to) &
                      database.localMeals.syncStatus.equals('pending'),
                ))
              .map((row) => row.read(database.localMeals.id)!)
              .get();
      if (replaceable.isNotEmpty) {
        await (database.delete(database.localMeals)
              ..where((row) => row.id.isIn(replaceable.map((meal) => meal.id))))
            .go();
      }
      final safeMeals = meals
          .where((meal) => !protectedIds.contains(meal.id.value))
          .toList(growable: false);
      final safeItems = items
          .where((item) => !protectedIds.contains(item.mealId.value))
          .toList(growable: false);
      await database.batch((batch) {
        batch.insertAllOnConflictUpdate(database.localMeals, safeMeals);
        batch.insertAllOnConflictUpdate(database.localMealItems, safeItems);
      });
    });
  }

  Future<void> clearUser(String userId) {
    return database.transaction(() async {
      await (database.delete(
        database.localMeals,
      )..where((row) => row.userId.equals(userId))).go();
      await (database.delete(
        database.localProfiles,
      )..where((row) => row.userId.equals(userId))).go();
      await (database.delete(
        database.syncOperations,
      )..where((row) => row.userId.equals(userId))).go();
      await (database.delete(
        database.syncCheckpoints,
      )..where((row) => row.userId.equals(userId))).go();
      await (database.delete(
        database.appPreferences,
      )..where((row) => row.userId.equals(userId))).go();
    });
  }

  List<LocalMealBundle> _groupRows(List<TypedResult> rows) {
    final meals = <String, LocalMealBundle>{};
    for (final row in rows) {
      final meal = row.readTable(database.localMeals);
      final item = row.readTableOrNull(database.localMealItems);
      final current = meals[meal.id];
      if (current == null) {
        meals[meal.id] = LocalMealBundle(
          meal: meal,
          items: item == null ? <LocalMealItem>[] : [item],
        );
      } else if (item != null) {
        current.items.add(item);
      }
    }
    return meals.values.toList(growable: false);
  }
}
