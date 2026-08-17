import 'package:flutter/foundation.dart';

import '../data/onboarding_repository.dart';
import '../domain/onboarding_draft.dart';

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
    _draft = _draft.copyWith(step: step.clamp(0, 2));
    notifyListeners();
    await _repository.saveDraft(_draft);
  }

  Future<void> selectIntention(TrackingIntention intention) async {
    _draft = _draft.copyWith(
      intention: intention,
      clearCalorieTarget: intention != TrackingIntention.calories,
    );
    notifyListeners();
    await _repository.saveDraft(_draft);
  }

  String? validateCalorieTarget(String rawValue) {
    if (_draft.intention != TrackingIntention.calories ||
        rawValue.trim().isEmpty) {
      return null;
    }
    final value = int.tryParse(rawValue.trim());
    if (value == null || value < 500 || value > 10000) {
      return '500–10.000 kcal arasında bir değer gir veya alanı boş bırak.';
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
