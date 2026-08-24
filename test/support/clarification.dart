import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dismisses the clarification sheets the meal flow opens on its own once
/// analysis finishes.
///
/// Portion is the dominant error source in dietary self-report, so the flow now
/// asks its open questions instead of waiting for the user to tap a flagged
/// row. Tests that are about the review screen itself have to walk past those
/// sheets first; tests that are about the sheets should not use this.
Future<void> dismissClarificationSheets(WidgetTester tester) async {
  // Each barrier tap closes one sheet and may reveal the next question, so this
  // drains the queue rather than closing a single sheet. The bound is a
  // safeguard against a sheet that re-opens itself.
  for (var guard = 0; guard < 8; guard += 1) {
    final barrier = find.byType(ModalBarrier);
    if (barrier.evaluate().length < 2) return;
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
  }
}
