import 'body_profile.dart';
import 'calorie_calculator.dart';
import 'nutrition_plan.dart';

enum TrackingIntention { understand, protein, calories }

/// Everything the setup flow has collected so far. Answers live here — not on
/// the server — until the user finishes, so a partially answered flow survives
/// the app being killed and nothing is written for someone who abandons it.
class OnboardingDraft {
  const OnboardingDraft({
    this.step = 0,
    this.intention,
    this.dailyCalorieTarget,
    this.body = const BodyProfile(),
  });

  final int step;
  final TrackingIntention? intention;

  /// Set only when the user overrode the computed target with their own.
  final int? dailyCalorieTarget;

  final BodyProfile body;

  /// Derived rather than stored: the answers are the source of truth, so a
  /// plan can never drift out of sync with the profile that produced it.
  /// Null until enough of [body] is answered.
  NutritionPlan? get plan {
    if (dailyCalorieTarget case final manual?) {
      return CalorieCalculator.withManualCalories(body, manual);
    }
    return CalorieCalculator.estimate(body);
  }

  OnboardingDraft copyWith({
    int? step,
    TrackingIntention? intention,
    int? dailyCalorieTarget,
    BodyProfile? body,
    bool clearCalorieTarget = false,
  }) {
    return OnboardingDraft(
      step: step ?? this.step,
      intention: intention ?? this.intention,
      dailyCalorieTarget: clearCalorieTarget
          ? null
          : dailyCalorieTarget ?? this.dailyCalorieTarget,
      body: body ?? this.body,
    );
  }
}
