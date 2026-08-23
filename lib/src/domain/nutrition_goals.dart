import '../onboarding/domain/nutrition_plan.dart';

/// The daily targets the Today and Profile screens render against.
///
/// These used to be literals scattered across the UI (`2100`, `160`, `240`,
/// `70`), and were later derived from a single calorie number with a fixed
/// 30/45/25 macro split. Both are gone: goals now come from [NutritionPlan],
/// which the setup flow computes from the user's own body profile.
///
/// [NutritionGoals.forCalories] keeps the old fixed split for the cases that
/// only have a calorie number to work from.
class NutritionGoals {
  const NutritionGoals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.source = PlanSource.computed,
    this.bmr,
    this.tdee,
  });

  /// Used when only a calorie number is known. The 30% protein / 45% carb /
  /// 25% fat split is a disclosed heuristic, not a recommendation.
  factory NutritionGoals.forCalories(
    num calories, {
    PlanSource source = PlanSource.computed,
  }) {
    final value = calories.toDouble();
    return NutritionGoals(
      calories: value,
      protein: value * proteinEnergyShare / 4,
      carbs: value * carbEnergyShare / 4,
      fat: value * fatEnergyShare / 9,
      source: source,
    );
  }

  /// The real path: targets the calorie engine produced for this user.
  factory NutritionGoals.fromPlan(NutritionPlan? plan) {
    if (plan == null) return fallback;
    return NutritionGoals(
      calories: plan.calories,
      protein: plan.proteinG,
      carbs: plan.carbsG,
      fat: plan.fatG,
      source: plan.source,
      bmr: plan.bmr,
      tdee: plan.tdee,
    );
  }

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  /// Where the calorie target came from. Checking this beats comparing the
  /// number against [fallbackCalories], which mislabels a computed 2100 kcal.
  final PlanSource source;

  /// Shown on the profile screen so the target can be explained, not just
  /// asserted. Null when the goals did not come from a computed plan.
  final double? bmr;
  final double? tdee;

  static const fallbackCalories = 2100.0;
  static const proteinEnergyShare = 0.30;
  static const carbEnergyShare = 0.45;
  static const fatEnergyShare = 0.25;

  /// True when the target is the app's own placeholder rather than the user's.
  bool get isDefault => source == PlanSource.appDefault;

  /// True while the number is the app's estimate rather than one the user set.
  bool get isEstimated => source != PlanSource.manual;

  /// [forCalories] applied to [fallbackCalories], precomputed so it can be used
  /// as a `const` default for widget parameters.
  static const fallback = NutritionGoals(
    calories: fallbackCalories,
    protein: fallbackCalories * proteinEnergyShare / 4,
    carbs: fallbackCalories * carbEnergyShare / 4,
    fat: fallbackCalories * fatEnergyShare / 9,
    source: PlanSource.appDefault,
  );
}
