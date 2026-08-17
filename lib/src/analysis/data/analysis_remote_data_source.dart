import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AnalysisRemoteDataSource {
  Future<Map<String, dynamic>> analyze({
    required String clientRequestId,
    required String input,
  });
}

class AnalysisRemoteException implements Exception {
  const AnalysisRemoteException({
    required this.code,
    required this.status,
    required this.retryable,
  });

  final String code;
  final int status;
  final bool retryable;
}

class SupabaseAnalysisRemoteDataSource implements AnalysisRemoteDataSource {
  const SupabaseAnalysisRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> analyze({
    required String clientRequestId,
    required String input,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'analyze-meal',
        body: {
          'clientRequestId': clientRequestId,
          'input': input,
          'inputKind': 'text',
          'locale': 'tr-TR',
        },
      );
      final data = response.data;
      if (data is! Map) {
        throw const AnalysisRemoteException(
          code: 'INVALID_RESPONSE',
          status: 502,
          retryable: true,
        );
      }
      return data.map((key, value) => MapEntry(key.toString(), value));
    } on FunctionException catch (error) {
      final details = error.details;
      final envelope = details is Map ? details['error'] : null;
      final errorBody = envelope is Map ? envelope : const {};
      throw AnalysisRemoteException(
        code: errorBody['code']?.toString() ?? _fallbackCode(error.status),
        status: error.status,
        retryable: errorBody['retryable'] == true || error.status >= 500,
      );
    } on AnalysisRemoteException {
      rethrow;
    } catch (_) {
      throw const AnalysisRemoteException(
        code: 'NETWORK_UNAVAILABLE',
        status: 0,
        retryable: true,
      );
    }
  }

  String _fallbackCode(int status) {
    return switch (status) {
      401 => 'UNAUTHENTICATED',
      429 => 'RATE_LIMITED',
      >= 500 => 'FUNCTION_UNAVAILABLE',
      _ => 'FUNCTION_ERROR',
    };
  }
}
