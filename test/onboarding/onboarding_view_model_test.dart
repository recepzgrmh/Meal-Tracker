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

  test('skipping the tour lands on the sign-in step without answers', () async {
    final repository = FakeOnboardingRepository();
    final viewModel = OnboardingViewModel(repository);
    await viewModel.initialize();

    await viewModel.skipToSignIn();

    expect(repository.draft.step, 3);
    expect(repository.draft.intention, isNull);
    expect(repository.draft.body.sex, isNull);
  });

  test('the step never escapes the flow it addresses', () async {
    final repository = FakeOnboardingRepository();
    final viewModel = OnboardingViewModel(repository);
    await viewModel.initialize();

    await viewModel.goToStep(-4);
    expect(viewModel.draft.step, 0);

    await viewModel.goToStep(99);
    expect(viewModel.draft.step, 3);
  });
}
