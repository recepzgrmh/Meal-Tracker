import 'dart:async';

import 'package:flutter/foundation.dart';

import '../local/outbox_dao.dart';

/// What the app can honestly tell the user about work that has not reached the
/// server yet.
enum SyncState {
  /// Nothing outstanding. The screen says nothing at all.
  settled,

  /// Outstanding work, currently being sent.
  syncing,

  /// Outstanding work, not being sent right now — the ordinary offline case,
  /// and the gap between backoff retries.
  waiting,

  /// The queue gave up. This is the only state that asks the user for
  /// anything.
  failed,
}

@immutable
class SyncStatus {
  const SyncStatus({
    required this.state,
    required this.pending,
    required this.blocked,
  });

  static const settled = SyncStatus(
    state: SyncState.settled,
    pending: 0,
    blocked: 0,
  );

  final SyncState state;
  final int pending;
  final int blocked;

  @override
  bool operator ==(Object other) =>
      other is SyncStatus &&
      other.state == state &&
      other.pending == pending &&
      other.blocked == blocked;

  @override
  int get hashCode => Object.hash(state, pending, blocked);
}

/// Turns the outbox tables into the one sentence the UI is allowed to say.
///
/// Everything the app writes is already optimistic: the meal is in Drift and on
/// screen before the network is involved, and the outbox retries with backoff
/// on its own. What was missing was any way for the user to know that. Without
/// it, a meal logged in a lift looks exactly like a meal logged at a desk, and
/// the only way to find out whether it survived was to log it again — which is
/// how duplicate meals get made.
///
/// The counts come from the database rather than from this class's own
/// bookkeeping, so a restart, a second window, or an operation drained by
/// something else all report the same truth.
class SyncStatusNotifier extends ChangeNotifier {
  SyncStatusNotifier({
    required OutboxDao outbox,
    required Future<void> Function() drain,
    DateTime Function()? clock,
  }) : _outbox = outbox,
       _drain = drain,
       _clock = clock ?? DateTime.now;

  final OutboxDao _outbox;
  final Future<void> Function() _drain;
  final DateTime Function() _clock;

  StreamSubscription<OutboxSummary>? _subscription;
  OutboxSummary _summary = OutboxSummary.empty;
  String? _userId;
  int _runsInFlight = 0;

  SyncStatus get status {
    if (_summary.blocked > 0) {
      return SyncStatus(
        state: SyncState.failed,
        pending: _summary.pending,
        blocked: _summary.blocked,
      );
    }
    if (_summary.pending == 0) return SyncStatus.settled;
    return SyncStatus(
      // "Syncing" with nothing queued is noise, so the running flag only
      // upgrades a queue that actually has something in it.
      state: _runsInFlight > 0 ? SyncState.syncing : SyncState.waiting,
      pending: _summary.pending,
      blocked: 0,
    );
  }

  /// Starts reporting for [userId]. Safe to call repeatedly with the same id.
  void watch(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _subscription?.cancel();
    _subscription = null;
    _summary = OutboxSummary.empty;
    if (userId != null) {
      _subscription = _outbox.watchSummary(userId).listen((summary) {
        if (summary == _summary) return;
        _summary = summary;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  /// Drains the queue, reporting that it is happening.
  ///
  /// Nested calls are counted rather than rejected: a save triggers a drain
  /// while an app-resume drain may still be running, and the state must not
  /// fall back to "waiting" because the inner one finished first.
  Future<void> run() async {
    _runsInFlight++;
    if (_runsInFlight == 1) notifyListeners();
    try {
      await _drain();
    } finally {
      _runsInFlight--;
      if (_runsInFlight == 0) notifyListeners();
    }
  }

  /// The user asked for another go at operations the queue had given up on.
  Future<void> retry() async {
    final userId = _userId;
    if (userId == null) return;
    await _outbox.requeueBlocked(userId, _clock());
    await run();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
