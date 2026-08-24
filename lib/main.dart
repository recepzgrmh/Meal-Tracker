import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'src/analysis/data/analysis_remote_data_source.dart';
import 'src/analysis/data/supabase_meal_analysis_repository.dart';
import 'src/auth/data/supabase_auth_repository.dart';
import 'src/bootstrap/app_bootstrap.dart';
import 'src/bootstrap/app_config.dart';
import 'src/bootstrap/configuration_error_app.dart';
import 'src/bootstrap/meal_clarity_root.dart';
import 'src/catalog/food_catalog_repository.dart';
import 'src/local/app_database.dart';
import 'src/local/meal_dao.dart';
import 'src/localization/ota_translation_repository.dart';
import 'src/local/outbox_dao.dart';
import 'src/meals/data/cached_meal_repository.dart';
import 'src/meals/data/supabase_meal_remote_data_source.dart';
import 'src/media/meal_photo_storage.dart';
import 'src/onboarding/data/shared_preferences_onboarding_repository.dart';
import 'src/onboarding/data/supabase_profile_repository.dart';
import 'src/sync/outbox_worker.dart';
import 'src/sync/supabase_mutation_gateway.dart';

void main() {
  runZonedGuarded(_startApplication, _reportUnhandledError);
}

bool _crashlyticsReady = false;

Future<void> _startApplication() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _crashlyticsReady = true;
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(FirebaseCrashlytics.instance.recordFlutterFatalError(details));
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    _reportUnhandledError(error, stackTrace);
    return true;
  };

  final config = AppConfig.fromEnvironment();

  try {
    await AppBootstrap.initialize(config);
    final client = Supabase.instance.client;
    final database = AppDatabase.defaults();
    final mealDao = MealDao(database);
    final outboxDao = OutboxDao(database);
    runApp(
      MealClarityRoot(
        authRepository: SupabaseAuthRepository(client),
        onboardingRepository: SharedPreferencesOnboardingRepository(),
        profileRepository: SupabaseProfileRepository(client),
        analysisRepository: SupabaseMealAnalysisRepository(
          remote: SupabaseAnalysisRemoteDataSource(client),
          photoStorage: SupabaseMealPhotoStorage(client),
        ),
        catalogRepository: SupabaseFoodCatalogRepository(client),
        mealRepository: CachedMealRepository(
          local: mealDao,
          remote: SupabaseMealRemoteDataSource(client),
        ),
        outboxWorker: OutboxWorker(
          outbox: outboxDao,
          gateway: SupabaseMutationGateway(client),
        ),
        outboxDao: outboxDao,
        ownedDatabase: database,
        translationRepository: SupabaseOtaTranslationRepository(client),
      ),
    );
  } on AppConfigException catch (error) {
    runApp(ConfigurationErrorApp(errors: error.errors));
  }
}

void _reportUnhandledError(Object error, StackTrace stackTrace) {
  FlutterError.presentError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'meal_clarity',
      context: ErrorDescription('while running the application'),
    ),
  );
  if (_crashlyticsReady) {
    unawaited(
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true),
    );
  }
}
