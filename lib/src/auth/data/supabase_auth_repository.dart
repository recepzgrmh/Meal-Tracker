import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../domain/auth_failure.dart';
import '../domain/auth_session.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final supabase.SupabaseClient _client;

  @override
  AuthSession? get currentSession => _mapSession(_client.auth.currentSession);

  @override
  Stream<AuthSession?> get sessionChanges =>
      _client.auth.onAuthStateChange.map((event) => _mapSession(event.session));

  @override
  Future<void> requestEmailOtp(String email) async {
    final normalizedEmail = email.trim();
    if (!_looksLikeEmail(normalizedEmail)) {
      throw const AuthFailure(
        AuthFailureCode.invalidEmail,
        'Geçerli bir e-posta adresi gir.',
      );
    }

    try {
      await _client.auth.signInWithOtp(email: normalizedEmail);
    } on supabase.AuthException catch (error) {
      throw _mapFailure(error);
    } on TimeoutException {
      throw const AuthFailure(
        AuthFailureCode.network,
        'Bağlantı zaman aşımına uğradı. Tekrar dene.',
      );
    }
  }

  @override
  Future<AuthSession> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    if (!RegExp(r'^\d{6}$').hasMatch(token)) {
      throw const AuthFailure(
        AuthFailureCode.invalidOtp,
        'Kod altı rakamdan oluşmalı.',
      );
    }

    try {
      final response = await _client.auth.verifyOTP(
        email: email.trim(),
        token: token,
        type: supabase.OtpType.email,
      );
      final session = _mapSession(response.session);
      if (session == null) {
        throw const AuthFailure(
          AuthFailureCode.unknown,
          'Oturum oluşturulamadı. Tekrar dene.',
        );
      }
      return session;
    } on supabase.AuthException catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on supabase.AuthException catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final response = await _client.functions.invoke('delete-account');
      final payload = response.data;
      if (payload is! Map ||
          payload['contractVersion'] != 'account-delete.v1' ||
          payload['deleted'] != true) {
        throw const AuthFailure(
          AuthFailureCode.unknown,
          'Hesap silinemedi. Lütfen tekrar dene.',
        );
      }
    } on supabase.FunctionException {
      throw const AuthFailure(
        AuthFailureCode.network,
        'Hesap silinemedi. Bağlantını kontrol edip tekrar dene.',
      );
    } on supabase.AuthException catch (error) {
      throw _mapFailure(error);
    } on TimeoutException {
      throw const AuthFailure(
        AuthFailureCode.network,
        'Bağlantı zaman aşımına uğradı. Tekrar dene.',
      );
    }

    // The account no longer exists server-side, so signing out can legitimately
    // fail on an already-invalid token. The local session must go either way.
    try {
      await _client.auth.signOut();
    } on supabase.AuthException {
      // Ignored: the session it would have revoked is already gone.
    }
  }

  static AuthSession? _mapSession(supabase.Session? session) {
    if (session == null) return null;
    return AuthSession(userId: session.user.id, email: session.user.email);
  }

  static bool _looksLikeEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }

  static AuthFailure _mapFailure(supabase.AuthException error) {
    final message = error.message.toLowerCase();
    final statusCode = int.tryParse(error.statusCode ?? '');

    if (statusCode == 429 || message.contains('rate limit')) {
      return const AuthFailure(
        AuthFailureCode.rateLimited,
        'Çok sık deneme yapıldı. Geri sayım bitince tekrar dene.',
      );
    }
    if (message.contains('expired')) {
      return const AuthFailure(
        AuthFailureCode.expiredOtp,
        'Kodun süresi dolmuş. Yeni bir kod iste.',
      );
    }
    if (message.contains('token') || message.contains('otp')) {
      return const AuthFailure(
        AuthFailureCode.invalidOtp,
        'Kod geçersiz. Kontrol edip tekrar dene.',
      );
    }
    return const AuthFailure(
      AuthFailureCode.unknown,
      'İşlem tamamlanamadı. Lütfen tekrar dene.',
    );
  }
}
