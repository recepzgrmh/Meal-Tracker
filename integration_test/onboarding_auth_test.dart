import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meal_clarity/src/bootstrap/meal_clarity_root.dart';
import 'package:meal_clarity/src/domain/nutrition_goals.dart';
import 'package:meal_clarity/src/onboarding/domain/body_profile.dart';
import 'package:meal_clarity/src/onboarding/domain/nutrition_plan.dart';
import 'package:meal_clarity/src/onboarding/presentation/onboarding_view_model.dart';

import '../test/support/fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboards, authenticates, commits profile, and opens Today', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('tr');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    final auth = FakeAuthRepository();
    final onboarding = FakeOnboardingRepository();
    final profile = FakeProfileRepository();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MealClarityRoot(
          authRepository: auth,
          onboardingRepository: onboarding,
          profileRepository: profile,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo-guide-continue')));
    await tester.pumpAndSettle();
    final suggestedPortion = find.byKey(const Key('demo-portion-50'));
    await tester.ensureVisible(suggestedPortion);
    await tester.tap(suggestedPortion);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-finish')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'case@example.com',
    );
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('auth-otp')), '123456');
    await tester.pump();
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();

    // Signing in now leads into setup rather than straight to Today: the
    // calorie target is answered for, not defaulted.
    Future<void> tapAndSettle(Key key) async {
      final finder = find.byKey(key);
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await tapAndSettle(const Key('setup-sex-female'));
    await tester.enterText(find.byKey(const Key('setup-age')), '34');
    await tester.pumpAndSettle();
    await tapAndSettle(const Key('setup-continue'));

    await tester.enterText(find.byKey(const Key('setup-height')), '165');
    await tester.enterText(find.byKey(const Key('setup-weight')), '68');
    await tester.pumpAndSettle();
    await tapAndSettle(const Key('setup-continue'));

    await tapAndSettle(const Key('setup-activity-moderate'));
    await tapAndSettle(const Key('setup-continue'));

    await tapAndSettle(const Key('setup-goal-lose'));
    await tapAndSettle(const Key('setup-pace-steady'));
    await tapAndSettle(const Key('setup-continue'));

    await tapAndSettle(const Key('setup-diet-balanced'));
    await tapAndSettle(const Key('setup-continue'));

    await tapAndSettle(const Key('setup-intention-calories'));
    await tapAndSettle(const Key('setup-continue'));

    expect(find.byKey(const Key('setup-summary-calories')), findsOneWidget);
    await tapAndSettle(const Key('setup-finish'));

    for (
      var attempt = 0;
      attempt < 20 &&
          find.byKey(const Key('quick-composer')).evaluate().isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(auth.verifyCount, 1);
    expect(profile.completionCount, 1);
    expect(onboarding.version, OnboardingViewModel.currentVersion);
    expect(find.byKey(const Key('quick-composer')), findsOneWidget);

    // The answers reached the repository as a real plan, not as the default.
    final saved = profile.lastDraft!;
    expect(saved.body.sex, BiologicalSex.female);
    expect(saved.body.heightCm, 165);
    expect(saved.body.weightKg, 68);
    expect(saved.body.activityLevel, ActivityLevel.moderate);
    expect(saved.body.goal, WeightGoal.lose);
    expect(saved.body.dietPattern, DietPattern.balanced);
    expect(saved.plan, isNotNull);
    expect(saved.plan!.source, PlanSource.computed);
    expect(saved.plan!.calories, isNot(NutritionGoals.fallbackCalories));

    await auth.close();
  });
}
