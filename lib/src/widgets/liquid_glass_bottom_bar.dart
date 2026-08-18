import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../l10n/l10n.dart';

class LiquidGlassBottomBar extends StatelessWidget {
  const LiquidGlassBottomBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  List<_GlassDestination> _destinations(BuildContext context) => [
    _GlassDestination(
      label: context.ota('navToday', tr: 'Günlük', en: 'Today'),
      icon: Icons.calendar_today_outlined,
    ),
    _GlassDestination(
      label: context.ota('navHistory', tr: 'Geçmiş', en: 'History'),
      icon: Icons.history_rounded,
    ),
    _GlassDestination(
      label: context.ota('navAddMeal', tr: 'Öğün Ekle', en: 'Add Meal'),
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
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: DecoratedBox(
        key: const Key('liquid-glass-navigation-surface'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.feature),
          boxShadow: AppShadows.floating,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.feature),
          child: Container(
            height: 62,
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
                        alignment: _indicatorAlignment(selectedIndex),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : AppMotion.fast,
                        curve: Curves.easeOutCubic,
                        child: FractionallySizedBox(
                          widthFactor: 1 / 5,
                          heightFactor: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.brandSoft,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.medium,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(destinations.length, (index) {
                      final destination = destinations[index];
                      return Expanded(
                        child: _GlassDestinationButton(
                          key: Key('nav-destination-$index'),
                          destination: destination,
                          selected: selectedIndex == index,
                          onTap: () => onDestinationSelected(index),
                        ),
                      );
                    }),
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
      label: destination.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
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
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                style: TextStyle(
                  color: selected ? AppColors.brandStrong : AppColors.muted,
                  fontSize: 11,
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
    );
  }
}

class _GlassDestination {
  const _GlassDestination({
    required this.label,
    required this.icon,
    this.emphasized = false,
  });

  final String label;
  final IconData icon;
  final bool emphasized;
}
