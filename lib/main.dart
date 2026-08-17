import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/bootstrap/app_bootstrap.dart';
import 'src/bootstrap/app_config.dart';
import 'src/bootstrap/configuration_error_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();

  try {
    await AppBootstrap.initialize(config);
    runApp(const MealClarityApp());
  } on AppConfigException catch (error) {
    runApp(ConfigurationErrorApp(errors: error.errors));
  }
}
