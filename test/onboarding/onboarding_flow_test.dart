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
      MealClarityRoot(
        authRepository: auth,
        onboardingRepository: onboarding,
        profileRepository: FakeProfileRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-continue')), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('demo-continue')), findsOneWidget);
    await tester.tap(find.byKey(const Key('demo-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('demo-continue')), findsOneWidget);
    await tester.tap(find.byKey(const Key('demo-continue')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('intent-understand')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-finish')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth-email')), findsOneWidget);
    expect(onboarding.draft.step, 3);

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
