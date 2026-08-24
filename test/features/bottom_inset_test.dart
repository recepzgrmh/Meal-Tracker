import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/app.dart';

/// The bottom of every tab has to clear the floating navigation bar.
///
/// `Scaffold(extendBody: true)` means the scroll views deliberately run *under*
/// the bar — that is what makes it read as glass — so the only thing that keeps
/// the last row reachable is the bottom inset each page reserves through
/// `AppSpacing.pageBottom`. That inset is computed from three separate numbers
/// (bar height, its outer margin, the device's own bottom view padding) while
/// the bar's real height comes from a `SafeArea` with a minimum. Nothing in the
/// type system ties the two together, so this walks the rendered tree instead
/// and fails if any on-screen text ends up behind the bar once a page is
/// scrolled to its end.
///
/// Checked across the shapes where the arithmetic differs: a home-indicator
/// device, a device with no bottom inset at all, a short screen, landscape, and
/// double text scale.
void main() {
  const navSurface = Key('liquid-glass-navigation-surface');
  const tabs = {'0': 'Today', '1': 'History', '3': 'Analysis', '4': 'Profile'};

  /// Every on-screen `Text` whose box crosses into the navigation bar.
  ///
  /// Adjacent pages stay alive in the `PageView`, laid out a screen-width to
  /// the side, so anything outside the viewport horizontally is somebody else's
  /// page and not evidence of anything.
  List<String> textBehindBar(WidgetTester tester, Size size) {
    final bar = tester.getRect(find.byKey(navSurface));
    final found = <String>[];
    void visit(Element element) {
      final box = element.renderObject;
      final widget = element.widget;
      if (box is RenderBox && box.hasSize && box.attached && widget is Text) {
        final label = widget.data;
        if (label != null && label.isNotEmpty && !_isNavLabel(label)) {
          final rect = box.localToGlobal(Offset.zero) & box.size;
          final onScreenHorizontally =
              rect.left < size.width - 1 && rect.right > 1;
          if (onScreenHorizontally &&
              rect.top < size.height &&
              rect.bottom > bar.top + 1) {
            found.add(
              '"$label" at ${rect.top.toStringAsFixed(0)}'
              '-${rect.bottom.toStringAsFixed(0)}, bar starts at '
              '${bar.top.toStringAsFixed(0)}',
            );
          }
        }
      }
      element.visitChildren(visit);
    }

    tester.binding.rootElement!.visitChildren(visit);
    return found;
  }

  Future<void> checkEveryTab(
    WidgetTester tester, {
    required Size size,
    required EdgeInsets viewPadding,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: viewPadding,
          viewPadding: viewPadding,
          textScaler: textScaler,
        ),
        // Frozen so the header date and the seeded meals cannot change the
        // content height from one day to the next.
        child: MealClarityApp(clock: () => DateTime(2026, 8, 22, 18, 30)),
      ),
    );
    await tester.pumpAndSettle();

    for (final MapEntry(key: destination, value: name) in tabs.entries) {
      await tester.tap(find.byKey(Key('nav-destination-$destination')));
      await tester.pumpAndSettle();

      final scrollable = find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      );
      if (scrollable.evaluate().isNotEmpty) {
        for (var drag = 0; drag < 20; drag++) {
          await tester.drag(
            scrollable.first,
            const Offset(0, -600),
            warnIfMissed: false,
          );
          await tester.pumpAndSettle();
        }
      }

      expect(
        textBehindBar(tester, size),
        isEmpty,
        reason: '$name has content stranded behind the navigation bar',
      );
    }
  }

  testWidgets('clears the bar on a home-indicator phone', (tester) async {
    await checkEveryTab(
      tester,
      size: const Size(390, 844),
      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
    );
  });

  testWidgets('clears the bar with no bottom inset at all', (tester) async {
    // The bar falls back to its own 8 px minimum here, which is the case where
    // the reserved inset and the real bar height are furthest apart.
    await checkEveryTab(
      tester,
      size: const Size(390, 844),
      viewPadding: EdgeInsets.zero,
    );
  });

  testWidgets('clears the bar with a tall three-button inset', (tester) async {
    await checkEveryTab(
      tester,
      size: const Size(390, 844),
      viewPadding: const EdgeInsets.only(bottom: 48),
    );
  });

  testWidgets('clears the bar on a short screen', (tester) async {
    await checkEveryTab(
      tester,
      size: const Size(320, 640),
      viewPadding: const EdgeInsets.only(bottom: 24),
    );
  });

  testWidgets('clears the bar in landscape', (tester) async {
    await checkEveryTab(
      tester,
      size: const Size(844, 390),
      viewPadding: const EdgeInsets.only(bottom: 21),
    );
  });

  testWidgets('clears the bar at double text scale', (tester) async {
    await checkEveryTab(
      tester,
      size: const Size(390, 844),
      viewPadding: const EdgeInsets.only(bottom: 34),
      textScaler: const TextScaler.linear(2),
    );
  });

  testWidgets('the undo action is never left under the bar', (tester) async {
    // The snackbar is the one thing here that is not inside a scroll view, and
    // `extendBody: true` lets a fixed one slide beneath the bar entirely.
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          padding: EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: EdgeInsets.only(top: 59, bottom: 34),
        ),
        child: MealClarityApp(clock: () => DateTime(2026, 8, 22, 18, 30)),
      ),
    );
    await tester.pumpAndSettle();

    // Scrolled into the clear first. On first paint the last rows sit under the
    // bar by design — `extendBody: true` is what makes content pass beneath the
    // glass — and a tap aimed there lands on the bar, not the row. That the
    // rows become reachable once scrolled is what the tests above establish.
    await tester.scrollUntilVisible(
      find.byKey(const Key('meal-lunch')),
      200,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('meal-lunch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('meal-action-delete')));
    await tester.pumpAndSettle();

    final bar = tester.getRect(find.byKey(navSurface));
    final undo = tester.getRect(find.text('Geri al'));
    expect(undo.bottom, lessThanOrEqualTo(bar.top));
    expect(
      tester.getRect(find.byType(SnackBar)).bottom,
      lessThanOrEqualTo(bar.top),
    );
  });
}

bool _isNavLabel(String value) =>
    const {'Günlük', 'Geçmiş', 'Ekle', 'Analiz', 'Profil'}.contains(value);
