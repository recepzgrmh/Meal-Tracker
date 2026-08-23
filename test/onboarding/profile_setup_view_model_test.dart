import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/onboarding/domain/body_profile.dart';
import 'package:meal_clarity/src/onboarding/domain/nutrition_plan.dart';
import 'package:meal_clarity/src/onboarding/domain/onboarding_draft.dart';
import 'package:meal_clarity/src/onboarding/presentation/profile_setup_view_model.dart';

import '../support/fakes.dart';

final _now = DateTime.utc(2026, 8, 24);

Future<ProfileSetupViewModel> _viewModel([
  FakeOnboardingRepository? repository,
]) async {
  final model = ProfileSetupViewModel(
    repository ?? FakeOnboardingRepository(),
    clock: () => _now,
  );
  await model.initialize();
  return model;
}

/// Answers every question so the summary step has a plan to show.
Future<ProfileSetupViewModel> _answered([
  FakeOnboardingRepository? repository,
]) async {
  final model = await _viewModel(repository);
  await model.selectSex(BiologicalSex.female);
  model.updateAge('34');
  model.updateHeight('165');
  model.updateWeight('68');
  await model.selectActivity(ActivityLevel.moderate);
  await model.selectGoal(WeightGoal.lose);
  await model.selectDiet(DietPattern.balanced);
  await model.selectIntention(TrackingIntention.calories);
  return model;
}

void main() {
  group('age', () {
    test('is stored as a birth year', () async {
      final model = await _viewModel();

      model.updateAge('34');

      expect(model.body.birthYear, 1992);
      expect(model.ageFieldValue(), '34');
      expect(model.ageError, isNull);
    });

    test('rejects an age outside the supported range', () async {
      final model = await _viewModel();

      model.updateAge('7');

      expect(model.ageError, NumericFieldError.outOfRange);
      expect(model.canAdvance, isFalse);
    });

    test('reports a non-numeric entry separately from an empty one', () async {
      final model = await _viewModel();

      model.updateAge('otuz');
      expect(model.ageError, NumericFieldError.malformed);

      model.updateAge('');
      expect(model.ageError, NumericFieldError.missing);
    });
  });

  group('units', () {
    test('converts feet and inches to centimetres', () async {
      final model = await _viewModel();
      await model.selectMeasurementSystem(MeasurementSystem.imperial);

      model.updateHeight('5', secondary: '9');

      expect(model.body.heightCm, closeTo(175.26, 0.01));
      expect(model.heightError, isNull);
    });

    test('a blank inches field reads as an exact foot', () async {
      final model = await _viewModel();
      await model.selectMeasurementSystem(MeasurementSystem.imperial);

      model.updateHeight('6');

      expect(model.body.heightCm, closeTo(182.88, 0.01));
    });

    test('converts pounds to kilograms', () async {
      final model = await _viewModel();
      await model.selectMeasurementSystem(MeasurementSystem.imperial);

      model.updateWeight('154');

      expect(model.body.weightKg, closeTo(69.85, 0.01));
    });

    test('switching units re-displays the same body, not a new one', () async {
      final model = await _viewModel();
      model.updateHeight('180');
      model.updateWeight('80');

      await model.selectMeasurementSystem(MeasurementSystem.imperial);

      expect(model.body.heightCm, 180);
      expect(model.body.weightKg, 80);
      expect(model.heightFieldValues().primary, '5');
      expect(model.heightFieldValues().secondary, '11');
      expect(model.weightFieldValue(), '176.4');
    });
  });

  group('advancing', () {
    test('each step waits for the answer it asks for', () async {
      final model = await _viewModel();
      expect(model.canAdvance, isFalse);

      await model.selectSex(BiologicalSex.male);
      model.updateAge('30');
      expect(model.canAdvance, isTrue);

      await model.next();
      expect(model.canAdvance, isFalse);

      model.updateHeight('178');
      model.updateWeight('75');
      expect(model.canAdvance, isTrue);
    });

    test('the summary step is always reachable', () async {
      final model = await _viewModel();
      await model.goTo(ProfileSetupViewModel.summaryStep);

      expect(model.canAdvance, isTrue);
      expect(model.step, ProfileSetupViewModel.summaryStep);
    });

    test('the step never leaves the flow', () async {
      final model = await _viewModel();

      await model.goTo(-1);
      expect(model.step, 0);

      await model.goTo(99);
      expect(model.step, ProfileSetupViewModel.stepCount - 1);
    });
  });

  group('goal', () {
    test('choosing to maintain drops a target weight', () async {
      final model = await _viewModel();
      model.updateWeight('80');
      model.updateTargetWeight('72');
      await model.selectGoal(WeightGoal.lose);
      expect(model.body.targetWeightKg, 72);

      await model.selectGoal(WeightGoal.maintain);

      expect(model.body.targetWeightKg, isNull);
    });

    test('an empty target weight is allowed, not an error', () async {
      final model = await _viewModel();
      model.updateTargetWeight('72');
      model.updateTargetWeight('');

      expect(model.body.targetWeightKg, isNull);
      expect(model.targetWeightError, isNull);
    });
  });

  group('plan', () {
    test('appears once every answer is in', () async {
      final model = await _viewModel();
      expect(model.plan, isNull);

      final answered = await _answered();

      expect(answered.plan, isNotNull);
      expect(answered.plan!.source, PlanSource.computed);
      expect(answered.plan!.calories, greaterThan(1200));
    });

    test(
      'an override replaces the estimate and is marked as the user\'s',
      () async {
        final model = await _answered();
        final computed = model.plan!.calories;

        await model.setCalorieOverride('1800');

        expect(model.plan!.calories, 1800);
        expect(model.plan!.source, PlanSource.manual);
        expect(model.plan!.isEstimated, isFalse);
        expect(computed, isNot(1800));
      },
    );

    test('clearing the override hands the target back to the engine', () async {
      final model = await _answered();
      await model.setCalorieOverride('1800');

      await model.setCalorieOverride('');

      expect(model.plan!.source, PlanSource.computed);
      expect(model.draft.dailyCalorieTarget, isNull);
    });

    test('an out-of-range override is rejected, not stored', () async {
      final model = await _answered();

      expect(model.validateCalorieTarget('499'), CalorieTargetError.outOfRange);
      expect(
        model.validateCalorieTarget('10001'),
        CalorieTargetError.outOfRange,
      );
      expect(model.validateCalorieTarget('2100'), isNull);

      await model.setCalorieOverride('499');
      expect(model.draft.dailyCalorieTarget, isNull);
    });
  });

  group('persistence', () {
    test('discrete answers are written immediately', () async {
      final repository = FakeOnboardingRepository();
      final model = await _viewModel(repository);

      await model.selectDiet(DietPattern.vegan);

      expect(repository.draft.body.dietPattern, DietPattern.vegan);
    });

    test('typed answers are flushed when the step changes', () async {
      final repository = FakeOnboardingRepository();
      final model = await _viewModel(repository);

      model.updateAge('41');
      expect(repository.draft.body.birthYear, isNull);

      await model.next();

      expect(repository.draft.body.birthYear, 1985);
    });
  });
}
