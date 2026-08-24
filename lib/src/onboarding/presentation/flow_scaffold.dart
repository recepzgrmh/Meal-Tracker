import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../theme/app_theme.dart';

/// Chrome shared by the pre-sign-in tour and the post-sign-in setup flow, so
/// the two read as one journey rather than two screens that happen to follow
/// each other.

/// Title row with a back affordance and a progress indicator whose dot count
/// follows the flow it is placed in.
class FlowHeader extends StatelessWidget {
  const FlowHeader({
    required this.step,
    required this.stepCount,
    required this.onBack,
    this.title = 'Meal Clarity',
    super.key,
  });

  final int step;
  final int stepCount;
  final VoidCallback? onBack;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xxs,
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppTouchTarget.minimum,
            height: AppTouchTarget.minimum,
            child: onBack == null
                ? null
                : IconButton(
                    key: const Key('onboarding-back'),
                    tooltip: context.ota('commonBack', tr: 'Geri', en: 'Back'),
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          // Sized to its dots rather than to a fixed box: seven steps do not
          // fit in the 48 px the back button needs, and a flow may have more.
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppTouchTarget.minimum,
              minHeight: AppTouchTarget.minimum,
            ),
            child: Semantics(
              label: context.ota(
                'onboardingProgressSemantics',
                tr: '{count} adımdan {step}. adım',
                en: 'Step {step} of {count}',
                replacements: {'step': step + 1, 'count': stepCount},
              ),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: List.generate(
                    stepCount,
                    (index) => AnimatedContainer(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : AppMotion.fast,
                      width: index == step ? 14 : 5,
                      height: 5,
                      margin: const EdgeInsets.only(left: 3),
                      decoration: BoxDecoration(
                        color: index == step ? AppColors.brand : AppColors.line,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A scrollable body with a footer pinned below it, both capped to a readable
/// measure so the flow holds up on a tablet.
class FlowStepLayout extends StatelessWidget {
  const FlowStepLayout({
    required this.child,
    required this.footer,
    this.centerContent = false,
    super.key,
  });

  final Widget child;
  final Widget footer;
  final bool centerContent;

  static const maxContentWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: centerContent ? constraints.maxHeight : 0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: maxContentWidth,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
              child: footer,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable choice with a title and a line of plain-language detail. Used
/// wherever the setup flow asks the user to pick one of several options.
class FlowOptionCard extends StatelessWidget {
  const FlowOptionCard({
    required this.title,
    required this.detail,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String title;
  final String detail;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Material(
          color: selected ? AppColors.selectedSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.compactCard),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppRadius.compactCard),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: AppTouchTarget.minimum,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.compactCard),
                border: Border.all(
                  color: selected ? AppColors.brand : AppColors.line,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium),
                        if (detail.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.micro),
                          Text(detail, style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  if (selected)
                    const Padding(
                      padding: EdgeInsets.only(left: AppSpacing.xs),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.brand,
                        size: 22,
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
}
