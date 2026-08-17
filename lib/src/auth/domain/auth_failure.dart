enum AuthFailureCode {
  invalidEmail,
  invalidOtp,
  expiredOtp,
  rateLimited,
  network,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message);

  final AuthFailureCode code;
  final String message;

  @override
  String toString() => message;
}
