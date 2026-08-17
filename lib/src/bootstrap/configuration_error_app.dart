import 'package:flutter/material.dart';

class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({required this.errors, super.key});

  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.settings_suggest_outlined, size: 44),
                const SizedBox(height: 20),
                Text(
                  'Uygulama yapılandırması eksik',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'config/app_config.example.json dosyasını kopyalayıp '
                  'gerçek publishable key ile çalıştır.',
                ),
                const SizedBox(height: 16),
                for (final error in errors)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• $error'),
                  ),
                const SizedBox(height: 8),
                const SelectableText(
                  'flutter run --dart-define-from-file=config/app_config.dev.json',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
