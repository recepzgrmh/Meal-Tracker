import 'dart:math' as math;

import 'body_profile.dart';
import 'nutrition_plan.dart';

/// Turns the setup answers into a daily calorie and macronutrient target.
///
/// The chain is deliberately conventional so the result can be explained to the
/// user and checked against any published calculator:
///
///   1. BMR from Mifflin-St Jeor (1990) — the equation that lands within 10% of
///      measured resting expenditure most often (Frankenfield 2005).
///   2. TDEE = BMR x the activity factor.
///   3. An energy gap sized as a share of body weight per week, not a flat
///      number, because 0.5 kg/week is routine at 120 kg and severe at 55 kg.
///   4. A safety floor: never below 1200 kcal (women) / 1500 kcal (men) per the
///      2013 AHA/ACC/TOS obesity guideline, and never below the user's own BMR.
///   5. Protein anchored in g/kg, then the dietary pattern splits what is left
///      between carbohydrate and fat, inside the AMDR bounds.
///
/// This is an estimate with roughly a +/-10% error band before the activity
/// factor is even considered. It is not medical or nutrition advice, and every
/// screen that shows the result says so.
abstract final class CalorieCalculator {
  /// Energy in a kilogram of body mass. The classic 3500 kcal/lb figure.
  static const kcalPerKgBodyMass = 7700.0;

  /// NIH obesity guidance: a 500-1000 kcal/day deficit, not more.
  static const maxDailyDeficit = 1000.0;

  /// Lean tissue accrues slowly; a larger surplus mostly adds fat.
  static const maxDailySurplus = 500.0;

  static const minWeeklyLossKg = 0.15;
  static const maxWeeklyLossKg = 1.0;
  static const minWeeklyGainKg = 0.1;
  static const maxWeeklyGainKg = 0.5;

  /// Matches the `profiles.daily_calorie_target` check constraint.
  static const minCalories = 500.0;
  static const maxCalories = 10000.0;

  /// Acceptable Macronutrient Distribution Range: protein 10-35% of energy,
  /// fat 20-35%.
  static const proteinEnergyCeiling = 0.35;
  static const fatEnergyFloor = 0.20;

  static const minCarbGrams = 50.0;
  static const minProteinPerKg = 1.2;
  static const maxProteinPerKg = 2.2;

  /// Extra protein while in a deficit, to blunt lean-mass loss.
  static const deficitProteinBonus = 0.2;

  static const underweightBmi = 18.5;
  static const highAdiposityBmi = 30.0;

  /// The BMI used to derive a proxy goal weight when someone with a high BMI
  /// has not named a target. Protein scales with lean mass, so billing it
  /// against total body weight over-prescribes.
  static const proxyGoalBmi = 25.0;

  /// Returns null until [profile] holds every answer the chain needs.
  static NutritionPlan? estimate(BodyProfile profile, {DateTime? now}) {
    final moment = now ?? DateTime.now();
    if (!profile.isCompleteAt(moment)) return null;

    final age = profile.ageAt(moment)!;
    final weightKg = profile.weightKg!;
    final heightCm = profile.heightCm!;
    final sex = profile.sex!;
    final activity = profile.activityLevel!;
    final diet = profile.dietPattern!;
    final bmi = profile.bmi!;

    final warnings = <PlanWarning>{};
    if (age < 18) warnings.add(PlanWarning.minorAge);

    final bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + sex.mifflinConstant;
    final tdee = bmr * activity.multiplier;

    // Asking to lose weight while already underweight is the one request the
    // engine declines: it maintains instead and says so.
    var goal = profile.goal!;
    if (goal == WeightGoal.lose && bmi < underweightBmi) {
      warnings.add(PlanWarning.underweightDeficit);
      goal = WeightGoal.maintain;
    }

    final (:dailyGap, :paceReduced) = _energyGap(
      goal: goal,
      pace: profile.pace,
      weightKg: weightKg,
    );
    if (paceReduced) warnings.add(PlanWarning.paceReduced);

    final unbounded = switch (goal) {
      WeightGoal.lose => tdee - dailyGap,
      WeightGoal.gain => tdee + dailyGap,
      WeightGoal.maintain => tdee,
    };

    // Two floors apply at once: the guideline minimum for the user's sex, and
    // the user's own resting requirement. The floor is raised to a whole ten
    // first, so the rounding below cannot round back underneath it.
    final floor = (math.max(sex.calorieFloor, bmr) / 10).ceil() * 10.0;
    final bounded = math.max(unbounded, floor);
    if (bounded > unbounded) warnings.add(PlanWarning.calorieFloorApplied);

    final calories = _roundCalories(bounded);

    // Report the rate the target actually produces, not the one that was asked
    // for: a floor or a cap silently changes it otherwise.
    final effectiveGap = calories - tdee;
    final weeklyRateKg = effectiveGap * 7 / kcalPerKgBodyMass;

    final macros = _macros(
      calories: calories,
      diet: diet,
      activity: activity,
      goal: goal,
      referenceWeightKg: _referenceWeight(profile),
    );
    if (macros.proteinCapped) warnings.add(PlanWarning.proteinCappedByAmdr);

    return NutritionPlan(
      calories: calories,
      proteinG: macros.protein,
      carbsG: macros.carbs,
      fatG: macros.fat,
      bmr: bmr,
      tdee: tdee,
      weeklyRateKg: weeklyRateKg,
      estimatedWeeks: _estimatedWeeks(profile, goal, weeklyRateKg),
      source: PlanSource.computed,
      warnings: warnings,
    );
  }

  /// Rebuilds the plan around a target the user typed themselves. The body
  /// profile still drives the macro split, and BMR/TDEE stay visible so the
  /// summary can show how far the override sits from maintenance.
  static NutritionPlan withManualCalories(
    BodyProfile profile,
    int calories, {
    DateTime? now,
  }) {
    final estimated = estimate(profile, now: now);
    final bounded = _roundCalories(calories.toDouble());
    final macros = _macros(
      calories: bounded,
      diet: profile.dietPattern ?? DietPattern.balanced,
      activity: profile.activityLevel ?? ActivityLevel.moderate,
      goal: profile.goal ?? WeightGoal.maintain,
      referenceWeightKg: _referenceWeight(profile),
    );

    final tdee = estimated?.tdee;
    return NutritionPlan(
      calories: bounded,
      proteinG: macros.protein,
      carbsG: macros.carbs,
      fatG: macros.fat,
      bmr: estimated?.bmr,
      tdee: tdee,
      weeklyRateKg: tdee == null ? 0 : (bounded - tdee) * 7 / kcalPerKgBodyMass,
      source: PlanSource.manual,
      warnings: const {},
    );
  }

  /// The daily calorie gap implied by the pace, after the weekly rate is held
  /// inside the safe band and the gap itself is capped.
  static ({double dailyGap, bool paceReduced}) _energyGap({
    required WeightGoal goal,
    required GoalPace pace,
    required double weightKg,
  }) {
    if (goal == WeightGoal.maintain) {
      return (dailyGap: 0.0, paceReduced: false);
    }

    final losing = goal == WeightGoal.lose;
    final requested = weightKg * (losing ? pace.lossShare : pace.gainShare);
    final clamped = requested.clamp(
      losing ? minWeeklyLossKg : minWeeklyGainKg,
      losing ? maxWeeklyLossKg : maxWeeklyGainKg,
    );

    final gap = clamped * kcalPerKgBodyMass / 7;
    final capped = math.min(gap, losing ? maxDailyDeficit : maxDailySurplus);

    return (
      dailyGap: capped,
      paceReduced: capped < gap || clamped != requested,
    );
  }

  static double _roundCalories(double value) =>
      ((value / 10).round() * 10).toDouble().clamp(minCalories, maxCalories);

  /// Protein tracks lean mass, so a high-BMI user is billed against their goal
  /// weight rather than their current weight.
  static double _referenceWeight(BodyProfile profile) {
    final weight = profile.weightKg;
    if (weight == null) return 70;

    if (profile.targetWeightKg case final target?) {
      if (target < weight) return target;
    }

    final bmi = profile.bmi;
    if (bmi != null && bmi > highAdiposityBmi && profile.heightCm != null) {
      final metres = profile.heightCm! / 100;
      return math.min(weight, proxyGoalBmi * metres * metres);
    }

    return weight;
  }

  static ({double protein, double carbs, double fat, bool proteinCapped})
  _macros({
    required double calories,
    required DietPattern diet,
    required ActivityLevel activity,
    required WeightGoal goal,
    required double referenceWeightKg,
  }) {
    var perKg = activity.proteinPerKg;
    if (goal == WeightGoal.lose) perKg += deficitProteinBonus;
    if (diet.minProteinPerKg case final floor?) {
      perKg = math.max(perKg, floor);
    }
    if (diet.maxProteinPerKg case final ceiling?) {
      perKg = math.min(perKg, ceiling);
    }
    perKg = perKg.clamp(minProteinPerKg, maxProteinPerKg);

    var protein = perKg * referenceWeightKg;
    final proteinCeiling = calories * proteinEnergyCeiling / 4;
    final proteinCapped = protein > proteinCeiling;
    if (proteinCapped) protein = proteinCeiling;

    final remaining = calories - protein * 4;

    double carbs;
    double fat;
    if (diet.fixedCarbGrams case final fixed?) {
      carbs = math.min(fixed, remaining / 4);
      fat = (remaining - carbs * 4) / 9;
    } else {
      carbs = remaining * diet.carbShare / 4;
      fat = remaining * (1 - diet.carbShare) / 9;
    }

    // Fat has an AMDR lower bound that the low-fat end of a split can breach.
    final fatFloorGrams = calories * fatEnergyFloor / 9;
    if (fat < fatFloorGrams) {
      fat = fatFloorGrams;
      carbs = (remaining - fat * 9) / 4;
    }

    // Carbohydrate has no such bound, but patterns that are not deliberately
    // low-carb should not drift into one by arithmetic.
    final restrictsCarbs =
        diet.fixedCarbGrams != null || diet.carbShare <= 0.35;
    if (!restrictsCarbs && carbs < minCarbGrams) {
      carbs = math.min(minCarbGrams, remaining / 4);
      fat = (remaining - carbs * 4) / 9;
    }

    return (
      protein: math.max(0, protein).roundToDouble(),
      carbs: math.max(0, carbs).roundToDouble(),
      fat: math.max(0, fat).roundToDouble(),
      proteinCapped: proteinCapped,
    );
  }

  /// Whole weeks to the target weight, only when the target actually lies in
  /// the direction the user chose.
  static int? _estimatedWeeks(
    BodyProfile profile,
    WeightGoal goal,
    double weeklyRateKg,
  ) {
    final target = profile.targetWeightKg;
    final weight = profile.weightKg;
    if (target == null || weight == null) return null;
    if (goal == WeightGoal.maintain || weeklyRateKg == 0) return null;

    final distance = target - weight;
    if (distance.sign != weeklyRateKg.sign) return null;

    final weeks = (distance.abs() / weeklyRateKg.abs()).ceil();
    return weeks <= 0 ? null : weeks;
  }
}
