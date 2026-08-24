import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/domain/models.dart';
import 'package:meal_clarity/src/local/app_database.dart';
import 'package:meal_clarity/src/local/meal_dao.dart';
import 'package:meal_clarity/src/meals/data/cached_meal_repository.dart';
import 'package:meal_clarity/src/meals/data/meal_remote_data_source.dart';
import 'package:meal_clarity/src/meals/data/meal_remote_dto.dart';

void main() {
  late AppDatabase database;
  late MealDao local;
  late FakeMealRemoteDataSource remote;
  late CachedMealRepository repository;
  final now = DateTime.utc(2026, 8, 17, 8, 42);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    local = MealDao(database);
    remote = FakeMealRemoteDataSource();
    repository = CachedMealRepository(
      local: local,
      remote: remote,
      operationIdFactory: () => 'operation-1',
      clock: () => now,
    );
  });

  tearDown(() => database.close());

  test(
    'optimistic save emits from cache and persists replay payload',
    () async {
      await repository.saveOptimistically(
        userId: 'user-a',
        meal: _domainMeal(name: 'Yerel Kahvaltı'),
        eatenAt: now,
      );

      final meals = await repository.watchDay(userId: 'user-a', day: now).first;
      final operation = await database
          .select(database.syncOperations)
          .getSingle();
      final payload = jsonDecode(operation.payloadJson) as Map<String, dynamic>;

      expect(meals.single.name, 'Yerel Kahvaltı');
      expect(meals.single.items.single.portionLabel, '1 adet · 50 g');
      expect(operation.id, 'operation-1');
      expect(payload['operation_id'], 'operation-1');
      expect(payload['client_request_id'], 'operation-1');
    },
  );

  test('refresh maps remote rows into the local source of truth', () async {
    remote.meals = [_remoteMeal(name: 'Uzak Kahvaltı')];

    await repository.refreshDay(userId: 'user-a', day: now);
    final meals = await repository.watchDay(userId: 'user-a', day: now).first;

    expect(remote.fetchCount, 1);
    expect(meals.single.name, 'Uzak Kahvaltı');
    expect(meals.single.items.single.matchState, MatchState.matched);
  });

  test('grounded save persists a durable commit-meal operation', () async {
    final meal = _domainMeal(
      name: 'AI Kahvaltısı',
      itemId: '018f6a5e-3528-7b52-a47d-2d5efc3b2f69',
    );
    const draft = MealDraft(
      inputText: '2 yumurta',
      mealName: 'AI Kahvaltısı',
      analysisRunId: 'analysis-run-1',
      traceId: 'trace-1',
      items: [
        MealItem(
          id: '018f6a5e-3528-7b52-a47d-2d5efc3b2f69',
          analysisItemKey: 'item-key-1',
          foodId: 'food-egg',
          name: 'Yumurta',
          sourceText: '2 yumurta',
          portionLabel: '2 adet',
          grams: 100,
          nutritionPer100g: Nutrition(
            calories: 155,
            protein: 12.6,
            carbs: 1.1,
            fat: 10.6,
          ),
          matchState: MatchState.matched,
        ),
      ],
    );

    await repository.saveAnalyzedOptimistically(
      userId: 'user-a',
      meal: meal,
      draft: draft,
      eatenAt: now,
    );

    final operation = await database
        .select(database.syncOperations)
        .getSingle();
    final payload = jsonDecode(operation.payloadJson) as Map<String, dynamic>;
    final items = payload['items'] as List<dynamic>;
    expect(operation.operationType, 'commit');
    expect(payload['analysisRunId'], 'analysis-run-1');
    expect(payload['commitRequestId'], 'operation-1');
    expect((items.single as Map<String, dynamic>)['foodId'], 'food-egg');
    expect(items.single['itemId'], '018f6a5e-3528-7b52-a47d-2d5efc3b2f69');
    expect(items.single['itemKey'], 'item-key-1');
    expect(items.single, isNot(contains('calories')));
  });

  test(
    'estimate commit sends estimateId and never writes a foodId key',
    () async {
      const estimateItem = MealItem(
        id: '018f6a5e-3528-7b52-a47d-2d5efc3b2f70',
        analysisItemKey: 'item-key-estimate',
        estimateId: '0190aaaa-bbbb-7ccc-8ddd-eeeeffff0001',
        matchMethod: 'ai_estimate',
        sourceName: '',
        name: 'Kısır',
        sourceText: 'ev yapımı kısır',
        portionLabel: '150 g',
        grams: 150,
        nutritionPer100g: Nutrition(
          calories: 190,
          protein: 4.2,
          carbs: 30.1,
          fat: 6.4,
        ),
        matchState: MatchState.matched,
      );
      final meal = LoggedMeal(
        id: 'meal-estimate',
        name: 'Akşam yemeği',
        timeLabel: '08:42',
        items: const [estimateItem],
      );
      const draft = MealDraft(
        inputText: 'ev yapımı kısır',
        mealName: 'Akşam yemeği',
        analysisRunId: 'analysis-run-2',
        traceId: 'trace-2',
        items: [estimateItem],
      );

      await repository.saveAnalyzedOptimistically(
        userId: 'user-a',
        meal: meal,
        draft: draft,
        eatenAt: now,
      );

      final operation = await database
          .select(database.syncOperations)
          .getSingle();
      final payload = jsonDecode(operation.payloadJson) as Map<String, dynamic>;
      final item = (payload['items'] as List).single as Map<String, dynamic>;
      expect(item['estimateId'], '0190aaaa-bbbb-7ccc-8ddd-eeeeffff0001');
      // A JSON `"foodId": null` still counts as "sent" to the exactly-one
      // validator, so the key must be absent entirely.
      expect(item, isNot(contains('foodId')));
    },
  );

  test('grounded commit keeps foodId and never writes an estimateId key', () async {
    final meal = _domainMeal(
      name: 'Kahvaltı',
      itemId: '018f6a5e-3528-7b52-a47d-2d5efc3b2f71',
    );
    const draft = MealDraft(
      inputText: '2 yumurta',
      mealName: 'Kahvaltı',
      analysisRunId: 'analysis-run-3',
      traceId: 'trace-3',
      items: [
        MealItem(
          id: '018f6a5e-3528-7b52-a47d-2d5efc3b2f71',
          analysisItemKey: 'item-key-1',
          foodId: 'food-egg',
          name: 'Yumurta',
          sourceText: '2 yumurta',
          portionLabel: '2 adet',
          grams: 100,
          nutritionPer100g: Nutrition(
            calories: 155,
            protein: 12.6,
            carbs: 1.1,
            fat: 10.6,
          ),
          matchState: MatchState.matched,
        ),
      ],
    );

    await repository.saveAnalyzedOptimistically(
      userId: 'user-a',
      meal: meal,
      draft: draft,
      eatenAt: now,
    );

    final operation = await database.select(database.syncOperations).getSingle();
    final payload = jsonDecode(operation.payloadJson) as Map<String, dynamic>;
    final item = (payload['items'] as List).single as Map<String, dynamic>;
    expect(item['foodId'], 'food-egg');
    expect(item, isNot(contains('estimateId')));
  });

  test('refuses to commit an item with neither or both authorities', () async {
    const base = MealItem(
      id: 'item-broken',
      name: 'Bilinmeyen',
      sourceText: 'bilinmeyen',
      portionLabel: '100 g',
      grams: 100,
      nutritionPer100g: Nutrition(calories: 1, protein: 0, carbs: 0, fat: 0),
      matchState: MatchState.matched,
    );
    const both = MealItem(
      id: 'item-broken',
      name: 'Bilinmeyen',
      sourceText: 'bilinmeyen',
      portionLabel: '100 g',
      grams: 100,
      nutritionPer100g: Nutrition(calories: 1, protein: 0, carbs: 0, fat: 0),
      matchState: MatchState.matched,
      foodId: 'food-x',
      estimateId: '0190aaaa-bbbb-7ccc-8ddd-eeeeffff0002',
    );
    for (final item in const [base, both]) {
      final meal = LoggedMeal(
        id: 'meal-broken',
        name: 'Öğün',
        timeLabel: '08:42',
        items: [item],
      );
      final draft = MealDraft(
        inputText: 'bilinmeyen',
        mealName: 'Öğün',
        analysisRunId: 'analysis-run-4',
        traceId: 'trace-4',
        items: [item],
      );

      await expectLater(
        repository.saveAnalyzedOptimistically(
          userId: 'user-a',
          meal: meal,
          draft: draft,
          eatenAt: now,
        ),
        throwsArgumentError,
      );
    }
  });

  test('match method survives the local cache round-trip', () async {
    final meal = LoggedMeal(
      id: 'meal-ai',
      name: 'AI Öğünü',
      timeLabel: '08:42',
      items: const [
        MealItem(
          id: 'item-ai',
          name: 'Kısır',
          sourceText: 'kısır',
          portionLabel: '150 g',
          grams: 150,
          nutritionPer100g: Nutrition(
            calories: 190,
            protein: 4.2,
            carbs: 30.1,
            fat: 6.4,
          ),
          matchState: MatchState.matched,
          matchMethod: 'ai_estimate',
        ),
      ],
    );

    await repository.saveOptimistically(
      userId: 'user-a',
      meal: meal,
      eatenAt: now,
    );
    final cached = await repository.watchDay(userId: 'user-a', day: now).first;

    // The AI-estimate marker in the meal detail hangs off this flag, so a
    // meal reopened from the cache must not lose it.
    expect(cached.single.items.single.matchMethod, 'ai_estimate');
    expect(cached.single.items.single.isAiEstimate, isTrue);
  });

  test('refresh keeps the server-recorded match method', () async {
    remote.meals = [
      _remoteMeal(name: 'Uzak AI Öğünü', matchMethod: 'ai_estimate'),
    ];

    await repository.refreshDay(userId: 'user-a', day: now);
    final meals = await repository.watchDay(userId: 'user-a', day: now).first;

    expect(meals.single.items.single.matchMethod, 'ai_estimate');
    expect(meals.single.items.single.isAiEstimate, isTrue);
  });

  test('refresh never overwrites an unsynced optimistic mutation', () async {
    await repository.saveOptimistically(
      userId: 'user-a',
      meal: _domainMeal(name: 'Düzenlenmiş Yerel Öğün'),
      eatenAt: now,
    );
    remote.meals = [_remoteMeal(name: 'Eski Uzak Öğün')];

    await repository.refreshDay(userId: 'user-a', day: now);
    final meals = await repository.watchDay(userId: 'user-a', day: now).first;

    expect(meals.single.name, 'Düzenlenmiş Yerel Öğün');
  });

  test('remote failure leaves the cached meal available', () async {
    await repository.saveOptimistically(
      userId: 'user-a',
      meal: _domainMeal(name: 'Çevrimdışı Öğün'),
      eatenAt: now,
    );
    remote.error = StateError('offline');

    await expectLater(
      repository.refreshDay(userId: 'user-a', day: now),
      throwsStateError,
    );
    final meals = await repository.watchDay(userId: 'user-a', day: now).first;
    expect(meals.single.name, 'Çevrimdışı Öğün');
  });

  test('clearing a user drops their cached meals and pending sync', () async {
    await repository.saveOptimistically(
      userId: 'user-a',
      meal: _domainMeal(name: 'Silinecek Öğün'),
      eatenAt: now,
    );
    await repository.saveOptimistically(
      userId: 'user-b',
      meal: _domainMeal(name: 'Kalacak Öğün', id: 'meal-2', itemId: 'item-2'),
      eatenAt: now,
    );

    await repository.clearUser('user-a');

    final cleared = await repository.watchDay(userId: 'user-a', day: now).first;
    expect(cleared, isEmpty);
    final operations = await database.select(database.syncOperations).get();
    expect(operations.every((row) => row.userId == 'user-b'), isTrue);

    // Signing out must not disturb another account cached on the same device.
    final retained = await repository
        .watchDay(userId: 'user-b', day: now)
        .first;
    expect(retained.single.name, 'Kalacak Öğün');
  });
}

class FakeMealRemoteDataSource implements MealRemoteDataSource {
  List<MealRemoteDto> meals = [];
  Object? error;
  int fetchCount = 0;

  @override
  Future<List<MealRemoteDto>> fetchWindow({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    fetchCount++;
    if (error case final value?) throw value;
    return meals;
  }
}

LoggedMeal _domainMeal({
  required String name,
  String id = 'meal-1',
  String itemId = 'item-1',
}) {
  return LoggedMeal(
    id: id,
    name: name,
    timeLabel: '08:42',
    items: [
      MealItem(
        id: itemId,
        name: 'Yumurta',
        sourceText: 'yumurta',
        portionLabel: '1 adet · 50 g',
        grams: 50,
        nutritionPer100g: const Nutrition(
          calories: 140,
          protein: 12.6,
          carbs: 0.7,
          fat: 9.5,
        ),
        matchState: MatchState.matched,
      ),
    ],
  );
}

MealRemoteDto _remoteMeal({required String name, String? matchMethod}) {
  return MealRemoteDto(
    id: 'meal-1',
    userId: 'user-a',
    clientRequestId: 'request-1',
    name: name,
    occurredAt: DateTime.utc(2026, 8, 17, 8, 42),
    updatedAt: DateTime.utc(2026, 8, 17, 9),
    rowVersion: 3,
    items: [
      MealItemRemoteDto(
        id: 'item-1',
        position: 0,
        sourceText: 'yumurta',
        canonicalName: 'Yumurta',
        portionLabel: '1 adet · 50 g',
        grams: 50,
        caloriesPer100g: 140,
        proteinPer100g: 12.6,
        carbsPer100g: 0.7,
        fatPer100g: 9.5,
        reviewStatus: 'accepted',
        nutritionSource: 'catalog',
        matchMethod: matchMethod,
      ),
    ],
  );
}
