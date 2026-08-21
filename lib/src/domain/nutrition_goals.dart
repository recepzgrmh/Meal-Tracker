import '../onboarding/domain/onboarding_draft.dart';

/// The daily targets the Today and Profile screens render against.
///
/// These used to be literals scattered across the UI (`2100`, `160`, `240`,
/// `70`), which meant the calorie target the user typed during onboarding was
/// collected and then ignored. Goals now derive from the onboarding draft.
///
/// The macro split is a fixed, disclosed heuristic — 30% protein / 45% carbs /
/// 25% fat by energy — not a medical recommendation. It reproduces roughly the
/// old hard-coded numbers at the default 2100 kcal while scaling with whatever
/// target the user actually chose.
class NutritionGoals {
  const NutritionGoals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  /// Used when the user never entered a target.
  factory NutritionGoals.forCalories(num calories) {
    final value = calories.toDouble();
    return NutritionGoals(
      calories: value,
      protein: value * proteinEnergyShare / 4,
      carbs: value * carbEnergyShare / 4,
      fat: value * fatEnergyShare / 9,
    );
  }

  factory NutritionGoals.fromDraft(OnboardingDraft draft) =>
      NutritionGoals.forCalories(draft.dailyCalorieTarget ?? fallbackCalories);

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  static const fallbackCalories = 2100.0;
  static const proteinEnergyShare = 0.30;
  static const carbEnergyShare = 0.45;
  static const fatEnergyShare = 0.25;

  /// True when the target came from the app's default rather than the user.
  bool get isDefault => calories == fallbackCalories;

  /// [forCalories] applied to [fallbackCalories], precomputed so it can be used
  /// as a `const` default for widget parameters.
  static const fallback = NutritionGoals(
    calories: fallbackCalories,
    protein: fallbackCalories * proteinEnergyShare / 4,
    carbs: fallbackCalories * carbEnergyShare / 4,
    fat: fallbackCalories * fatEnergyShare / 9,
  );
}
