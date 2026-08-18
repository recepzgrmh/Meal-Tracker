import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HeroCardSurface extends StatelessWidget {
  const HeroCardSurface({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.color = AppColors.surface,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) => _AppSurface(
    radius: AppRadius.heroCard,
    padding: padding,
    color: color,
    child: child,
  );
}

class StandardCardSurface extends StatelessWidget {
  const StandardCardSurface({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = AppColors.surface,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) => _AppSurface(
    radius: AppRadius.standardCard,
    padding: padding,
    color: color,
    child: child,
  );
}

class CompactCardSurface extends StatelessWidget {
  const CompactCardSurface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.surface,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) => _AppSurface(
    radius: AppRadius.compactCard,
    padding: padding,
    color: color,
    child: child,
  );
}

class _AppSurface extends StatelessWidget {
  const _AppSurface({
    required this.radius,
    required this.padding,
    required this.color,
    required this.child,
  });

  final double radius;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.highContrastOf(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: highContrast ? AppColors.muted : AppColors.line,
        ),
        boxShadow: highContrast ? null : AppShadows.card,
      ),
      child: child,
    );
  }
}
