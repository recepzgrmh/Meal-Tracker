import 'package:drift/drift.dart';

import 'app_database.dart';

abstract final class SyncOperationStatus {
  static const pending = 'pending';
  static const inFlight = 'in_flight';
  static const blocked = 'blocked';
  static const failed = 'failed';
  static const succeeded = 'succeeded';
}

class OutboxDao {
  const OutboxDao(this.database);

  final AppDatabase database;

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

  Future<void> markSucceeded(String operationId, DateTime now) {
    return _update(
      operationId,
      SyncOperationsCompanion(
        status: const Value(SyncOperationStatus.succeeded),
        nextAttemptAt: const Value(null),
        lastErrorCode: const Value(null),
        updatedAt: Value(now),
      ),
    );
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
