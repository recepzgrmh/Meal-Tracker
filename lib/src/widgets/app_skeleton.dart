import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Drives every [SkeletonBox] beneath it from a single ticker.
///
/// One controller per group rather than one per box: a first-load list is a
/// dozen placeholders, and a dozen independent tickers would both cost more and
/// pulse out of phase, which reads as noise instead of as one waiting surface.
///
/// The group is also the only thing assistive technology hears. Boxes are
/// individually silent and the group announces the wait once, so a screen
/// reader says "loading" rather than reading a dozen anonymous rectangles as if
/// they were content.
class SkeletonGroup extends StatefulWidget {
  const SkeletonGroup({required this.label, required this.child, super.key});

  /// What a screen reader announces for the whole loading region.
  final String label;
  final Widget child;

  @override
  State<SkeletonGroup> createState() => _SkeletonGroupState();

  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkeletonScope>()?.animation;
}

class _SkeletonGroupState extends State<SkeletonGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.skeleton,
  );

  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A pulse is motion for its own sake to anyone who asked the system for
    // less of it, and the placeholder still reads as "not content yet" when it
    // holds still. The ticker is stopped rather than merely ignored: a repeat()
    // left running would keep the app rendering a frame every 16 ms, on screen
    // and off, for a setting whose entire point is to stop exactly that.
    final reduced = AppMotion.reduced(context);
    if (reduced == _reduced && _controller.isAnimating != reduced) return;
    _reduced = reduced;
    if (reduced) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = _reduced ? null : _curve;

    return Semantics(
      container: true,
      liveRegion: true,
      // The placeholders themselves are plain coloured boxes and emit no
      // semantics of their own, so there is nothing to exclude — and excluding
      // the subtree wholesale would silence anything real that sits among them.
      // Today keeps its capture action live while the day loads; wrapping the
      // region in `ExcludeSemantics` hid that button from screen readers for as
      // long as the load lasted.
      explicitChildNodes: true,
      label: widget.label,
      child: _SkeletonScope(animation: animation, child: widget.child),
    );
  }
}

class _SkeletonScope extends InheritedWidget {
  const _SkeletonScope({required this.animation, required super.child});

  final Animation<double>? animation;

  @override
  bool updateShouldNotify(_SkeletonScope oldWidget) =>
      animation != oldWidget.animation;
}

/// One placeholder rectangle, sized by its caller to match the real content it
/// stands in for. Sizing is deliberately not this widget's business: a
/// placeholder that guesses is a placeholder that shifts the layout when the
/// content lands.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    required this.width,
    required this.height,
    this.radius = AppRadius.small,
    super.key,
  });

  const SkeletonBox.square({
    required double dimension,
    double radius = AppRadius.small,
    Key? key,
  }) : this(width: dimension, height: dimension, radius: radius, key: key);

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final animation = SkeletonGroup.maybeOf(context);
    final shape = BorderRadius.circular(radius);

    if (animation == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.skeleton,
          borderRadius: shape,
        ),
      );
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Color.lerp(
            AppColors.skeleton,
            AppColors.skeletonHighlight,
            animation.value,
          ),
          borderRadius: shape,
        ),
      ),
    );
  }
}
