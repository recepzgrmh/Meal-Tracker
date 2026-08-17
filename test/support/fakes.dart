import 'dart:async';

import 'package:meal_clarity/src/auth/data/auth_repository.dart';
import 'package:meal_clarity/src/auth/domain/auth_failure.dart';
import 'package:meal_clarity/src/auth/domain/auth_session.dart';
import 'package:meal_clarity/src/onboarding/data/onboarding_repository.dart';
import 'package:meal_clarity/src/onboarding/domain/onboarding_draft.dart';

class FakeAuthRepository implements AuthRepository {
  final _sessions = StreamController<AuthSession?>.broadcast();

  AuthSession? session;
  AuthFailure? nextFailure;
  int requestCount = 0;
  int verifyCount = 0;

  @override
  AuthSession? get currentSession => session;

  @override
  Stream<AuthSession?> get sessionChanges => _sessions.stream;

  @override
  Future<void> requestEmailOtp(String email) async {
    requestCount++;
    final failure = nextFailure;
    nextFailure = null;
    if (failure != null) throw failure;
  }

  @override
  Future<AuthSession> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    verifyCount++;
    final failure = nextFailure;
    nextFailure = null;
    if (failure != null) throw failure;
    session = AuthSession(userId: 'user-1', email: email);
    _sessions.add(session);
    return session!;
  }

  @override
  Future<void> signOut() async {
    session = null;
    _sessions.add(null);
  }

  Future<void> close() => _sessions.close();
}

class FakeOnboardingRepository implements OnboardingRepository {
  OnboardingDraft draft = const OnboardingDraft();
  int version = 0;

  @override
  Future<int> completedVersion() async => version;

  @override
  Future<OnboardingDraft> loadDraft() async => draft;

  @override
  Future<void> markCompleted(int version) async => this.version = version;

  @override
  Future<void> restart() async {
    draft = const OnboardingDraft();
    version = 0;
  }

  @override
  Future<void> saveDraft(OnboardingDraft draft) async => this.draft = draft;
}
