import 'package:shared_preferences/shared_preferences.dart';

import '../domain/onboarding_draft.dart';
import 'onboarding_repository.dart';

class SharedPreferencesOnboardingRepository implements OnboardingRepository {
  SharedPreferencesOnboardingRepository([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _stepKey = 'onboarding.step';
  static const _intentionKey = 'onboarding.intention';
  static const _calorieTargetKey = 'onboarding.calorie_target';
  static const _completedVersionKey = 'onboarding.completed_version';

  final SharedPreferencesAsync _preferences;

  @override
  Future<OnboardingDraft> loadDraft() async {
    final intentionName = await _preferences.getString(_intentionKey);
    return OnboardingDraft(
      step: await _preferences.getInt(_stepKey) ?? 0,
      intention: TrackingIntention.values
          .where((value) => value.name == intentionName)
          .firstOrNull,
      dailyCalorieTarget: await _preferences.getInt(_calorieTargetKey),
    );
  }

  @override
  Future<void> saveDraft(OnboardingDraft draft) async {
    await _preferences.setInt(_stepKey, draft.step);
    if (draft.intention case final intention?) {
      await _preferences.setString(_intentionKey, intention.name);
    } else {
      await _preferences.remove(_intentionKey);
    }
    if (draft.dailyCalorieTarget case final target?) {
      await _preferences.setInt(_calorieTargetKey, target);
    } else {
      await _preferences.remove(_calorieTargetKey);
    }
  }

  @override
  Future<int> completedVersion() async {
    return await _preferences.getInt(_completedVersionKey) ?? 0;
  }

  @override
  Future<void> markCompleted(int version) async {
    await _preferences.setInt(_completedVersionKey, version);
  }

  @override
  Future<void> restart() async {
    await _preferences.remove(_stepKey);
    await _preferences.remove(_intentionKey);
    await _preferences.remove(_calorieTargetKey);
    await _preferences.remove(_completedVersionKey);
  }
}
