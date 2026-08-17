import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/auth/data/supabase_auth_repository.dart';
import 'src/bootstrap/app_bootstrap.dart';
import 'src/bootstrap/app_config.dart';
import 'src/bootstrap/configuration_error_app.dart';
import 'src/bootstrap/meal_clarity_root.dart';
import 'src/onboarding/data/shared_preferences_onboarding_repository.dart';
import 'src/onboarding/data/supabase_profile_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();

  try {
    await AppBootstrap.initialize(config);
    final client = Supabase.instance.client;
    runApp(
      MealClarityRoot(
        authRepository: SupabaseAuthRepository(client),
        onboardingRepository: SharedPreferencesOnboardingRepository(),
        profileRepository: SupabaseProfileRepository(client),
      ),
    );
  } on AppConfigException catch (error) {
    runApp(ConfigurationErrorApp(errors: error.errors));
  }
}
