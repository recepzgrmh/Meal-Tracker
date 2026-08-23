/// The output of the calorie engine: a daily target plus the working that
/// produced it, so the summary step can show the user *why* they got a number
/// instead of asking them to trust it.
library;

/// Where the calorie target came from. This replaces comparing the value
/// against the app default, which mislabels a computed 2100 kcal as a default.
enum PlanSource {
  /// Nothing was answered; the app-wide fallback is in use.
  appDefault('default'),

  /// Derived from the user's body profile.
  computed('computed'),

  /// The user overrode the computed target with their own number.
  manual('manual');

  const PlanSource(this.wire);

  final String wire;

  static PlanSource? fromWire(String? value) =>
      values.where((item) => item.wire == value).firstOrNull;
}

/// Something the engine had to correct or wants disclosed. Carries no copy:
/// the wording belongs to the UI layer, which localises it once.
enum PlanWarning {
  /// The requested deficit would have dropped intake below the safe floor.
  calorieFloorApplied,

  /// The chosen pace exceeded the safe weekly rate and was reduced.
  paceReduced,

  /// A deficit was requested at a BMI already under 18.5.
  underweightDeficit,

  /// The user is under 18; the equation is not validated for them.
  minorAge,

  /// The protein target hit the 35%-of-energy AMDR ceiling and was scaled back.
  proteinCappedByAmdr,
}

class NutritionPlan {
  const NutritionPlan({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.source,
    this.bmr,
    this.tdee,
    this.weeklyRateKg = 0,
    this.estimatedWeeks,
    this.warnings = const {},
  });

  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  /// Basal metabolic rate, null when the plan was not computed from a profile.
  final double? bmr;

  /// Total daily energy expenditure (maintenance).
  final double? tdee;

  /// Signed: negative while losing, positive while gaining, zero maintaining.
  final double weeklyRateKg;

  /// Whole weeks to reach the target weight at [weeklyRateKg]. Null when there
  /// is no target weight or the user is maintaining.
  final int? estimatedWeeks;

  final PlanSource source;
  final Set<PlanWarning> warnings;

  /// True while the number is the app's own guess rather than the user's.
  bool get isEstimated => source != PlanSource.manual;
}
