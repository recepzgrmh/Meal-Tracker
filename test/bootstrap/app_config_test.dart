import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/bootstrap/app_bootstrap.dart';
import 'package:meal_clarity/src/bootstrap/app_config.dart';

void main() {
  const validConfig = AppConfig(
    environment: 'test',
    supabaseUrl: 'https://project-ref.supabase.co',
    supabasePublishableKey: 'sb_publishable_test-only',
    nodeBackendUrl: 'https://backend.example.com',
  );

  group('AppConfig', () {
    test('accepts a Supabase URL and publishable key', () {
      expect(validConfig.validationErrors(), isEmpty);
      expect(validConfig.validate, returnsNormally);
    });

    test('rejects placeholders and non-Supabase URLs', () {
      const config = AppConfig(
        environment: 'production',
        supabaseUrl: 'http://example.com',
        supabasePublishableKey: 'replace-with-your-publishable-key',
        nodeBackendUrl: 'http://backend.example.com',
      );

      // Three now: placeholder key, non-Supabase URL, and plain http on a
      // non-loopback backend host.
      expect(config.validationErrors(), hasLength(3));
      expect(config.validate, throwsA(isA<AppConfigException>()));
    });

    test('rejects secret keys', () {
      const config = AppConfig(
        environment: 'production',
        supabaseUrl: 'https://project-ref.supabase.co',
        supabasePublishableKey: 'sb_secret_do-not-ship',
        nodeBackendUrl: 'https://backend.example.com',
      );

      expect(
        config.validationErrors(),
        contains('A secret/service-role key must never be shipped in the app.'),
      );
    });
  });

  test('bootstrap validates before calling the provider initializer', () async {
    AppConfig? initializedWith;

    await AppBootstrap.initialize(
      validConfig,
      initializer: (config) async => initializedWith = config,
    );

    expect(initializedWith, same(validConfig));
  });
}
