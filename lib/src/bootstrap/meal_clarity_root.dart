import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';

import '../app.dart';
import '../data/meal_repository.dart';
import '../catalog/food_catalog_repository.dart';
import '../auth/data/auth_repository.dart';
import '../auth/presentation/auth_screen.dart';
import '../auth/presentation/auth_view_model.dart';
import '../local/app_database.dart';
import '../localization/ota_localizations.dart';
import '../localization/ota_translation_repository.dart';
import '../meals/data/cached_meal_repository.dart';
import '../onboarding/data/onboarding_repository.dart';
import '../onboarding/data/profile_repository.dart';
import '../onboarding/presentation/onboarding_screen.dart';
import '../onboarding/presentation/onboarding_view_model.dart';
import '../onboarding/presentation/profile_completion_screen.dart';
import '../theme/app_theme.dart';
import '../sync/outbox_worker.dart';
import 'app_coordinator.dart';

class MealClarityRoot extends StatefulWidget {
  const MealClarityRoot({
    required this.authRepository,
    required this.onboardingRepository,
    required this.profileRepository,
    this.mealRepository,
    this.analysisRepository,
    this.catalogRepository,
    this.outboxWorker,
    this.ownedDatabase,
    this.translationRepository = const BundledOnlyTranslationRepository(),
    super.key,
  });

  final AuthRepository authRepository;
  final OnboardingRepository onboardingRepository;
  final ProfileRepository profileRepository;
  final CachedMealRepository? mealRepository;
  final MealRepository? analysisRepository;
  final FoodCatalogRepository? catalogRepository;
  final OutboxWorker? outboxWorker;
  final AppDatabase? ownedDatabase;
  final OtaTranslationRepository translationRepository;

  @override
  State<MealClarityRoot> createState() => _MealClarityRootState();
}

class _MealClarityRootState extends State<MealClarityRoot> {
  late final AppCoordinator _coordinator;
  late final OnboardingViewModel _onboardingViewModel;
  late final AuthViewModel _authViewModel;
  late final GoRouter _router;
  bool _isDrainingOutbox = false;

  @override
  void initState() {
    super.initState();
    _coordinator = AppCoordinator(
      authRepository: widget.authRepository,
      onboardingRepository: widget.onboardingRepository,
      profileRepository: widget.profileRepository,
    );
    _onboardingViewModel = OnboardingViewModel(widget.onboardingRepository);
    _authViewModel = AuthViewModel(widget.authRepository);
    _router = GoRouter(
      initialLocation: '/boot',
      refreshListenable: _coordinator,
      redirect: _redirect,
      routes: [
        GoRoute(path: '/boot', builder: (_, _) => const _BootScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (_, _) => OnboardingScreen(
            viewModel: _onboardingViewModel,
            onDraftChanged: _coordinator.refreshOnboarding,
          ),
        ),
        GoRoute(
          path: '/auth',
          builder: (_, _) => AuthScreen(
            viewModel: _authViewModel,
            onAuthenticated: _coordinator.completeProfile,
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, _) => ProfileCompletionScreen(coordinator: _coordinator),
        ),
        GoRoute(
          path: '/app',
          builder: (_, _) => MealClarityShell(
            cachedRepository: widget.mealRepository,
            analysisRepository: widget.analysisRepository,
            catalogRepository: widget.catalogRepository,
            userId: _coordinator.session?.userId,
            onSyncRequested: widget.outboxWorker == null ? null : _drainOutbox,
          ),
        ),
      ],
    );
    _coordinator.initialize();
  }

  Future<void> _drainOutbox() async {
    final worker = widget.outboxWorker;
    final userId = _coordinator.session?.userId;
    if (worker == null || userId == null || _isDrainingOutbox) return;
    _isDrainingOutbox = true;
    try {
      await worker.recoverInterrupted(userId);
      for (var index = 0; index < 20; index++) {
        final result = await worker.runOnce(userId);
        if (result.outcome != SyncRunOutcome.succeeded) break;
      }
    } finally {
      _isDrainingOutbox = false;
    }
  }

  String? _redirect(BuildContext context, GoRouterState routerState) {
    final target = switch (_coordinator.state) {
      AppFlowState.booting => '/boot',
      AppFlowState.onboarding => '/onboarding',
      AppFlowState.authentication => '/auth',
      AppFlowState.profile => '/profile',
      AppFlowState.ready => '/app',
    };
    return routerState.matchedLocation == target ? null : target;
  }

  @override
  void dispose() {
    _router.dispose();
    _authViewModel.dispose();
    _onboardingViewModel.dispose();
    _coordinator.dispose();
    unawaited(widget.ownedDatabase?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: [
        OtaLocalizationsDelegate(widget.translationRepository),
        ...AppLocalizations.localizationsDelegates.skip(1),
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildTheme(),
      routerConfig: _router,
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
