import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    this.localePreference,
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

  /// Injectable so tests can drive the language override without touching
  /// platform preferences.
  final LocalePreference? localePreference;

  @override
  State<MealClarityRoot> createState() => _MealClarityRootState();
}

class _MealClarityRootState extends State<MealClarityRoot> {
  late final AppCoordinator _coordinator;
  late final OnboardingViewModel _onboardingViewModel;
  late final AuthViewModel _authViewModel;
  late final LocalePreference _localePreference;
  late final GoRouter _router;
  bool _isDrainingOutbox = false;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _localePreference = widget.localePreference ?? LocalePreference();
    unawaited(_restoreLocale());
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
            goals: _coordinator.goals,
            locale: _locale,
            onLocaleChanged: _changeLocale,
            onSignOut: _signOut,
            onDeleteAccount: _deleteAccount,
          ),
        ),
      ],
    );
    _coordinator.initialize();
  }

  // A preference store that is unavailable must not take the app down with it;
  // the device language is a safe answer in that case.
  Future<void> _restoreLocale() async {
    Locale? stored;
    try {
      stored = await _localePreference.load();
    } catch (_) {
      return;
    }
    if (!mounted || stored == null) return;
    setState(() => _locale = stored);
  }

  void _changeLocale(Locale? locale) {
    setState(() => _locale = locale);
    unawaited(_localePreference.save(locale).catchError((_) {}));
  }

  /// Leaving the account must not leave its meals cached on the device — this
  /// is the same phone the next person may sign in on.
  Future<void> _signOut() async {
    final userId = _coordinator.session?.userId;
    await _coordinator.signOut();
    await _clearLocalCache(userId);
  }

  /// The account is gone once this returns `true`; the coordinator's session
  /// stream then drives the router back to `/auth`.
  Future<bool> _deleteAccount() async {
    final userId = _coordinator.session?.userId;
    try {
      await _coordinator.deleteAccount();
    } catch (_) {
      return false;
    }
    // Deliberately after the server delete succeeded: wiping the local copy
    // first would destroy meals that are still only queued in the outbox if
    // the remote call then failed.
    await _clearLocalCache(userId);
    return true;
  }

  Future<void> _clearLocalCache(String? userId) async {
    final repository = widget.mealRepository;
    if (repository == null || userId == null) return;
    try {
      await repository.clearUser(userId);
    } catch (_) {
      // The session is already over; a cache that refuses to drop must not
      // strand the user on a screen they no longer have an account for.
    }
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
      locale: _locale,
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

/// Persists the language override the user picked in Profile. Stored the same
/// way as the onboarding draft so both survive a cold start identically; a
/// missing entry means "follow the device".
class LocalePreference {
  LocalePreference([this._injected]);

  static const _localeKey = 'settings.locale';

  final SharedPreferencesAsync? _injected;

  // Built on demand rather than in the constructor so a host without the
  // shared_preferences platform binding (widget tests) can still mount the app.
  SharedPreferencesAsync get _preferences =>
      _injected ?? SharedPreferencesAsync();

  Future<Locale?> load() async {
    final code = await _preferences.getString(_localeKey);
    if (code == null) return null;
    return AppLocalizations.supportedLocales
        .where((locale) => locale.languageCode == code)
        .firstOrNull;
  }

  Future<void> save(Locale? locale) async {
    if (locale == null) {
      await _preferences.remove(_localeKey);
      return;
    }
    await _preferences.setString(_localeKey, locale.languageCode);
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: Center(child: CircularProgressIndicator())),
    );
  }
}
