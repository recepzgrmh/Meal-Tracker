import '../domain/onboarding_draft.dart';

abstract interface class OnboardingRepository {
  Future<OnboardingDraft> loadDraft();

  Future<void> saveDraft(OnboardingDraft draft);

  Future<int> completedVersion();

  Future<void> markCompleted(int version);

  Future<void> restart();
}
