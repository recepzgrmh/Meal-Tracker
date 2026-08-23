enum AuthFailureCode {
  invalidEmail,
  invalidOtp,
  expiredOtp,
  emailDeliveryFailed,
  emailRateLimited,
  rateLimited,
  network,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message, {this.retryAfter});

  final AuthFailureCode code;
  final String message;
  final Duration? retryAfter;

  @override
  String toString() => message;
}
