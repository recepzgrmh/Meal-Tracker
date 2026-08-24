import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/l10n/generated/app_localizations.dart';
import 'package:meal_clarity/src/auth/domain/auth_session.dart';
import 'package:meal_clarity/src/bootstrap/app_coordinator.dart';
import 'package:meal_clarity/src/onboarding/domain/body_profile.dart';
import 'package:meal_clarity/src/onboarding/domain/nutrition_plan.dart';
import 'package:meal_clarity/src/onboarding/domain/onboarding_draft.dart';
import 'package:meal_clarity/src/onboarding/presentation/profile_setup_screen.dart';
import 'package:meal_clarity/src/onboarding/presentation/profile_setup_view_model.dart';

import '../support/fakes.dart';

/// A draft with every question already answered, so a test can open the flow
/// on the step it is actually about.
const _answered = OnboardingDraft(
  step: 3,
  intention: TrackingIntention.calories,
  body: BodyProfile(
    sex: BiologicalSex.female,
    birthYear: 1992,
    heightCm: 165,
    weightKg: 68,
    activityLevel: ActivityLevel.moderate,
    goal: WeightGoal.lose,
    dietPattern: DietPattern.balanced,
  ),
);

Future<({AppCoordinator coordinator, ProfileSetupViewModel viewModel})> _pump(
  WidgetTester tester, {
  required FakeAuthRepository auth,
  required FakeOnboardingRepository onboarding,
  FakeProfileRepository? profile,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  auth.session = const AuthSession(userId: 'user-1', email: 'a@b.co');
  final coordinator = AppCoordinator(
    authRepository: auth,
    onboardingRepository: onboarding,
    profileRepository: profile ?? FakeProfileRepository(),
  );
  await coordinator.initialize();
  final viewModel = ProfileSetupViewModel(onboarding);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: true, textScaler: textScaler),
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
  return (coordinator: coordinator, viewModel: viewModel);
}

void main() {
  testWidgets('the summary shows the computed plan and saves it', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    final onboarding = FakeOnboardingRepository()..draft = _answered;
    final profile = FakeProfileRepository();
    final handles = await _pump(
      tester,
      auth: auth,
      onboarding: onboarding,
      profile: profile,
    );

    await handles.viewModel.goTo(ProfileSetupViewModel.summaryStep);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('setup-summary-calories')), findsOneWidget);
    await tester.tap(find.byKey(const Key('setup-finish')));
    // Not pumpAndSettle: the saving pane spins until the router moves on, so
    // settling would wait for an animation that never ends in isolation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(profile.completionCount, 1);
    expect(profile.lastDraft!.plan!.source, PlanSource.computed);

    handles.coordinator.dispose();
    await auth.close();
  });

  testWidgets('an override replaces the estimate on the summary', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    final onboarding = FakeOnboardingRepository()..draft = _answered;
    final profile = FakeProfileRepository();
    final handles = await _pump(
      tester,
      auth: auth,
      onboarding: onboarding,
      profile: profile,
    );

    await handles.viewModel.goTo(ProfileSetupViewModel.summaryStep);
    await tester.pumpAndSettle();

    final toggle = find.byKey(const Key('setup-override-toggle'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('setup-override')), '1750');
    await tester.pumpAndSettle();

    final finish = find.byKey(const Key('setup-finish'));
    await tester.ensureVisible(finish);
    await tester.tap(finish);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(profile.lastDraft!.plan!.calories, 1750);
    expect(profile.lastDraft!.plan!.source, PlanSource.manual);

    handles.coordinator.dispose();
    await auth.close();
  });

  testWidgets('a failed save offers a retry rather than losing the answers', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    final onboarding = FakeOnboardingRepository()..draft = _answered;
    final profile = FakeProfileRepository()..shouldFail = true;
    final handles = await _pump(
      tester,
      auth: auth,
      onboarding: onboarding,
      profile: profile,
    );

    await handles.viewModel.goTo(ProfileSetupViewModel.summaryStep);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('setup-finish')));
    await tester.pumpAndSettle();

    expect(handles.coordinator.profileError, ProfileCompletionError.saveFailed);
    expect(find.text('Tekrar dene'), findsOneWidget);
    expect(onboarding.version, 0);

    handles.coordinator.dispose();
    await auth.close();
  });

  testWidgets('every step lays out at 200 percent text scale', (tester) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = FakeAuthRepository();
    final onboarding = FakeOnboardingRepository()..draft = _answered;
    final handles = await _pump(
      tester,
      auth: auth,
      onboarding: onboarding,
      textScaler: const TextScaler.linear(2),
    );

    for (var step = 0; step < ProfileSetupViewModel.stepCount; step++) {
      await handles.viewModel.goTo(step);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'step $step overflowed');
    }

    handles.coordinator.dispose();
    await auth.close();
  });
}
