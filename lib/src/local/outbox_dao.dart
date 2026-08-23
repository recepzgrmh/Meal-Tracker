import 'package:drift/drift.dart';

import 'app_database.dart';

abstract final class SyncOperationStatus {
  static const pending = 'pending';
  static const inFlight = 'in_flight';
  static const blocked = 'blocked';
  static const failed = 'failed';
  static const succeeded = 'succeeded';
}

/// How much work the outbox is still holding, split by whether it will move on
/// its own.
///
/// [pending] retries by itself; [blocked] has given up — [OutboxDao.nextReady]
/// only ever picks `pending` or `failed` rows, so a blocked operation stays put
/// until something requeues it. That difference is the whole reason the two are
/// counted apart: one is "wait", the other is "this needs you".
class OutboxSummary {
  const OutboxSummary({required this.pending, required this.blocked});

  static const empty = OutboxSummary(pending: 0, blocked: 0);

  final int pending;
  final int blocked;

  bool get isEmpty => pending == 0 && blocked == 0;

  @override
  bool operator ==(Object other) =>
      other is OutboxSummary &&
      other.pending == pending &&
      other.blocked == blocked;

  @override
  int get hashCode => Object.hash(pending, blocked);
}

class OutboxDao {
  const OutboxDao(this.database);

  final AppDatabase database;

  Stream<OutboxSummary> watchSummary(String userId) {
    final count = database.syncOperations.id.count();
    final status = database.syncOperations.status;
    final query = database.selectOnly(database.syncOperations)
      ..addColumns([status, count])
      ..where(
        database.syncOperations.userId.equals(userId) &
            status.isIn([
              SyncOperationStatus.pending,
              SyncOperationStatus.inFlight,
              SyncOperationStatus.failed,
              SyncOperationStatus.blocked,
            ]),
      )
      ..groupBy([status]);

    return query.watch().map((rows) {
      var pending = 0;
      var blocked = 0;
      for (final row in rows) {
        final rowCount = row.read(count) ?? 0;
        if (row.read(status) == SyncOperationStatus.blocked) {
          blocked += rowCount;
        } else {
          pending += rowCount;
        }
      }
      return OutboxSummary(pending: pending, blocked: blocked);
    });
  }

  /// Puts blocked operations back in the queue.
  ///
  /// The attempt counter resets too: the backoff ladder exists to stop a client
  /// hammering a server that is failing, and an explicit "try again" from the
  /// person holding the phone is a new intent, not the seventh automatic retry
  /// of the old one.
  Future<int> requeueBlocked(String userId, DateTime now) {
    return (database.update(database.syncOperations)..where(
          (row) =>
              row.userId.equals(userId) &
              row.status.equals(SyncOperationStatus.blocked),
        ))
        .write(
          SyncOperationsCompanion(
            status: const Value(SyncOperationStatus.pending),
            attemptCount: const Value(0),
            nextAttemptAt: const Value(null),
            lastErrorCode: const Value(null),
            updatedAt: Value(now),
          ),
        );
  }

  Stream<int> watchOutstandingCount(String userId) {
    final count = database.syncOperations.id.count();
    final query = database.selectOnly(database.syncOperations)
      ..addColumns([count])
      ..where(
        database.syncOperations.userId.equals(userId) &
            database.syncOperations.status.isIn([
              SyncOperationStatus.pending,
              SyncOperationStatus.inFlight,
              SyncOperationStatus.failed,
            ]),
      );
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<SyncOperation?> nextReady({
    required String userId,
    required DateTime now,
  }) {
    final query = database.select(database.syncOperations)
      ..where(
        (row) =>
            row.userId.equals(userId) &
            row.status.isIn([
              SyncOperationStatus.pending,
              SyncOperationStatus.failed,
            ]) &
            (row.nextAttemptAt.isNull() |
                row.nextAttemptAt.isSmallerOrEqualValue(now)),
      )
      ..orderBy([(row) => OrderingTerm.asc(row.createdAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<void> markInFlight(String operationId, DateTime now) {
    return _update(
      operationId,
      SyncOperationsCompanion(
        status: const Value(SyncOperationStatus.inFlight),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markSucceeded(
    SyncOperation operation,
    DateTime now, {
    int? rowVersion,
  }) {
    return database.transaction(() async {
      await _update(
        operation.id,
        SyncOperationsCompanion(
          status: const Value(SyncOperationStatus.succeeded),
          nextAttemptAt: const Value(null),
          lastErrorCode: const Value(null),
          updatedAt: Value(now),
        ),
      );
      if (operation.entityType == 'meal' &&
          (operation.operationType == 'upsert' ||
              operation.operationType == 'commit')) {
        await (database.update(database.localMeals)..where(
              (meal) =>
                  meal.id.equals(operation.entityId) &
                  meal.userId.equals(operation.userId),
            ))
            .write(
              LocalMealsCompanion(
                syncStatus: const Value('synced'),
                rowVersion: rowVersion == null
                    ? const Value.absent()
                    : Value(rowVersion),
                remoteUpdatedAt: Value(now),
              ),
            );
      }
    });
  }

  Future<void> markRetry({
    required SyncOperation operation,
    required DateTime nextAttemptAt,
    required String errorCode,
    required DateTime now,
  }) {
    return _update(
      operation.id,
      SyncOperationsCompanion(
        status: const Value(SyncOperationStatus.failed),
        attemptCount: Value(operation.attemptCount + 1),
        nextAttemptAt: Value(nextAttemptAt),
        lastErrorCode: Value(errorCode),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markBlocked({
    required String operationId,
    required String errorCode,
    required DateTime now,
  }) {
    return _update(
      operationId,
      SyncOperationsCompanion(
        status: const Value(SyncOperationStatus.blocked),
        nextAttemptAt: const Value(null),
        lastErrorCode: Value(errorCode),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> recoverInterrupted(String userId, DateTime now) {
    return (database.update(database.syncOperations)..where(
          (row) =>
              row.userId.equals(userId) &
              row.status.equals(SyncOperationStatus.inFlight),
        ))
        .write(
          SyncOperationsCompanion(
            status: const Value(SyncOperationStatus.pending),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> _update(
    String operationId,
    SyncOperationsCompanion values,
  ) async {
    await (database.update(
      database.syncOperations,
    )..where((row) => row.id.equals(operationId))).write(values);
  }
}
