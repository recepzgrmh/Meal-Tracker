import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../../l10n/l10n.dart';

class LiquidGlassBottomBar extends StatefulWidget {
  const LiquidGlassBottomBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  State<LiquidGlassBottomBar> createState() => _LiquidGlassBottomBarState();
}

class _LiquidGlassBottomBarState extends State<LiquidGlassBottomBar> {
  static const int _destinationCount = 5;

  Alignment? _dragAlignment;
  int? _dragTargetIndex;

  List<_GlassDestination> _destinations(BuildContext context) => [
    _GlassDestination(
      label: context.ota('navToday', tr: 'Günlük', en: 'Today'),
      icon: Icons.calendar_today_outlined,
    ),
    _GlassDestination(
      label: context.ota('navHistory', tr: 'Geçmiş', en: 'History'),
      icon: Icons.history_rounded,
    ),
    // Five destinations across a 360 px screen leave ~66 px each, so the full
    // phrase truncates. The short form is shown; the full one is announced.
    _GlassDestination(
      label: context.ota('navAddMealShort', tr: 'Ekle', en: 'Add'),
      semanticLabel: context.ota('navAddMeal', tr: 'Öğün Ekle', en: 'Add Meal'),
      icon: Icons.add_rounded,
      emphasized: true,
    ),
    _GlassDestination(
      label: context.ota('navAnalysis', tr: 'Analiz', en: 'Analysis'),
      icon: Icons.bar_chart_outlined,
    ),
    _GlassDestination(
      label: context.ota('navProfile', tr: 'Profil', en: 'Profile'),
      icon: Icons.person_outline_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations(context);
    final highContrast = MediaQuery.highContrastOf(context);
    final fillOpacity = highContrast ? 1.0 : 0.96;

    return SafeArea(
      top: false,
      // Geometry lives in AppNavigationBar so scroll views can reserve exactly
      // this much clearance via AppSpacing.pageBottom instead of guessing.
      minimum: const EdgeInsets.fromLTRB(
        AppNavigationBar.horizontalMargin,
        0,
        AppNavigationBar.horizontalMargin,
        AppNavigationBar.outerMargin,
      ),
      child: DecoratedBox(
        key: const Key('liquid-glass-navigation-surface'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.feature),
          boxShadow: AppShadows.floating,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.feature),
          child: Container(
            height: AppNavigationBar.height,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: fillOpacity),
              borderRadius: BorderRadius.circular(AppRadius.feature),
              border: Border.all(
                color: AppColors.ink.withValues(
                  alpha: highContrast ? 0.36 : 0.16,
                ),
                width: 1,
              ),
            ),
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.25,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedAlign(
                        key: const Key('bottom-nav-selection-indicator'),
                        alignment:
                            _dragAlignment ??
                            _indicatorAlignment(widget.selectedIndex),
                        duration:
                            _dragAlignment != null ||
                                MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : AppMotion.fast,
                        curve: Curves.easeOutCubic,
                        child: FractionallySizedBox(
                          widthFactor: 1 / _destinationCount,
                          heightFactor: 1,
                          child: DecoratedBox(
                            key: const Key('bottom-nav-selection-fill'),
                            decoration: BoxDecoration(
                              color: AppColors.brandSoft,
                              borderRadius: BorderRadius.circular(
                                AppRadius.feature,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) => GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onLongPressStart: (details) => _startDrag(
                          details.localPosition.dx,
                          constraints.maxWidth,
                        ),
                        onLongPressMoveUpdate: (details) => _updateDrag(
                          details.localPosition.dx,
                          constraints.maxWidth,
                        ),
                        onLongPressEnd: (_) => _finishDrag(),
                        onLongPressCancel: _cancelDrag,
                        child: Row(
                          children: List.generate(destinations.length, (index) {
                            final destination = destinations[index];
                            return Expanded(
                              child: _GlassDestinationButton(
                                key: Key('nav-destination-$index'),
                                destination: destination,
                                selected: widget.selectedIndex == index,
                                onTap: () =>
                                    widget.onDestinationSelected(index),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Alignment _indicatorAlignment(int index) {
    return switch (index) {
      1 => const Alignment(-0.5, 0),
      2 => Alignment.center,
      3 => const Alignment(0.5, 0),
      4 => Alignment.centerRight,
      _ => Alignment.centerLeft,
    };
  }

  void _startDrag(double x, double width) {
    final pressedIndex = _tabIndexForX(x, width);
    if (pressedIndex != widget.selectedIndex) return;

    setState(() {
      _dragTargetIndex = pressedIndex;
      _dragAlignment = _alignmentForX(x, width);
    });
    unawaited(HapticFeedback.selectionClick());
  }

  void _updateDrag(double x, double width) {
    if (_dragAlignment == null) return;
    final targetIndex = _tabIndexForX(x, width);
    if (targetIndex != _dragTargetIndex) {
      _dragTargetIndex = targetIndex;
      unawaited(HapticFeedback.selectionClick());
    }
    setState(() => _dragAlignment = _alignmentForX(x, width));
  }

  void _finishDrag() {
    final targetIndex = _dragTargetIndex;
    if (_dragAlignment == null || targetIndex == null) return;

    setState(() {
      _dragAlignment = null;
      _dragTargetIndex = null;
    });
    widget.onDestinationSelected(targetIndex);
  }

  void _cancelDrag() {
    if (_dragAlignment == null) return;
    setState(() {
      _dragAlignment = null;
      _dragTargetIndex = null;
    });
  }

  int _tabIndexForX(double x, double width) {
    if (width <= 0) return widget.selectedIndex;
    return (x.clamp(0.0, width) / width * _destinationCount).floor().clamp(
      0,
      _destinationCount - 1,
    );
  }

  Alignment _alignmentForX(double x, double width) {
    if (width <= 0) return _indicatorAlignment(widget.selectedIndex);
    final indicatorWidth = width / _destinationCount;
    final center = x.clamp(indicatorWidth / 2, width - indicatorWidth / 2);
    final travel = width - indicatorWidth;
    return Alignment(((center - indicatorWidth / 2) / travel) * 2 - 1, 0);
  }
}

class _GlassDestinationButton extends StatelessWidget {
  const _GlassDestinationButton({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _GlassDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final highlighted = destination.emphasized;

    return Semantics(
      selected: selected,
      button: true,
      label: destination.semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          // The wrapping Semantics already carries the label; without this the
          // icon and caption merge into it and every destination is announced
          // twice.
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: highlighted ? 38 : 31,
                  height: 31,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: highlighted ? AppColors.lime : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    child: TweenAnimationBuilder<Color?>(
                      duration: reduceMotion ? Duration.zero : AppMotion.fast,
                      curve: Curves.easeOutCubic,
                      tween: ColorTween(
                        end: selected || highlighted
                            ? AppColors.brand
                            : AppColors.muted,
                      ),
                      builder: (context, color, _) => Icon(
                        destination.icon,
                        size: destination.emphasized ? 22 : 20,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.micro),
                AnimatedDefaultTextStyle(
                  duration: reduceMotion ? Duration.zero : AppMotion.fast,
                  style: TextStyle(
                    color: selected ? AppColors.brandStrong : AppColors.muted,
                    // 11 px sat below the legible floor for a persistent control.
                    fontSize: 12,
                    height: 1,
                    fontWeight: selected || highlighted
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassDestination {
  const _GlassDestination({
    required this.label,
    required this.icon,
    this.emphasized = false,
    String? semanticLabel,
  }) : semanticLabel = semanticLabel ?? label;

  final String label;

  /// What assistive tech announces, when the visible label had to be shortened
  /// to fit the bar.
  final String semanticLabel;
  final IconData icon;
  final bool emphasized;
}
