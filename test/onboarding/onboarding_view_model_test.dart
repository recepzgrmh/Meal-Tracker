import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/onboarding/domain/onboarding_draft.dart';
import 'package:meal_clarity/src/onboarding/presentation/onboarding_view_model.dart';

import '../support/fakes.dart';

void main() {
  test('restores and persists the current onboarding step', () async {
    final repository = FakeOnboardingRepository()
      ..draft = const OnboardingDraft(step: 1);
    final viewModel = OnboardingViewModel(repository);

    await viewModel.initialize();
    await viewModel.goToStep(2);

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.draft.step, 2);
    expect(repository.draft.step, 2);
  });

  test('switching away from calorie tracking clears calorie target', () async {
    final repository = FakeOnboardingRepository();
    final viewModel = OnboardingViewModel(repository);
    await viewModel.initialize();

    await viewModel.selectIntention(TrackingIntention.calories);
    await viewModel.setCalorieTarget('2100');
    await viewModel.selectIntention(TrackingIntention.protein);

    expect(viewModel.draft.dailyCalorieTarget, isNull);
    expect(repository.draft.dailyCalorieTarget, isNull);
  });

  test('calorie target enforces the database range', () async {
    final viewModel = OnboardingViewModel(FakeOnboardingRepository());
    await viewModel.initialize();
    await viewModel.selectIntention(TrackingIntention.calories);

    expect(viewModel.validateCalorieTarget('499'), isNotNull);
    expect(viewModel.validateCalorieTarget('10001'), isNotNull);
    expect(viewModel.validateCalorieTarget('2100'), isNull);
    expect(viewModel.validateCalorieTarget(''), isNull);
  });
}
