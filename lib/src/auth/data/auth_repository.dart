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

  /// Permanently deletes the signed-in account and everything keyed to it.
  /// Irreversible; the local session is dropped as part of the call.
  Future<void> deleteAccount();
}
