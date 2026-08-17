import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/local/app_database.dart';
import 'package:meal_clarity/src/local/meal_dao.dart';

void main() {
  late AppDatabase database;
  late MealDao mealDao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    mealDao = MealDao(database);
  });

  tearDown(() => database.close());

  test('v1 schema creates all offline and sync tables', () async {
    final tables = await database
        .customSelect(
          "select name from sqlite_master where type = 'table' order by name",
        )
        .map((row) => row.read<String>('name'))
        .get();

    expect(
      tables,
      containsAll([
        'local_profiles',
        'local_meals',
        'local_meal_items',
        'sync_operations',
        'sync_checkpoints',
        'app_preferences',
      ]),
    );
  });

  test(
    'meal query is partitioned by user and cascades item deletion',
    () async {
      final now = DateTime.utc(2026, 8, 17, 8, 42);
      await mealDao.putMeal(
        meal: _meal(id: 'meal-1', userId: 'user-a', eatenAt: now),
        items: [_item(id: 'item-1', mealId: 'meal-1', userId: 'user-a')],
      );

      final ownMeals = await mealDao.watchDay(userId: 'user-a', day: now).first;
      final otherMeals = await mealDao
          .watchDay(userId: 'user-b', day: now)
          .first;

      expect(ownMeals, hasLength(1));
      expect(ownMeals.single.items.single.name, 'Yumurta');
      expect(otherMeals, isEmpty);

      await (database.delete(
        database.localMeals,
      )..where((row) => row.id.equals('meal-1'))).go();
      expect(await database.select(database.localMealItems).get(), isEmpty);
    },
  );

  test(
    'meal mutation and idempotent outbox insert share one transaction',
    () async {
      final now = DateTime.utc(2026, 8, 17, 8, 42);
      final operation = _operation(
        id: 'operation-1',
        userId: 'user-a',
        entityId: 'meal-1',
        now: now,
      );

      await mealDao.putMeal(
        meal: _meal(id: 'meal-1', userId: 'user-a', eatenAt: now),
        items: [_item(id: 'item-1', mealId: 'meal-1', userId: 'user-a')],
        operation: operation,
      );
      await mealDao.putMeal(
        meal: _meal(id: 'meal-1', userId: 'user-a', eatenAt: now),
        items: [_item(id: 'item-1', mealId: 'meal-1', userId: 'user-a')],
        operation: operation,
      );

      expect(await database.select(database.localMeals).get(), hasLength(1));
      expect(
        await database.select(database.syncOperations).get(),
        hasLength(1),
      );
    },
  );
}

LocalMealsCompanion _meal({
  required String id,
  required String userId,
  required DateTime eatenAt,
}) {
  return LocalMealsCompanion.insert(
    id: id,
    userId: userId,
    name: 'Kahvaltı',
    eatenAt: eatenAt,
    localUpdatedAt: eatenAt,
  );
}

LocalMealItemsCompanion _item({
  required String id,
  required String mealId,
  required String userId,
}) {
  return LocalMealItemsCompanion.insert(
    id: id,
    mealId: mealId,
    userId: userId,
    name: 'Yumurta',
    sourceText: 'yumurta',
    portionLabel: '1 adet',
    grams: 50,
    caloriesPer100g: 140,
    proteinPer100g: 12.6,
    carbsPer100g: 0.7,
    fatPer100g: 9.5,
    matchState: 'matched',
    sourceName: 'catalog',
    position: 0,
  );
}

SyncOperationsCompanion _operation({
  required String id,
  required String userId,
  required String entityId,
  required DateTime now,
}) {
  return SyncOperationsCompanion.insert(
    id: id,
    userId: userId,
    entityType: 'meal',
    entityId: entityId,
    operationType: 'upsert',
    payloadJson: '{}',
    createdAt: now,
    updatedAt: now,
  );
}
