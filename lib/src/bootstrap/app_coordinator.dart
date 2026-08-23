import 'dart:async';

import 'package:flutter/foundation.dart';

import '../auth/data/auth_repository.dart';
import '../auth/domain/auth_session.dart';
import '../domain/nutrition_goals.dart';
import '../onboarding/data/onboarding_repository.dart';
import '../onboarding/data/profile_repository.dart';
import '../onboarding/domain/onboarding_draft.dart';
import '../onboarding/presentation/onboarding_view_model.dart';

enum AppFlowState { booting, onboarding, authentication, profile, ready }

/// Why profile completion failed. The coordinator deliberately does not carry a
/// message: the copy belongs to the UI layer, which localises it.
enum ProfileCompletionError { saveFailed }

class AppCoordinator extends ChangeNotifier {
  AppCoordinator({
    required AuthRepository authRepository,
    required OnboardingRepository onboardingRepository,
    required ProfileRepository profileRepository,
  }) : _authRepository = authRepository,
       _onboardingRepository = onboardingRepository,
       _profileRepository = profileRepository;

  final AuthRepository _authRepository;
  final OnboardingRepository _onboardingRepository;
  final ProfileRepository _profileRepository;

  StreamSubscription<AuthSession?>? _authSubscription;
  AuthSession? _session;
  OnboardingDraft _draft = const OnboardingDraft();
  int _completedVersion = 0;
  bool _initialized = false;
  bool _isCompletingProfile = false;
  ProfileCompletionError? _profileError;

  AuthSession? get session => _session;
  OnboardingDraft get draft => _draft;
  bool get isCompletingProfile => _isCompletingProfile;
  ProfileCompletionError? get profileError => _profileError;

  /// Daily targets derived from the body profile the user answered during
  /// setup, or the app default while that is still unanswered.
  NutritionGoals get goals => NutritionGoals.fromPlan(_draft.plan);

  AppFlowState get state {
    if (!_initialized) return AppFlowState.booting;
    if (_completedVersion >= OnboardingViewModel.currentVersion) {
      return _session == null
          ? AppFlowState.authentication
          : AppFlowState.ready;
    }
    if (_draft.step < 3) return AppFlowState.onboarding;
    return _session == null
        ? AppFlowState.authentication
        : AppFlowState.profile;
  }

  Future<void> initialize() async {
    _session = _authRepository.currentSession;
    _draft = await _onboardingRepository.loadDraft();
    _completedVersion = await _onboardingRepository.completedVersion();
    _authSubscription = _authRepository.sessionChanges.listen((session) {
      _session = session;
      notifyListeners();
    });
    _initialized = true;
    notifyListeners();
  }

  Future<void> refreshOnboarding() async {
    _draft = await _onboardingRepository.loadDraft();
    notifyListeners();
  }

  Future<bool> completeProfile() async {
    final session = _session;
    if (session == null || _isCompletingProfile) return false;
    _isCompletingProfile = true;
    _profileError = null;
    notifyListeners();
    try {
      await _profileRepository.completeOnboarding(
        userId: session.userId,
        draft: _draft,
        version: OnboardingViewModel.currentVersion,
      );
      await _onboardingRepository.markCompleted(
        OnboardingViewModel.currentVersion,
      );
      _completedVersion = OnboardingViewModel.currentVersion;
      return true;
    } catch (_) {
      _profileError = ProfileCompletionError.saveFailed;
      return false;
    } finally {
      _isCompletingProfile = false;
      notifyListeners();
    }
  }

  /// Sends the user back through setup with their previous answers intact, so
  /// a target can be revised without starting from an empty profile. Only the
  /// in-memory completion marker is cleared: an interrupted edit leaves the
  /// stored profile exactly as it was.
  void reopenSetup() {
    _completedVersion = 0;
    _profileError = null;
    notifyListeners();
  }

  /// Ends the session. The `sessionChanges` subscription drives the redirect,
  /// so nothing is mutated here; failures propagate for the caller to surface.
  Future<void> signOut() => _authRepository.signOut();

  /// Permanently deletes the account, then clears the locally stored onboarding
  /// answers so a fresh sign-up does not inherit the deleted user's targets.
  Future<void> deleteAccount() async {
    await _authRepository.deleteAccount();
    await _onboardingRepository.restart();
    _draft = const OnboardingDraft();
    _completedVersion = 0;
    _session = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
