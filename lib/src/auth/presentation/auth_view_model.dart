import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_session.dart';

enum AuthStep { email, otp }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(
    this._repository, {
    this.resendCooldown = const Duration(seconds: 60),
  });

  final AuthRepository _repository;
  final Duration resendCooldown;

  AuthStep _step = AuthStep.email;
  String _email = '';
  bool _isBusy = false;
  String? _errorMessage;
  AuthFailureCode? _errorCode;
  int _resendSeconds = 0;
  Timer? _timer;

  AuthStep get step => _step;
  String get email => _email;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  AuthFailureCode? get errorCode => _errorCode;
  int get resendSeconds => _resendSeconds;
  bool get canResend => !_isBusy && _resendSeconds == 0;
  bool get canRequestOtp => !_isBusy && _resendSeconds == 0;
  bool get isEmailRateLimited => _errorCode == AuthFailureCode.emailRateLimited;

  Future<bool> requestOtp(String email) async {
    if (!canRequestOtp) return false;
    _email = email.trim();
    _setBusy(true);
    try {
      await _repository.requestEmailOtp(_email);
      _step = AuthStep.otp;
      _startCooldown();
      return true;
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
      _errorCode = error.code;
      if (error.code == AuthFailureCode.emailRateLimited ||
          error.code == AuthFailureCode.rateLimited) {
        _startCooldown(error.retryAfter ?? resendCooldown);
      }
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<AuthSession?> verifyOtp(String token) async {
    if (_isBusy) return null;
    _setBusy(true);
    try {
      final session = await _repository.verifyEmailOtp(
        email: _email,
        token: token,
      );
      _timer?.cancel();
      _resendSeconds = 0;
      return session;
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
      _errorCode = error.code;
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> resendOtp() async {
    if (!canResend) return false;
    return requestOtp(_email);
  }

  /// A send limit does not invalidate a code that already reached the inbox.
  /// This lets the user continue with that code instead of being trapped on
  /// the email screen until the project-wide mail quota resets.
  void useExistingCode() {
    if (_email.isEmpty) return;
    _step = AuthStep.otp;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();
  }

  void editEmail() {
    _timer?.cancel();
    _step = AuthStep.email;
    _errorMessage = null;
    _errorCode = null;
    _resendSeconds = 0;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _isBusy = value;
    if (value) _errorMessage = null;
    if (value) _errorCode = null;
    notifyListeners();
  }

  void _startCooldown([Duration? duration]) {
    _timer?.cancel();
    _resendSeconds = (duration ?? resendCooldown).inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _resendSeconds--;
      if (_resendSeconds <= 0) {
        timer.cancel();
        if (_errorCode == AuthFailureCode.emailRateLimited ||
            _errorCode == AuthFailureCode.rateLimited) {
          _errorMessage = null;
          _errorCode = null;
        }
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
