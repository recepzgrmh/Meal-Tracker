import 'dart:async';

import 'package:flutter/services.dart';

/// Every haptic the app is allowed to play, named after the *meaning* rather
/// than the waveform.
///
/// Routing them through one place is the point: Android's own guidance is that
/// "less is more" and that feedback must stay consistent with the system and
/// with itself, so a call site picks an event it is reporting instead of
/// picking an intensity. That keeps the vocabulary small — four events — and
/// makes it obvious in review when a new one is being invented.
///
/// The deliberate omissions matter as much as the entries: ordinary buttons,
/// navigation, scrolling and opening sheets play nothing. A phone that buzzes
/// on every tap trains the user to switch haptics off, which costs the four
/// signals below their meaning.
abstract final class AppHaptics {
  /// A user-initiated task the user waited for has finished: the meal is
  /// stored. Maps to the platform's "success" notification, which is what both
  /// platforms reserve for exactly this.
  static void success() => unawaited(HapticFeedback.successNotification());

  /// Something finished on its own while the user waited and their attention
  /// has to come back to the screen — the analysis result landing. Lighter than
  /// [success] on purpose, because the two fire seconds apart in the same flow
  /// and must not feel like the same event.
  static void arrived() => unawaited(HapticFeedback.lightImpact());

  /// A committed, consequential change: a meal removed by swipe. Heavier than a
  /// selection so it is felt even when the finger is still moving, and paired
  /// with an undo affordance so the weight reads as "noted", not "alarm".
  static void committed() => unawaited(HapticFeedback.mediumImpact());

  /// Moving through discrete values — portion options, the navigation bar's
  /// scrub gesture. The lightest signal there is.
  static void selection() => unawaited(HapticFeedback.selectionClick());
}
