import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/auth/domain/auth_session.dart';
import 'package:meal_clarity/src/bootstrap/app_coordinator.dart';
import 'package:meal_clarity/src/onboarding/domain/onboarding_draft.dart';
import 'package:meal_clarity/src/onboarding/presentation/onboarding_view_model.dart';

import '../support/fakes.dart';

void main() {
  test('cold boot derives onboarding without protected screen flash', () async {
    final auth = FakeAuthRepository();
    final onboarding = FakeOnboardingRepository();
    final coordinator = AppCoordinator(
      authRepository: auth,
      onboardingRepository: onboarding,
      profileRepository: FakeProfileRepository(),
    );

    expect(coordinator.state, AppFlowState.booting);
    await coordinator.initialize();
    expect(coordinator.state, AppFlowState.onboarding);

    coordinator.dispose();
    await auth.close();
  });

  test('draft complete and session missing routes to authentication', () async {
    final auth = FakeAuthRepository();
    final onboarding = FakeOnboardingRepository()
      ..draft = const OnboardingDraft(step: 3);
    final coordinator = AppCoordinator(
      authRepository: auth,
      onboardingRepository: onboarding,
      profileRepository: FakeProfileRepository(),
    );

    await coordinator.initialize();

    expect(coordinator.state, AppFlowState.authentication);
    coordinator.dispose();
    await auth.close();
  });

  test('profile completion persists version before entering app', () async {
    final auth = FakeAuthRepository()
      ..session = const AuthSession(userId: 'user-1', email: 'a@b.co');
    final onboarding = FakeOnboardingRepository()
      ..draft = const OnboardingDraft(
        step: 3,
        intention: TrackingIntention.protein,
      );
    final profile = FakeProfileRepository();
    final coordinator = AppCoordinator(
      authRepository: auth,
      onboardingRepository: onboarding,
      profileRepository: profile,
    );
    await coordinator.initialize();

    expect(coordinator.state, AppFlowState.profile);
    expect(await coordinator.completeProfile(), isTrue);
    expect(coordinator.state, AppFlowState.ready);
    expect(onboarding.version, OnboardingViewModel.currentVersion);
    expect(profile.completionCount, 1);

    coordinator.dispose();
    await auth.close();
  });
}
