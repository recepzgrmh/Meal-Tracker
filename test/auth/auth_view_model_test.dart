import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/auth/domain/auth_failure.dart';
import 'package:meal_clarity/src/auth/presentation/auth_view_model.dart';

import '../support/fakes.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthViewModel viewModel;

  setUp(() {
    repository = FakeAuthRepository();
    viewModel = AuthViewModel(
      repository,
      resendCooldown: const Duration(seconds: 2),
    );
  });

  tearDown(() async {
    viewModel.dispose();
    await repository.close();
  });

  test('successful request advances to OTP and starts cooldown', () async {
    final result = await viewModel.requestOtp('  test@example.com  ');

    expect(result, isTrue);
    expect(viewModel.email, 'test@example.com');
    expect(viewModel.step, AuthStep.otp);
    expect(viewModel.resendSeconds, 2);
    expect(repository.requestCount, 1);
  });

  test('stable domain error remains available to the UI', () async {
    repository.nextFailure = const AuthFailure(
      AuthFailureCode.rateLimited,
      'Geri sayım bitince tekrar dene.',
    );

    final result = await viewModel.requestOtp('test@example.com');

    expect(result, isFalse);
    expect(viewModel.step, AuthStep.email);
    expect(viewModel.errorMessage, 'Geri sayım bitince tekrar dene.');
  });

  test('verification returns a session', () async {
    await viewModel.requestOtp('test@example.com');

    final session = await viewModel.verifyOtp('123456');

    expect(session?.userId, 'user-1');
    expect(repository.verifyCount, 1);
  });
}
