import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

typedef SupabaseInitializer = Future<void> Function(AppConfig config);

class AppBootstrap {
  const AppBootstrap._();

  static Future<void> initialize(
    AppConfig config, {
    SupabaseInitializer initializer = _initializeSupabase,
  }) async {
    config.validate();
    await initializer(config);
  }

  static Future<void> _initializeSupabase(AppConfig config) async {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
    );
  }
}
