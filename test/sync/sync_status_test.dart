import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/local/app_database.dart';
import 'package:meal_clarity/src/local/outbox_dao.dart';
import 'package:meal_clarity/src/sync/sync_status.dart';

void main() {
  late AppDatabase database;
  late OutboxDao outbox;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    outbox = OutboxDao(database);
  });

  tearDown(() => database.close());

  Future<void> insert(String id, String status) {
    final now = DateTime(2026, 8, 22, 9);
    return database
        .into(database.syncOperations)
        .insert(
          SyncOperationsCompanion.insert(
            id: id,
            userId: 'user-a',
            entityType: 'meal',
            entityId: 'meal-$id',
            operationType: 'upsert',
            payloadJson: '{}',
            status: Value(status),
            attemptCount: const Value(6),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  group('OutboxDao.watchSummary', () {
    test('counts retryable work apart from work that gave up', () async {
      await insert('a', SyncOperationStatus.pending);
      await insert('b', SyncOperationStatus.inFlight);
      await insert('c', SyncOperationStatus.failed);
      await insert('d', SyncOperationStatus.blocked);
      await insert('e', SyncOperationStatus.succeeded);

      final summary = await outbox.watchSummary('user-a').first;

      expect(summary.pending, 3);
      expect(summary.blocked, 1);
      expect(summary.isEmpty, isFalse);
    });

    test('reports nothing for a user with no queue', () async {
      await insert('a', SyncOperationStatus.pending);

      final summary = await outbox.watchSummary('user-b').first;

      expect(summary, OutboxSummary.empty);
      expect(summary.isEmpty, isTrue);
    });
  });

  group('OutboxDao.requeueBlocked', () {
    test(
      'returns blocked work to the queue with a fresh attempt budget',
      () async {
        await insert('a', SyncOperationStatus.blocked);
        await insert('b', SyncOperationStatus.pending);

        final requeued = await outbox.requeueBlocked(
          'user-a',
          DateTime(2026, 8, 22, 10),
        );

        expect(requeued, 1);
        final row = await (database.select(
          database.syncOperations,
        )..where((op) => op.id.equals('a'))).getSingle();
        expect(row.status, SyncOperationStatus.pending);
        expect(row.attemptCount, 0);
        expect(row.nextAttemptAt, isNull);
        expect(row.lastErrorCode, isNull);

        // A requeued operation is now something nextReady will actually pick up,
        // which is the whole point of the retry button.
        final next = await outbox.nextReady(
          userId: 'user-a',
          now: DateTime(2026, 8, 22, 10),
        );
        expect(next, isNotNull);
      },
    );

    test('leaves another user alone', () async {
      await insert('a', SyncOperationStatus.blocked);

      expect(
        await outbox.requeueBlocked('user-b', DateTime(2026, 8, 22, 10)),
        0,
      );
    });
  });

  group('SyncStatusNotifier', () {
    test('is silent until something is queued', () async {
      final notifier = SyncStatusNotifier(outbox: outbox, drain: () async {});
      addTearDown(notifier.dispose);
      notifier.watch('user-a');
      await pumpEventQueue();

      expect(notifier.status, SyncStatus.settled);
    });

    test('waiting work is reported as waiting, not as an error', () async {
      await insert('a', SyncOperationStatus.pending);
      final notifier = SyncStatusNotifier(outbox: outbox, drain: () async {});
      addTearDown(notifier.dispose);
      notifier.watch('user-a');
      await pumpEventQueue();

      expect(notifier.status.state, SyncState.waiting);
      expect(notifier.status.pending, 1);
    });

    test('a run upgrades waiting to syncing and back', () async {
      await insert('a', SyncOperationStatus.pending);
      final gate = Completer<void>();
      final notifier = SyncStatusNotifier(
        outbox: outbox,
        drain: () => gate.future,
      );
      addTearDown(notifier.dispose);
      notifier.watch('user-a');
      await pumpEventQueue();

      final run = notifier.run();
      expect(notifier.status.state, SyncState.syncing);

      gate.complete();
      await run;
      expect(notifier.status.state, SyncState.waiting);
    });

    test('nested runs do not report finished until the last one is', () async {
      await insert('a', SyncOperationStatus.pending);
      final gate = Completer<void>();
      final notifier = SyncStatusNotifier(
        outbox: outbox,
        drain: () => gate.future,
      );
      addTearDown(notifier.dispose);
      notifier.watch('user-a');
      await pumpEventQueue();

      final outer = notifier.run();
      final inner = notifier.run();
      expect(notifier.status.state, SyncState.syncing);

      gate.complete();
      await inner;
      await outer;
      expect(notifier.status.state, SyncState.waiting);
    });

    test('running with an empty queue still says nothing', () async {
      final gate = Completer<void>();
      final notifier = SyncStatusNotifier(
        outbox: outbox,
        drain: () => gate.future,
      );
      addTearDown(notifier.dispose);
      notifier.watch('user-a');
      await pumpEventQueue();

      final run = notifier.run();
      // "Syncing" with nothing to sync would fire a banner on every save.
      expect(notifier.status, SyncStatus.settled);
      gate.complete();
      await run;
    });

    test('blocked work outranks everything else', () async {
      await insert('a', SyncOperationStatus.pending);
      await insert('b', SyncOperationStatus.blocked);
      final notifier = SyncStatusNotifier(outbox: outbox, drain: () async {});
      addTearDown(notifier.dispose);
      notifier.watch('user-a');
      await pumpEventQueue();

      expect(notifier.status.state, SyncState.failed);
      expect(notifier.status.blocked, 1);
    });

    test('retry requeues then drains', () async {
      await insert('a', SyncOperationStatus.blocked);
      var drains = 0;
      final notifier = SyncStatusNotifier(
        outbox: outbox,
        drain: () async => drains++,
        clock: () => DateTime(2026, 8, 22, 10),
      );
      addTearDown(notifier.dispose);
      notifier.watch('user-a');
      await pumpEventQueue();
      expect(notifier.status.state, SyncState.failed);

      await notifier.retry();
      await pumpEventQueue();

      expect(drains, 1);
      expect(notifier.status.state, SyncState.waiting);
    });

    test('retry without a user is a no-op rather than a crash', () async {
      var drains = 0;
      final notifier = SyncStatusNotifier(
        outbox: outbox,
        drain: () async => drains++,
      );
      addTearDown(notifier.dispose);

      await notifier.retry();

      expect(drains, 0);
    });

    test('switching user drops the previous queue', () async {
      await insert('a', SyncOperationStatus.pending);
      final notifier = SyncStatusNotifier(outbox: outbox, drain: () async {});
      addTearDown(notifier.dispose);
      notifier.watch('user-a');
      await pumpEventQueue();
      expect(notifier.status.state, SyncState.waiting);

      notifier.watch('user-b');
      await pumpEventQueue();
      expect(notifier.status, SyncStatus.settled);
    });
  });
}
