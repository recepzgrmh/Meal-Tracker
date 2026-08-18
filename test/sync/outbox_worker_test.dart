import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/local/app_database.dart';
import 'package:meal_clarity/src/local/outbox_dao.dart';
import 'package:meal_clarity/src/sync/mutation_gateway.dart';
import 'package:meal_clarity/src/sync/outbox_worker.dart';

void main() {
  late AppDatabase database;
  late OutboxDao outbox;
  late FakeMutationGateway gateway;
  late DateTime now;
  late OutboxWorker worker;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    outbox = OutboxDao(database);
    gateway = FakeMutationGateway();
    now = DateTime.utc(2026, 8, 17, 12);
    worker = OutboxWorker(
      outbox: outbox,
      gateway: gateway,
      clock: () => now,
      jitter: () => 0.5,
    );
  });

  tearDown(() => database.close());

  test('processes exactly one operation and marks it succeeded', () async {
    await database
        .into(database.localMeals)
        .insert(
          LocalMealsCompanion.insert(
            id: 'meal-first',
            userId: 'user-a',
            name: 'Kahvaltı',
            eatenAt: now,
            syncStatus: const Value('pending'),
            localUpdatedAt: now,
          ),
        );
    await _insert(database, _operation('first', now));
    await _insert(database, _operation('second', now));

    final result = await worker.runOnce('user-a');

    expect(result.outcome, SyncRunOutcome.succeeded);
    expect(result.operationId, 'first');
    expect(gateway.executedIds, ['first']);
    expect(
      (await _read(database, 'first')).status,
      SyncOperationStatus.succeeded,
    );
    expect(
      (await _read(database, 'second')).status,
      SyncOperationStatus.pending,
    );
    final meal = await database.select(database.localMeals).getSingle();
    expect(meal.syncStatus, 'synced');
    expect(meal.rowVersion, 2);
  });

  test(
    'transient failure schedules deterministic full-jitter backoff',
    () async {
      await _insert(database, _operation('retry', now));
      gateway.failure = const SyncFailure(
        kind: SyncFailureKind.transient,
        code: 'network',
      );

      final result = await worker.runOnce('user-a');
      final stored = await _read(database, 'retry');

      expect(result.outcome, SyncRunOutcome.retryScheduled);
      expect(result.nextAttemptAt, now.add(const Duration(seconds: 1)));
      expect(stored.attemptCount, 1);
      expect(stored.lastErrorCode, 'network');

      now = now.add(const Duration(milliseconds: 999));
      expect((await worker.runOnce('user-a')).outcome, SyncRunOutcome.idle);
      now = now.add(const Duration(milliseconds: 1));
      expect(
        (await worker.runOnce('user-a')).outcome,
        SyncRunOutcome.retryScheduled,
      );
    },
  );

  test('validation failure is blocked without automatic retry', () async {
    await _insert(database, _operation('invalid', now));
    gateway.failure = const SyncFailure(
      kind: SyncFailureKind.validation,
      code: 'invalid_grams',
    );

    final result = await worker.runOnce('user-a');
    final stored = await _read(database, 'invalid');

    expect(result.outcome, SyncRunOutcome.blocked);
    expect(stored.status, SyncOperationStatus.blocked);
    expect(stored.lastErrorCode, 'invalid_grams');
    expect((await worker.runOnce('user-a')).outcome, SyncRunOutcome.idle);
  });

  test('retry exhaustion becomes blocked', () async {
    await _insert(database, _operation('exhausted', now, attemptCount: 5));
    gateway.failure = const SyncFailure(
      kind: SyncFailureKind.transient,
      code: 'timeout',
    );

    await worker.runOnce('user-a');
    final stored = await _read(database, 'exhausted');

    expect(stored.status, SyncOperationStatus.blocked);
    expect(stored.lastErrorCode, 'retry_exhausted:timeout');
  });

  test(
    'recovery makes interrupted work eligible after process restart',
    () async {
      await _insert(
        database,
        _operation('interrupted', now, status: SyncOperationStatus.inFlight),
      );

      await worker.recoverInterrupted('user-a');
      final result = await worker.runOnce('user-a');

      expect(result.outcome, SyncRunOutcome.succeeded);
      expect(gateway.executedIds, ['interrupted']);
    },
  );
}

class FakeMutationGateway implements MutationGateway {
  final List<String> executedIds = [];
  SyncFailure? failure;

  @override
  Future<MutationResult> execute(SyncOperation operation) async {
    executedIds.add(operation.id);
    final value = failure;
    if (value != null) throw value;
    return MutationResult(mealId: operation.entityId, rowVersion: 2);
  }
}

SyncOperationsCompanion _operation(
  String id,
  DateTime now, {
  String status = SyncOperationStatus.pending,
  int attemptCount = 0,
}) {
  return SyncOperationsCompanion.insert(
    id: id,
    userId: 'user-a',
    entityType: 'meal',
    entityId: 'meal-$id',
    operationType: 'upsert',
    payloadJson: '{}',
    status: Value(status),
    attemptCount: Value(attemptCount),
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _insert(
  AppDatabase database,
  SyncOperationsCompanion operation,
) async {
  await database.into(database.syncOperations).insert(operation);
}

Future<SyncOperation> _read(AppDatabase database, String id) {
  return (database.select(
    database.syncOperations,
  )..where((row) => row.id.equals(id))).getSingle();
}
