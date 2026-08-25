import 'package:supabase_flutter/supabase_flutter.dart';

import '../../media/meal_photo_storage.dart';
import '../../network/node_backend_client.dart';

abstract interface class AnalysisRemoteDataSource {
  Future<Map<String, dynamic>> analyze({
    required String clientRequestId,
    required String input,
    required String inputKind,
    required String locale,
    StoredMealPhoto? photo,
  });
}

class AnalysisRemoteException implements Exception {
  const AnalysisRemoteException({
    required this.code,
    required this.status,
    required this.retryable,
    this.unmatchedTexts = const [],
  });

  final String code;
  final int status;
  final bool retryable;

  /// NO_MATCH details: the inputs the server could neither ground nor
  /// estimate, so the caller can name them instead of shrugging.
  final List<String> unmatchedTexts;
}

class NodeAnalysisRemoteDataSource implements AnalysisRemoteDataSource {
  const NodeAnalysisRemoteDataSource(this._backend);

  final NodeBackendClient _backend;

  @override
  Future<Map<String, dynamic>> analyze({
    required String clientRequestId,
    required String input,
    required String inputKind,
    required String locale,
    StoredMealPhoto? photo,
  }) async {
    try {
      final response = await _backend.invoke(
        'analyze-meal',
        body: {
          'clientRequestId': clientRequestId,
          'input': input,
          'inputKind': inputKind,
          'locale': locale,
          if (photo != null) 'photo': photo.toJson(),
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
        unmatchedTexts: _unmatchedTexts(errorBody['details']),
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

  /// NO_MATCH details carry `unmatchedItems: [{itemKey, text}]` (and a legacy
  /// `unmatchedText` string list). Anything malformed reads as "no names",
  /// never as a parse failure — this is an error path already.
  List<String> _unmatchedTexts(Object? details) {
    if (details is! Map) return const [];
    final items = details['unmatchedItems'];
    if (items is List) {
      final texts = [
        for (final item in items)
          if (item is Map && item['text'] is String) item['text'] as String,
      ];
      if (texts.isNotEmpty) return texts;
    }
    final legacy = details['unmatchedText'];
    if (legacy is List) {
      return [
        for (final text in legacy)
          if (text is String) text,
      ];
    }
    return const [];
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
