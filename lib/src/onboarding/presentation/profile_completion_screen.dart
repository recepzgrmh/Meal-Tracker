import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../bootstrap/app_coordinator.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({required this.coordinator, super.key});

  final AppCoordinator coordinator;

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.coordinator.completeProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.coordinator,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.coordinator.profileError == null) ...[
                        const CircularProgressIndicator(),
                        const SizedBox(height: 22),
                        Text(
                          context.ota(
                            'profileSavingPreferences',
                            tr: 'Başlangıç tercihlerin kaydediliyor…',
                            en: 'Saving your initial preferences…',
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        const Icon(Icons.cloud_off_outlined, size: 48),
                        const SizedBox(height: 18),
                        Text(
                          context.ota(
                            'profileSaveError',
                            tr: 'Tercihler kaydedilemedi. Bağlantını kontrol edip tekrar dene.',
                            en: 'Preferences could not be saved. Check your connection and try again.',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: widget.coordinator.isCompletingProfile
                              ? null
                              : widget.coordinator.completeProfile,
                          child: Text(
                            context.ota(
                              'commonRetry',
                              tr: 'Tekrar dene',
                              en: 'Try again',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
