import 'package:flutter/foundation.dart';

import '../data/onboarding_repository.dart';
import '../domain/onboarding_draft.dart';

/// Drives the pre-sign-in tour. The questions that shape the user's targets
/// are asked afterwards by [ProfileSetupViewModel]: nothing here is worth
/// making someone answer before they have seen what the app does.
class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel(this._repository);

  /// Bumped to 2 when the setup flow started collecting a body profile, so
  /// users who completed the old three-question version are asked again.
  static const currentVersion = 2;

  final OnboardingRepository _repository;

  OnboardingDraft _draft = const OnboardingDraft();
  bool _isLoading = true;

  OnboardingDraft get draft => _draft;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _draft = await _repository.loadDraft();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> goToStep(int step) async {
    _draft = _draft.copyWith(step: step.clamp(0, 3));
    notifyListeners();
    await _repository.saveDraft(_draft);
  }

  Future<void> finishDraft() => goToStep(3);

  /// Leaves onboarding for the sign-in screen without watching any of it.
  /// The returning user keeps an empty draft: nothing is written except the
  /// step the coordinator reads to decide where to route.
  Future<void> skipToSignIn() => goToStep(3);
}
