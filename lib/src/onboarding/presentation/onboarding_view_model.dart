import 'package:flutter/foundation.dart';

import '../data/onboarding_repository.dart';
import '../domain/onboarding_draft.dart';

/// Why a calorie target was rejected. The view model deliberately does not
/// carry a message: the copy belongs to the UI layer, which localises it once.
enum CalorieTargetError { outOfRange }

class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel(this._repository);

  static const currentVersion = 1;

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

  /// Leaves onboarding for the sign-in screen without answering any of it.
  /// The returning user keeps an empty draft: nothing is written except the
  /// step the coordinator reads to decide where to route.
  Future<void> skipToSignIn() => goToStep(3);

  Future<void> selectIntention(TrackingIntention intention) async {
    _draft = _draft.copyWith(
      intention: intention,
      clearCalorieTarget: intention != TrackingIntention.calories,
    );
    notifyListeners();
    await _repository.saveDraft(_draft);
  }

  CalorieTargetError? validateCalorieTarget(String rawValue) {
    if (_draft.intention != TrackingIntention.calories ||
        rawValue.trim().isEmpty) {
      return null;
    }
    final value = int.tryParse(rawValue.trim());
    if (value == null || value < 500 || value > 10000) {
      return CalorieTargetError.outOfRange;
    }
    return null;
  }

  Future<void> setCalorieTarget(String rawValue) async {
    final target = rawValue.trim().isEmpty ? null : int.parse(rawValue.trim());
    _draft = _draft.copyWith(
      dailyCalorieTarget: target,
      clearCalorieTarget: target == null,
    );
    notifyListeners();
    await _repository.saveDraft(_draft);
  }
}
