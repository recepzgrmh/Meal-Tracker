import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/l10n/generated/app_localizations.dart';
import 'package:meal_clarity/src/auth/domain/auth_session.dart';
import 'package:meal_clarity/src/bootstrap/app_coordinator.dart';
import 'package:meal_clarity/src/onboarding/domain/body_profile.dart';
import 'package:meal_clarity/src/onboarding/domain/onboarding_draft.dart';
import 'package:meal_clarity/src/onboarding/presentation/profile_setup_screen.dart';
import 'package:meal_clarity/src/onboarding/presentation/profile_setup_view_model.dart';

import '../support/fakes.dart';

/// Steps that ask exactly one question move on by themselves. The Continue tap
/// that used to follow carried no information — it confirmed the answer just
/// given — and three of the seven steps were like that.

/// Everything before the activity step already answered, so the flow can be
/// opened on the step under test.
const _atActivityStep = OnboardingDraft(
  body: BodyProfile(
    sex: BiologicalSex.female,
    birthYear: 1992,
    heightCm: 165,
    weightKg: 68,
  ),
);

Future<ProfileSetupViewModel> _pump(
  WidgetTester tester, {
  bool accessibleNavigation = false,
}) async {
  final auth = FakeAuthRepository()
    ..session = const AuthSession(userId: 'user-1', email: 'a@b.co');
  final onboarding = FakeOnboardingRepository()..draft = _atActivityStep;
  final coordinator = AppCoordinator(
    authRepository: auth,
    onboardingRepository: onboarding,
    profileRepository: FakeProfileRepository(),
  );
  await coordinator.initialize();
  final viewModel = ProfileSetupViewModel(onboarding);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        disableAnimations: true,
        accessibleNavigation: accessibleNavigation,
      ),
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfileSetupScreen(
          viewModel: viewModel,
          coordinator: coordinator,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // The persisted draft carries a step, but the view model starts every
  // session at zero, so the flow is walked to the step under test the same
  // way the rest of the suite does it.
  await viewModel.goTo(ProfileSetupViewModel.activityStep);
  await tester.pumpAndSettle();
  return viewModel;
}

void main() {
  testWidgets('choosing an activity level advances without a Continue tap', (
    tester,
  ) async {
    final viewModel = await _pump(tester);
    expect(viewModel.step, ProfileSetupViewModel.activityStep);

    await tester.tap(find.byKey(const Key('setup-activity-sedentary')));
    await tester.pumpAndSettle();

    expect(viewModel.step, ProfileSetupViewModel.goalStep);
    expect(viewModel.body.activityLevel, ActivityLevel.sedentary);
  });

  testWidgets('a second tap during the delay does not skip a step', (
    tester,
  ) async {
    final viewModel = await _pump(tester);

    await tester.tap(find.byKey(const Key('setup-activity-sedentary')));
    await tester.pump(const Duration(milliseconds: 60));
    // Changing your mind before the flow moves must not queue a second advance.
    await tester.tap(find.byKey(const Key('setup-activity-moderate')));
    await tester.pumpAndSettle();

    expect(viewModel.step, ProfileSetupViewModel.goalStep);
    expect(viewModel.body.activityLevel, ActivityLevel.moderate);
  });

  testWidgets('screen-reader users keep the explicit Continue button', (
    tester,
  ) async {
    // Auto-advance moves focus out from under a screen reader without being
    // asked, which is what accessibleNavigation exists to suppress.
    final viewModel = await _pump(tester, accessibleNavigation: true);

    await tester.tap(find.byKey(const Key('setup-activity-sedentary')));
    await tester.pumpAndSettle();

    expect(viewModel.step, ProfileSetupViewModel.activityStep);
    expect(viewModel.body.activityLevel, ActivityLevel.sedentary);
  });
}
