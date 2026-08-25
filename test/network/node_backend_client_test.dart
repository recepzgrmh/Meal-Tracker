import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meal_clarity/src/network/node_backend_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// These cover the transport itself — headers, token sourcing, and the
/// exception shape the three call sites' error mapping depends on. None of it
/// was exercised before, which is why a regression here (an expired token sent
/// as-is, producing a non-retryable 401) was invisible to the rest of the suite.
void main() {
  late List<http.Request> sent;

  MockClient respondWith(
    String body, {
    int status = 200,
    String contentType = 'application/json',
  }) {
    return MockClient((request) async {
      sent.add(request);
      return http.Response(
        body,
        status,
        headers: {'content-type': contentType},
        request: request,
      );
    });
  }

  NodeBackendClient clientWith(
    http.Client httpClient, {
    Future<String?> Function()? accessToken,
    String baseUrl = 'https://backend.example.com',
  }) {
    return NodeBackendClient(
      baseUrl: baseUrl,
      accessToken: accessToken ?? () async => 'token-abc',
      httpClient: httpClient,
    );
  }

  setUp(() => sent = []);

  test('posts JSON to the route and attaches the bearer token', () async {
    final backend = clientWith(respondWith('{"ok":true}'));

    final response = await backend.invoke(
      'analyze-meal',
      body: {'input': '2 yumurta'},
    );

    expect(response.status, 200);
    expect(response.data, {'ok': true});
    expect(sent, hasLength(1));
    expect(sent.single.method, 'POST');
    expect(
      sent.single.url.toString(),
      'https://backend.example.com/analyze-meal',
    );
    expect(sent.single.headers['Authorization'], 'Bearer token-abc');
    expect(jsonDecode(sent.single.body), {'input': '2 yumurta'});
  });

  test(
    'asks for a token on every call so a refreshed one is picked up',
    () async {
      var calls = 0;
      final backend = clientWith(
        respondWith('{}'),
        accessToken: () async => 'token-${++calls}',
      );

      await backend.invoke('commit-meal');
      await backend.invoke('commit-meal');

      expect(sent.map((request) => request.headers['Authorization']), [
        'Bearer token-1',
        'Bearer token-2',
      ]);
    },
  );

  test('omits the header when there is no session', () async {
    final backend = clientWith(
      respondWith('{}'),
      accessToken: () async => null,
    );

    await backend.invoke('search-food-catalog');

    expect(sent.single.headers.containsKey('Authorization'), isFalse);
  });

  test(
    'lets a failed token refresh escape rather than sending a stale one',
    () async {
      final backend = clientWith(
        respondWith('{}'),
        accessToken: () async => throw const AuthException('refresh failed'),
      );

      await expectLater(
        backend.invoke('commit-meal'),
        throwsA(isA<AuthException>()),
      );
      expect(
        sent,
        isEmpty,
        reason: 'no request may be sent without a valid token',
      );
    },
  );

  test('throws FunctionException carrying the decoded error envelope', () async {
    final backend = clientWith(
      respondWith(
        '{"error":{"code":"NO_MATCH","message":"yok","traceId":"t-1","retryable":false}}',
        status: 422,
      ),
    );

    await expectLater(
      backend.invoke('analyze-meal'),
      throwsA(
        isA<FunctionException>()
            .having((error) => error.status, 'status', 422)
            .having(
              (error) => (error.details as Map)['error']['code'],
              'error code',
              'NO_MATCH',
            ),
      ),
    );
  });

  test(
    'surfaces a non-JSON error body as a string instead of failing to parse',
    () async {
      // What a proxy returns on a 502 — the call sites treat a non-Map `details`
      // as "no structured error", so it must not blow up here first.
      final backend = clientWith(
        respondWith(
          '<html>bad gateway</html>',
          status: 502,
          contentType: 'text/html',
        ),
      );

      await expectLater(
        backend.invoke('analyze-meal'),
        throwsA(
          isA<FunctionException>()
              .having((error) => error.status, 'status', 502)
              .having((error) => error.details, 'details', isA<String>()),
        ),
      );
    },
  );

  test('normalises a trailing slash on the base URL', () async {
    final backend = clientWith(
      respondWith('{}'),
      baseUrl: 'https://backend.example.com/',
    );

    await backend.invoke('commit-meal');

    expect(
      sent.single.url.toString(),
      'https://backend.example.com/commit-meal',
    );
  });
}
