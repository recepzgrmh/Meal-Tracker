class AppConfig {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      environment: String.fromEnvironment(
        'APP_ENV',
        defaultValue: 'development',
      ),
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabasePublishableKey: String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
      ),
    );
  }

  final String environment;
  final String supabaseUrl;
  final String supabasePublishableKey;

  List<String> validationErrors() {
    final errors = <String>[];
    final uri = Uri.tryParse(supabaseUrl);

    if (uri == null ||
        uri.scheme != 'https' ||
        !uri.host.endsWith('.supabase.co')) {
      errors.add('SUPABASE_URL must be a valid HTTPS Supabase project URL.');
    }

    final normalizedKey = supabasePublishableKey.trim().toLowerCase();
    if (normalizedKey.isEmpty ||
        normalizedKey.contains('replace-with') ||
        normalizedKey.contains('your-')) {
      errors.add('SUPABASE_PUBLISHABLE_KEY is missing or still a placeholder.');
    }

    if (normalizedKey.startsWith('sb_secret_') ||
        normalizedKey.contains('service_role')) {
      errors.add('A secret/service-role key must never be shipped in the app.');
    }

    return errors;
  }

  void validate() {
    final errors = validationErrors();
    if (errors.isNotEmpty) throw AppConfigException(errors);
  }
}

class AppConfigException implements Exception {
  const AppConfigException(this.errors);

  final List<String> errors;

  @override
  String toString() => 'Invalid app configuration: ${errors.join(' ')}';
}
