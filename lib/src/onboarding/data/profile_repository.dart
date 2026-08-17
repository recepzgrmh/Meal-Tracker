import '../domain/onboarding_draft.dart';

abstract interface class ProfileRepository {
  Future<void> completeOnboarding({
    required String userId,
    required OnboardingDraft draft,
    required int version,
  });
}
