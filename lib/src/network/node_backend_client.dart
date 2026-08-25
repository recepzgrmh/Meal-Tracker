import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Calls the Node backend that now serves analyze-meal, commit-meal and
/// search-food-catalog.
///
/// `supabase_flutter`'s `functions.invoke()` always targets the project's own
/// functions gateway and cannot be pointed at another host, so those three
/// routes need their own transport. This deliberately reproduces the gateway's
/// contract instead of inventing one: it returns a [FunctionResponse] and
/// throws a [FunctionException] carrying the decoded body as `details`, exactly
/// as `functions_client` does. That is what lets the call sites keep their
/// existing error mapping untouched — only the invoke call changes.
class NodeBackendClient {
  NodeBackendClient({
    required String baseUrl,
    required this.accessToken,
    http.Client? httpClient,
  }) : _baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       _httpClient = httpClient ?? http.Client();

  /// Supplies a currently-valid access token, refreshing if needed. Injected
  /// rather than reaching into a [SupabaseClient] so the transport can be
  /// tested without one — the same shape `supabase` uses for its own
  /// `AuthHttpClient`.
  final Future<String?> Function() accessToken;

  final String _baseUrl;
  final http.Client _httpClient;

  Future<FunctionResponse> invoke(
    String name, {
    Map<String, dynamic>? body,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    // The provider must refresh an expired session rather than hand one over.
    // The backend rejects an expired token with a non-retryable 401, and for
    // the outbox that turns a refreshable state into a permanently blocked
    // operation. When a refresh genuinely fails the provider throws
    // AuthException, which the call sites' catch-alls already map to a
    // retryable network failure — the same outcome as before this moved off
    // functions.invoke(). Letting it escape is deliberate.
    final token = await accessToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/$name'),
      headers: headers,
      body: jsonEncode(body ?? const <String, dynamic>{}),
    );

    final contentType = (response.headers['content-type'] ?? 'text/plain')
        .split(';')
        .first
        .trim();
    final dynamic data;
    if (contentType == 'application/json') {
      data = response.bodyBytes.isEmpty
          ? ''
          : jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      data = utf8.decode(response.bodyBytes);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return FunctionResponse(data: data, status: response.statusCode);
    }
    throw FunctionException(
      status: response.statusCode,
      details: data,
      reasonPhrase: response.reasonPhrase,
    );
  }
}
