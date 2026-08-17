enum TrackingIntention { understand, protein, calories }

class OnboardingDraft {
  const OnboardingDraft({
    this.step = 0,
    this.intention,
    this.dailyCalorieTarget,
  });

  final int step;
  final TrackingIntention? intention;
  final int? dailyCalorieTarget;

  OnboardingDraft copyWith({
    int? step,
    TrackingIntention? intention,
    int? dailyCalorieTarget,
    bool clearCalorieTarget = false,
  }) {
    return OnboardingDraft(
      step: step ?? this.step,
      intention: intention ?? this.intention,
      dailyCalorieTarget: clearCalorieTarget
          ? null
          : dailyCalorieTarget ?? this.dailyCalorieTarget,
    );
  }
}
