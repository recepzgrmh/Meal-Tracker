import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_surfaces.dart';

/// The one shape an empty screen takes in this app.
///
/// Today, History and Analysis each used to hand-roll their own: different
/// paddings, different type, and a `TextButton` as the only way forward. A text
/// button is the app's *tertiary* affordance, so the single most useful action
/// on an otherwise blank screen was also its quietest control. The primary
/// action here is a [FilledButton], matching every other "this is the thing to
/// do" moment in the product.
///
/// The icon is deliberately the only ornament, and it reuses the soft-lime disc
/// already used by the capture actions rather than introducing illustration the
/// app has nowhere else.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'An empty state action needs both a label and a callback.',
       );

  final IconData icon;

  /// What is true right now — "no meals yet", not "oops".
  final String title;

  /// Why the screen is blank and what filling it will do.
  final String body;

  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    final action = onAction;

    return StandardCardSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.limeSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26, color: AppColors.brandStrong),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (label != null && action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton(key: actionKey, onPressed: action, child: Text(label)),
          ],
        ],
      ),
    );
  }
}
