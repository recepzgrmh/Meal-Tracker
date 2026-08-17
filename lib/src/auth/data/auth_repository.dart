import '../domain/auth_session.dart';

abstract interface class AuthRepository {
  AuthSession? get currentSession;

  Stream<AuthSession?> get sessionChanges;

  Future<void> requestEmailOtp(String email);

  Future<AuthSession> verifyEmailOtp({
    required String email,
    required String token,
  });

  Future<void> signOut();
}
