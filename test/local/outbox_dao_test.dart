import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/local/app_database.dart';
import 'package:meal_clarity/src/local/outbox_dao.dart';

void main() {
  late AppDatabase database;
  late OutboxDao outbox;
  final now = DateTime.utc(2026, 8, 17, 12);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    outbox = OutboxDao(database);
  });

  tearDown(() => database.close());

  test(
    'returns only ready operations for the active user in FIFO order',
    () async {
      await database.batch((batch) {
        batch.insertAll(database.syncOperations, [
          _operation('later', 'user-a', now.add(const Duration(seconds: 1))),
          _operation('first', 'user-a', now),
          _operation('other-user', 'user-b', now),
          _operation(
            'future',
            'user-a',
            now,
            nextAttemptAt: now.add(const Duration(hours: 1)),
          ),
        ]);
      });

      final operation = await outbox.nextReady(userId: 'user-a', now: now);

      expect(operation?.id, 'first');
    },
  );

  test('retry persists attempt, error code, and next eligible time', () async {
    await database
        .into(database.syncOperations)
        .insert(_operation('retry-me', 'user-a', now));
    final operation = await outbox.nextReady(userId: 'user-a', now: now);
    final retryAt = now.add(const Duration(seconds: 10));

    await outbox.markInFlight(operation!.id, now);
    await outbox.markRetry(
      operation: operation,
      nextAttemptAt: retryAt,
      errorCode: 'network',
      now: now,
    );

    final stored = await (database.select(
      database.syncOperations,
    )..where((row) => row.id.equals(operation.id))).getSingle();
    expect(stored.status, SyncOperationStatus.failed);
    expect(stored.attemptCount, 1);
    expect(stored.lastErrorCode, 'network');
    expect(stored.nextAttemptAt?.toUtc(), retryAt);
    expect(await outbox.nextReady(userId: 'user-a', now: now), isNull);
  });

  test('interrupted in-flight work becomes pending after restart', () async {
    await database
        .into(database.syncOperations)
        .insert(
          _operation(
            'interrupted',
            'user-a',
            now,
            status: SyncOperationStatus.inFlight,
          ),
        );

    expect(await outbox.recoverInterrupted('user-a', now), 1);
    expect(
      (await outbox.nextReady(userId: 'user-a', now: now))?.id,
      'interrupted',
    );
  });
}

SyncOperationsCompanion _operation(
  String id,
  String userId,
  DateTime createdAt, {
  String status = SyncOperationStatus.pending,
  DateTime? nextAttemptAt,
}) {
  return SyncOperationsCompanion.insert(
    id: id,
    userId: userId,
    entityType: 'meal',
    entityId: 'meal-$id',
    operationType: 'upsert',
    payloadJson: '{}',
    status: Value(status),
    nextAttemptAt: Value(nextAttemptAt),
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}
