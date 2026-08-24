import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../domain/models.dart';
import '../../local/app_database.dart';
import '../../local/meal_dao.dart';
import 'meal_persistence_mapper.dart';
import 'meal_remote_data_source.dart';

typedef OperationIdFactory = String Function();
typedef Clock = DateTime Function();

class CachedMealRepository {
  CachedMealRepository({
    required MealDao local,
    required MealRemoteDataSource remote,
    MealPersistenceMapper mapper = const MealPersistenceMapper(),
    OperationIdFactory? operationIdFactory,
    Clock? clock,
  }) : _local = local,
       _remote = remote,
       _mapper = mapper,
       _operationIdFactory = operationIdFactory ?? const Uuid().v4,
       _clock = clock ?? DateTime.now;

  final MealDao _local;
  final MealRemoteDataSource _remote;
  final MealPersistenceMapper _mapper;
  final OperationIdFactory _operationIdFactory;
  final Clock _clock;

  Stream<List<LoggedMeal>> watchDay({
    required String userId,
    required DateTime day,
  }) {
    return _local
        .watchDay(userId: userId, day: day)
        .map(
          (bundles) =>
              bundles.map(_mapper.localToDomain).toList(growable: false),
        );
  }

  Stream<List<LoggedMeal>> watchHistory(String userId) {
    return _local
        .watchHistory(userId)
        .map(
          (bundles) =>
              bundles.map(_mapper.localToDomain).toList(growable: false),
        );
  }

  Future<void> refreshDay({
    required String userId,
    required DateTime day,
  }) async {
    final from = DateTime(day.year, day.month, day.day);
    final to = from.add(const Duration(days: 1));
    await refreshWindow(userId: userId, from: from, to: to);
  }

  Future<void> refreshWindow({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final remoteMeals = await _remote.fetchWindow(
      userId: userId,
      from: from,
      to: to,
    );
    final localWrites = remoteMeals.map(_mapper.remoteToLocal).toList();
    await _local.replaceWindow(
      userId: userId,
      from: from,
      to: to,
      meals: localWrites.map((write) => write.meal).toList(growable: false),
      items: localWrites.expand((write) => write.items).toList(growable: false),
    );
  }

  Future<String> saveOptimistically({
    required String userId,
    required LoggedMeal meal,
    DateTime? eatenAt,
  }) async {
    final operationId = _operationIdFactory();
    final now = _clock();
    final existing = await _local.getMeal(userId: userId, mealId: meal.id);
    final effectiveEatenAt = eatenAt ?? existing?.meal.eatenAt ?? now;
    final write = _mapper.domainToLocal(
      userId: userId,
      meal: meal,
      eatenAt: effectiveEatenAt,
      updatedAt: now,
      rowVersion: existing?.meal.rowVersion ?? 1,
    );
    await _local.putMeal(
      meal: write.meal,
      items: write.items,
      operation: SyncOperationsCompanion.insert(
        id: operationId,
        userId: userId,
        entityType: 'meal',
        entityId: meal.id,
        operationType: 'upsert',
        payloadJson: jsonEncode(
          _mealPayload(
            operationId: operationId,
            userId: userId,
            meal: meal,
            eatenAt: effectiveEatenAt,
            expectedRowVersion: existing?.meal.rowVersion,
          ),
        ),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return operationId;
  }

  Future<String> saveAnalyzedOptimistically({
    required String userId,
    required LoggedMeal meal,
    required MealDraft draft,
    required DateTime eatenAt,
  }) async {
    final analysisRunId = draft.analysisRunId;
    // Each committed item references exactly one nutrition authority: a
    // catalog food or a server-recorded AI estimate. The commit function
    // rejects anything else, so the guard fails fast on the device instead.
    if (analysisRunId == null ||
        draft.items.any(
          (item) => (item.foodId == null) == (item.estimateId == null),
        ) ||
        draft.items.length != meal.items.length) {
      throw ArgumentError(
        'A grounded analysis run and exactly one of foodId or estimateId '
        'per item are required.',
      );
    }
    final operationId = _operationIdFactory();
    final now = _clock();
    final write = _mapper.domainToLocal(
      userId: userId,
      meal: meal,
      eatenAt: eatenAt,
      updatedAt: now,
    );
    await _local.putMeal(
      meal: write.meal,
      items: write.items,
      operation: SyncOperationsCompanion.insert(
        id: operationId,
        userId: userId,
        entityType: 'meal',
        entityId: meal.id,
        operationType: 'commit',
        payloadJson: jsonEncode({
          'analysisRunId': analysisRunId,
          'commitRequestId': operationId,
          'mealId': meal.id,
          'name': meal.name,
          'occurredAt': eatenAt.toUtc().toIso8601String(),
          'items': [
            for (final entry in draft.items.asMap().entries)
              {
                // The logged meal owns the durable local UUID. The draft owns
                // the analyzer item key used for proposal/correction diffing.
                'itemId': meal.items[entry.key].id,
                'itemKey':
                    entry.value.analysisItemKey ?? meal.items[entry.key].id,
                // The commit contract wants exactly one of the two keys
                // present — a JSON `"foodId": null` still counts as sent.
                if (entry.value.foodId case final foodId?)
                  'foodId': foodId
                else
                  'estimateId': entry.value.estimateId,
                'sourceText': entry.value.sourceText,
                'portionLabel': entry.value.portionLabel,
                'grams': entry.value.grams,
              },
          ],
        }),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return operationId;
  }

  Future<String> deleteOptimistically({
    required String userId,
    required String mealId,
  }) async {
    final operationId = _operationIdFactory();
    final now = _clock();
    final existing = await _local.getMeal(userId: userId, mealId: mealId);
    await _local.deleteMeal(
      userId: userId,
      mealId: mealId,
      operation: SyncOperationsCompanion.insert(
        id: operationId,
        userId: userId,
        entityType: 'meal',
        entityId: mealId,
        operationType: 'delete',
        payloadJson: jsonEncode({
          'schema_version': 1,
          'operation_id': operationId,
          'meal_id': mealId,
          'expected_row_version': existing?.meal.rowVersion,
        }),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return operationId;
  }

  /// Drops every locally cached row for [userId].
  ///
  /// Sign-out and account deletion both leave the Drift database untouched
  /// otherwise, so a shared device kept the previous user's meals, photos
  /// metadata and pending sync operations on disk. Deleting an account has to
  /// mean the local copy goes too, not just the server rows.
  Future<void> clearUser(String userId) => _local.clearUser(userId);

  Map<String, Object?> _mealPayload({
    required String operationId,
    required String userId,
    required LoggedMeal meal,
    required DateTime eatenAt,
    required int? expectedRowVersion,
  }) {
    return {
      'schema_version': 1,
      'operation_id': operationId,
      'client_request_id': operationId,
      'expected_row_version': expectedRowVersion,
      'meal': {
        'id': meal.id,
        'user_id': userId,
        'name': meal.name,
        'occurred_at': eatenAt.toUtc().toIso8601String(),
        'image_path': meal.imageAsset,
        'items': [
          for (final MapEntry(key: position, value: item)
              in meal.items.asMap().entries)
            {
              'id': item.id,
              'food_id': item.foodId,
              'position': position,
              'source_text': item.sourceText,
              'canonical_name': item.canonicalName,
              'portion_label': item.portionLabel,
              'grams': item.grams,
              'calories_per_100g': item.nutritionPer100g.calories,
              'protein_per_100g': item.nutritionPer100g.protein,
              'carbs_per_100g': item.nutritionPer100g.carbs,
              'fat_per_100g': item.nutritionPer100g.fat,
              'nutrition_source': item.sourceName,
            },
        ],
      },
    };
  }
}
