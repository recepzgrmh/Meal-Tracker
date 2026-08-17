import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meal_clarity/src/bootstrap/meal_clarity_root.dart';

import '../test/support/fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboards, authenticates, commits profile, and opens Today', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    final onboarding = FakeOnboardingRepository();
    final profile = FakeProfileRepository();

    await tester.pumpWidget(
      MealClarityRoot(
        authRepository: auth,
        onboardingRepository: onboarding,
        profileRepository: profile,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('demo-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('demo-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ne yediğimi daha iyi anlamak'));
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
    await tester.pumpAndSettle();

    expect(find.text('Bugün'), findsWidgets);
    expect(find.byKey(const Key('quick-composer')), findsOneWidget);
    expect(profile.completionCount, 1);
    expect(onboarding.version, 1);

    await auth.close();
  });
}
