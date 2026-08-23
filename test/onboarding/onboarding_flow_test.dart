import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/bootstrap/meal_clarity_root.dart';

import '../support/fakes.dart';

void main() {
  testWidgets('fresh user reaches auth through interactive onboarding', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('tr');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    final auth = FakeAuthRepository();
    final onboarding = FakeOnboardingRepository();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MealClarityRoot(
          authRepository: auth,
          onboardingRepository: onboarding,
          profileRepository: FakeProfileRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-continue')), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('photo-guide-continue')), findsOneWidget);
    await tester.tap(find.byKey(const Key('photo-guide-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('demo-cheese-row')), findsOneWidget);
    final suggestedPortion = find.byKey(const Key('demo-portion-50'));
    await tester.ensureVisible(suggestedPortion);
    await tester.tap(suggestedPortion);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-finish')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth-email')), findsOneWidget);
    expect(onboarding.draft.step, 3);

    await auth.close();
  });

  testWidgets('example result expands inline and updates the total', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('tr');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    final auth = FakeAuthRepository();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MealClarityRoot(
          authRepository: auth,
          onboardingRepository: FakeOnboardingRepository(),
          profileRepository: FakeProfileRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('≈ 415 kcal'), findsNothing);
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo-guide-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('demo-cheese-row')), findsOneWidget);
    final seventyFiveGrams = find.byKey(const Key('demo-portion-75'));
    await tester.ensureVisible(seventyFiveGrams);
    await tester.tap(seventyFiveGrams);
    await tester.pumpAndSettle();
    expect(find.text('≈ 478 kcal'), findsOneWidget);

    await auth.close();
  });

  testWidgets('onboarding welcome remains usable at 200 percent text scale', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MealClarityRoot(
          authRepository: auth,
          onboardingRepository: FakeOnboardingRepository(),
          profileRepository: FakeProfileRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-continue')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await auth.close();
  });
}
