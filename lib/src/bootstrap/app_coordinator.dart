import 'dart:async';

import 'package:flutter/foundation.dart';

import '../auth/data/auth_repository.dart';
import '../auth/domain/auth_session.dart';
import '../onboarding/data/onboarding_repository.dart';
import '../onboarding/data/profile_repository.dart';
import '../onboarding/domain/onboarding_draft.dart';
import '../onboarding/presentation/onboarding_view_model.dart';

enum AppFlowState { booting, onboarding, authentication, profile, ready }

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
  String? _profileError;

  AuthSession? get session => _session;
  OnboardingDraft get draft => _draft;
  bool get isCompletingProfile => _isCompletingProfile;
  String? get profileError => _profileError;

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
      _profileError =
          'Tercihler kaydedilemedi. Bağlantını kontrol edip tekrar dene.';
      return false;
    } finally {
      _isCompletingProfile = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
