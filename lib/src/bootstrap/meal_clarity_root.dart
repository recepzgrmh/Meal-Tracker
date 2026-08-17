import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../auth/data/auth_repository.dart';
import '../auth/presentation/auth_screen.dart';
import '../auth/presentation/auth_view_model.dart';
import '../onboarding/data/onboarding_repository.dart';
import '../onboarding/data/profile_repository.dart';
import '../onboarding/presentation/onboarding_screen.dart';
import '../onboarding/presentation/onboarding_view_model.dart';
import '../onboarding/presentation/profile_completion_screen.dart';
import '../theme/app_theme.dart';
import 'app_coordinator.dart';

class MealClarityRoot extends StatefulWidget {
  const MealClarityRoot({
    required this.authRepository,
    required this.onboardingRepository,
    required this.profileRepository,
    super.key,
  });

  final AuthRepository authRepository;
  final OnboardingRepository onboardingRepository;
  final ProfileRepository profileRepository;

  @override
  State<MealClarityRoot> createState() => _MealClarityRootState();
}

class _MealClarityRootState extends State<MealClarityRoot> {
  late final AppCoordinator _coordinator;
  late final OnboardingViewModel _onboardingViewModel;
  late final AuthViewModel _authViewModel;
  late final GoRouter _router;

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
        GoRoute(path: '/app', builder: (_, _) => const MealClarityShell()),
      ],
    );
    _coordinator.initialize();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Meal Clarity',
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
