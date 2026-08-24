import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/auth/domain/auth_failure.dart';
import 'package:meal_clarity/src/auth/presentation/auth_screen.dart';
import 'package:meal_clarity/src/auth/presentation/auth_view_model.dart';
import 'package:meal_clarity/src/theme/app_theme.dart';

import '../support/fakes.dart';

void main() {
  testWidgets('email delivery failure shows an actionable message', (
    tester,
  ) async {
    final repository = FakeAuthRepository()
      ..nextFailure = const AuthFailure(
        AuthFailureCode.emailDeliveryFailed,
        'Doğrulama e-postası şu anda gönderilemedi.',
      );
    final viewModel = AuthViewModel(repository);
    addTearDown(repository.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: AuthScreen(viewModel: viewModel, onAuthenticated: () async {}),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'test@example.com',
    );
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pump();

    expect(find.textContaining('Doğrulama e-postası'), findsOneWidget);
    viewModel.dispose();
  });

  testWidgets('email limit keeps a path to an already delivered code', (
    tester,
  ) async {
    final repository = FakeAuthRepository()
      ..nextFailure = const AuthFailure(
        AuthFailureCode.emailRateLimited,
        'E-posta gönderim sınırına ulaşıldı.',
        retryAfter: Duration(minutes: 30),
      );
    final viewModel = AuthViewModel(repository);
    addTearDown(repository.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: AuthScreen(viewModel: viewModel, onAuthenticated: () async {}),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'test@example.com',
    );
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pump();

    expect(find.byKey(const Key('auth-use-existing-code')), findsOneWidget);
    expect(find.textContaining('30:00'), findsWidgets);
    await tester.tap(find.byKey(const Key('auth-use-existing-code')));
    await tester.pump();
    expect(find.byKey(const Key('auth-otp')), findsOneWidget);
    viewModel.dispose();
  });

  testWidgets('OTP is submitted only from the explicit verify action', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    final viewModel = AuthViewModel(
      repository,
      resendCooldown: const Duration(seconds: 2),
    );
    addTearDown(repository.close);
    await viewModel.requestOtp('test@example.com');

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: AuthScreen(viewModel: viewModel, onAuthenticated: () async {}),
      ),
    );
    await tester.enterText(find.byKey(const Key('auth-otp')), '123456');
    await tester.pump();

    expect(repository.verifyCount, 0);
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pump();
    expect(repository.verifyCount, 1);
    viewModel.dispose();
  });
}
