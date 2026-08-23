import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/onboarding/domain/body_profile.dart';
import 'package:meal_clarity/src/onboarding/domain/calorie_calculator.dart';
import 'package:meal_clarity/src/onboarding/domain/nutrition_plan.dart';

/// Fixed so `ageAt` is deterministic: birth year 1996 reads as age 30.
final _now = DateTime.utc(2026, 8, 23);

BodyProfile _profile({
  BiologicalSex sex = BiologicalSex.male,
  int birthYear = 1996,
  double heightCm = 175,
  double weightKg = 70,
  double? targetWeightKg,
  ActivityLevel activity = ActivityLevel.moderate,
  WeightGoal goal = WeightGoal.maintain,
  GoalPace pace = GoalPace.steady,
  DietPattern diet = DietPattern.balanced,
}) {
  return BodyProfile(
    sex: sex,
    birthYear: birthYear,
    heightCm: heightCm,
    weightKg: weightKg,
    targetWeightKg: targetWeightKg,
    activityLevel: activity,
    goal: goal,
    pace: pace,
    dietPattern: diet,
  );
}

NutritionPlan _plan(BodyProfile profile) =>
    CalorieCalculator.estimate(profile, now: _now)!;

void main() {
  group('Mifflin-St Jeor', () {
    test('reproduces the published worked example', () {
      final plan = _plan(_profile());

      // 10*70 + 6.25*175 - 5*30 + 5
      expect(plan.bmr, closeTo(1648.75, 0.01));
      expect(plan.tdee, closeTo(1648.75 * 1.55, 0.01));
      expect(plan.calories, closeTo(2560, 10));
    });

    test('applies the sex constant', () {
      final male = _plan(_profile(sex: BiologicalSex.male)).bmr!;
      final female = _plan(_profile(sex: BiologicalSex.female)).bmr!;
      final unspecified = _plan(_profile(sex: BiologicalSex.unspecified)).bmr!;

      expect(male - female, closeTo(166, 0.01));
      // The unspecified constant is the midpoint of the other two.
      expect(unspecified, closeTo((male + female) / 2, 0.01));
    });

    test('returns null until every answer is present', () {
      expect(
        CalorieCalculator.estimate(const BodyProfile(), now: _now),
        isNull,
      );
      expect(
        CalorieCalculator.estimate(
          const BodyProfile(
            sex: BiologicalSex.male,
            birthYear: 1996,
            heightCm: 175,
            weightKg: 70,
            activityLevel: ActivityLevel.moderate,
            goal: WeightGoal.maintain,
          ),
          now: _now,
        ),
        isNull,
        reason: 'diet pattern is still missing',
      );
    });

    test('rejects an age outside the supported range', () {
      expect(
        CalorieCalculator.estimate(_profile(birthYear: 2020), now: _now),
        isNull,
      );
    });
  });

  group('energy gap', () {
    test('scales the weekly rate with body weight', () {
      final light = _plan(
        _profile(weightKg: 60, goal: WeightGoal.lose),
      ).weeklyRateKg;
      final heavy = _plan(
        _profile(weightKg: 110, goal: WeightGoal.lose),
      ).weeklyRateKg;

      expect(light, closeTo(-0.3, 0.02));
      expect(heavy, closeTo(-0.55, 0.02));
    });

    test('caps the deficit at 1000 kcal per day', () {
      final plan = _plan(
        _profile(
          weightKg: 200,
          heightCm: 190,
          goal: WeightGoal.lose,
          pace: GoalPace.fast,
          activity: ActivityLevel.athlete,
        ),
      );

      expect(plan.warnings, contains(PlanWarning.paceReduced));
      expect(plan.tdee! - plan.calories, lessThanOrEqualTo(1000 + 5));
    });

    test('caps the surplus at 500 kcal per day', () {
      final plan = _plan(
        _profile(weightKg: 200, goal: WeightGoal.gain, pace: GoalPace.fast),
      );

      expect(plan.calories - plan.tdee!, lessThanOrEqualTo(500 + 5));
    });

    test('maintaining leaves the target at maintenance', () {
      final plan = _plan(_profile());

      expect(plan.weeklyRateKg, closeTo(0, 0.02));
      expect(plan.calories, closeTo(plan.tdee!, 10));
    });
  });

  group('safety floors', () {
    test('raises a small sedentary woman to the 1200 kcal floor', () {
      final plan = _plan(
        _profile(
          sex: BiologicalSex.female,
          heightCm: 152,
          weightKg: 50,
          activity: ActivityLevel.sedentary,
          goal: WeightGoal.lose,
          pace: GoalPace.fast,
        ),
      );

      expect(plan.warnings, contains(PlanWarning.calorieFloorApplied));
      expect(plan.calories, greaterThanOrEqualTo(1200));
    });

    test('never drops below the user own BMR', () {
      final plan = _plan(
        _profile(
          weightKg: 130,
          heightCm: 185,
          activity: ActivityLevel.sedentary,
          goal: WeightGoal.lose,
          pace: GoalPace.fast,
        ),
      );

      expect(plan.calories, greaterThanOrEqualTo(plan.bmr!));
    });

    test('declines a deficit when the user is already underweight', () {
      final plan = _plan(
        _profile(
          sex: BiologicalSex.female,
          heightCm: 170,
          weightKg: 50,
          goal: WeightGoal.lose,
        ),
      );

      expect(plan.warnings, contains(PlanWarning.underweightDeficit));
      expect(plan.calories, closeTo(plan.tdee!, 10));
    });

    test('flags a minor without refusing to answer', () {
      final plan = _plan(_profile(birthYear: 2012));

      expect(plan.warnings, contains(PlanWarning.minorAge));
      expect(plan.calories, greaterThan(0));
    });
  });

  group('macros', () {
    test('keto pins carbohydrate to its gram cap', () {
      final plan = _plan(_profile(diet: DietPattern.keto));

      expect(plan.carbsG, 25);
      expect(plan.fatG * 9 / plan.calories, greaterThan(0.6));
    });

    test('high protein raises protein above the activity baseline', () {
      final balanced = _plan(_profile(diet: DietPattern.balanced)).proteinG;
      final high = _plan(_profile(diet: DietPattern.highProtein)).proteinG;

      expect(high, greaterThan(balanced));
    });

    test('a deficit adds protein for lean-mass retention', () {
      final maintaining = _plan(_profile()).proteinG;
      final losing = _plan(_profile(goal: WeightGoal.lose)).proteinG;

      expect(losing, greaterThan(maintaining));
    });

    test('bills protein against goal weight at a high BMI', () {
      final heavy = _profile(weightKg: 120, heightCm: 170);
      final plan = _plan(heavy);

      // 120 kg at 1.6 g/kg would be 192 g; the BMI 25 proxy is ~72 kg.
      expect(plan.proteinG, lessThan(150));
    });

    test('honours the AMDR bounds for every pattern', () {
      for (final diet in DietPattern.values) {
        for (final goal in WeightGoal.values) {
          final plan = _plan(_profile(diet: diet, goal: goal));

          final proteinShare = plan.proteinG * 4 / plan.calories;
          final fatShare = plan.fatG * 9 / plan.calories;

          expect(
            proteinShare,
            lessThanOrEqualTo(0.36),
            reason: '$diet/$goal protein share',
          );
          expect(
            fatShare,
            greaterThanOrEqualTo(0.19),
            reason: '$diet/$goal fat share',
          );
          expect(plan.carbsG, greaterThanOrEqualTo(0));
        }
      }
    });

    test('macro energy adds back up to the calorie target', () {
      for (final diet in DietPattern.values) {
        final plan = _plan(_profile(diet: diet));
        final total = plan.proteinG * 4 + plan.carbsG * 4 + plan.fatG * 9;

        expect(
          total,
          closeTo(plan.calories, plan.calories * 0.02),
          reason: '$diet',
        );
      }
    });
  });

  group('projection', () {
    test('estimates weeks to the target weight', () {
      final plan = _plan(
        _profile(weightKg: 90, targetWeightKg: 80, goal: WeightGoal.lose),
      );

      // ~0.45 kg/week over 10 kg.
      expect(plan.estimatedWeeks, inInclusiveRange(20, 26));
    });

    test('has no projection when the target sits the wrong way', () {
      final plan = _plan(
        _profile(weightKg: 90, targetWeightKg: 95, goal: WeightGoal.lose),
      );

      expect(plan.estimatedWeeks, isNull);
    });
  });

  group('manual override', () {
    test('keeps the working but marks the source as manual', () {
      final profile = _profile();
      final plan = CalorieCalculator.withManualCalories(
        profile,
        1800,
        now: _now,
      );

      expect(plan.calories, 1800);
      expect(plan.source, PlanSource.manual);
      expect(plan.isEstimated, isFalse);
      expect(plan.bmr, closeTo(1648.75, 0.01));
      expect(
        plan.proteinG * 4 + plan.carbsG * 4 + plan.fatG * 9,
        closeTo(1800, 36),
      );
    });

    test('clamps an out-of-range override into the database range', () {
      expect(
        CalorieCalculator.withManualCalories(
          _profile(),
          99,
          now: _now,
        ).calories,
        500,
      );
      expect(
        CalorieCalculator.withManualCalories(
          _profile(),
          99999,
          now: _now,
        ).calories,
        10000,
      );
    });
  });
}
