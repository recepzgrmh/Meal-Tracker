import 'dart:math' as math;

import '../local/outbox_dao.dart';
import 'mutation_gateway.dart';

typedef SyncClock = DateTime Function();
typedef JitterSource = double Function();

enum SyncRunOutcome { idle, succeeded, retryScheduled, blocked }

class SyncRunResult {
  const SyncRunResult(this.outcome, {this.operationId, this.nextAttemptAt});

  final SyncRunOutcome outcome;
  final String? operationId;
  final DateTime? nextAttemptAt;
}

class OutboxWorker {
  OutboxWorker({
    required OutboxDao outbox,
    required MutationGateway gateway,
    SyncClock? clock,
    JitterSource? jitter,
    this.maxAttempts = 6,
    this.baseDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(minutes: 5),
  }) : _outbox = outbox,
       _gateway = gateway,
       _clock = clock ?? DateTime.now,
       _jitter = jitter ?? math.Random.secure().nextDouble;

  final OutboxDao _outbox;
  final MutationGateway _gateway;
  final SyncClock _clock;
  final JitterSource _jitter;
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;

  Future<void> recoverInterrupted(String userId) async {
    await _outbox.recoverInterrupted(userId, _clock());
  }

  Future<SyncRunResult> runOnce(String userId) async {
    final now = _clock();
    final operation = await _outbox.nextReady(userId: userId, now: now);
    if (operation == null) {
      return const SyncRunResult(SyncRunOutcome.idle);
    }

    await _outbox.markInFlight(operation.id, now);
    try {
      await _gateway.execute(operation);
      await _outbox.markSucceeded(operation.id, _clock());
      return SyncRunResult(SyncRunOutcome.succeeded, operationId: operation.id);
    } on SyncFailure catch (failure) {
      if (failure.isRetryable && operation.attemptCount + 1 < maxAttempts) {
        final nextAttemptAt = _clock().add(_backoff(operation.attemptCount));
        await _outbox.markRetry(
          operation: operation,
          nextAttemptAt: nextAttemptAt,
          errorCode: failure.code,
          now: _clock(),
        );
        return SyncRunResult(
          SyncRunOutcome.retryScheduled,
          operationId: operation.id,
          nextAttemptAt: nextAttemptAt,
        );
      }

      final code = failure.isRetryable
          ? 'retry_exhausted:${failure.code}'
          : failure.code;
      await _outbox.markBlocked(
        operationId: operation.id,
        errorCode: code,
        now: _clock(),
      );
      return SyncRunResult(SyncRunOutcome.blocked, operationId: operation.id);
    } catch (_) {
      await _outbox.markBlocked(
        operationId: operation.id,
        errorCode: 'unclassified_client_error',
        now: _clock(),
      );
      return SyncRunResult(SyncRunOutcome.blocked, operationId: operation.id);
    }
  }

  Duration _backoff(int completedAttempts) {
    final exponent = math.min(completedAttempts, 20);
    final capMs = math.min(
      baseDelay.inMilliseconds * math.pow(2, exponent).toInt(),
      maxDelay.inMilliseconds,
    );
    final jitteredMs = (capMs * _jitter().clamp(0, 1)).round();
    return Duration(milliseconds: jitteredMs);
  }
}
