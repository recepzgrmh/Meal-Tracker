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
  int _resendSeconds = 0;
  Timer? _timer;

  AuthStep get step => _step;
  String get email => _email;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  int get resendSeconds => _resendSeconds;
  bool get canResend => !_isBusy && _resendSeconds == 0;

  Future<bool> requestOtp(String email) async {
    if (_isBusy) return false;
    _email = email.trim();
    _setBusy(true);
    try {
      await _repository.requestEmailOtp(_email);
      _step = AuthStep.otp;
      _startCooldown();
      return true;
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
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
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> resendOtp() async {
    if (!canResend) return false;
    return requestOtp(_email);
  }

  void editEmail() {
    _timer?.cancel();
    _step = AuthStep.email;
    _errorMessage = null;
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
    notifyListeners();
  }

  void _startCooldown() {
    _timer?.cancel();
    _resendSeconds = resendCooldown.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _resendSeconds--;
      if (_resendSeconds <= 0) timer.cancel();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
