class AppConfig {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.nodeBackendUrl,
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
      nodeBackendUrl: String.fromEnvironment('NODE_BACKEND_URL'),
    );
  }

  final String environment;
  final String supabaseUrl;
  final String supabasePublishableKey;

  /// Host of the Node backend serving analyze-meal, commit-meal and
  /// search-food-catalog. Auth, storage and direct Postgres reads still go to
  /// [supabaseUrl].
  final String nodeBackendUrl;

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

    // Plain http is tolerated only for a development host, so a device build
    // can never be pointed at an unencrypted backend by accident. 10.0.2.2 is
    // how the Android emulator reaches a server on the host machine, so it
    // belongs here alongside loopback or the emulator could not be used.
    final backendUri = Uri.tryParse(nodeBackendUrl);
    const devHosts = {'localhost', '127.0.0.1', '10.0.2.2'};
    final isDevHost = backendUri != null && devHosts.contains(backendUri.host);
    if (backendUri == null ||
        !backendUri.hasScheme ||
        backendUri.host.isEmpty ||
        (backendUri.scheme != 'https' &&
            !(backendUri.scheme == 'http' && isDevHost))) {
      errors.add(
        'NODE_BACKEND_URL must be an HTTPS URL '
        '(http allowed only for localhost, 127.0.0.1 or 10.0.2.2).',
      );
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
