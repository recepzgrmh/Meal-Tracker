import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/bootstrap/app_bootstrap.dart';
import 'package:meal_clarity/src/bootstrap/app_config.dart';

void main() {
  const validConfig = AppConfig(
    environment: 'test',
    supabaseUrl: 'https://project-ref.supabase.co',
    supabasePublishableKey: 'sb_publishable_test-only',
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
      );

      expect(config.validationErrors(), hasLength(2));
      expect(config.validate, throwsA(isA<AppConfigException>()));
    });

    test('rejects secret keys', () {
      const config = AppConfig(
        environment: 'production',
        supabaseUrl: 'https://project-ref.supabase.co',
        supabasePublishableKey: 'sb_secret_do-not-ship',
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
