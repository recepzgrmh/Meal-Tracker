import 'package:shared_preferences/shared_preferences.dart';

import '../domain/body_profile.dart';
import '../domain/onboarding_draft.dart';
import 'onboarding_repository.dart';

class SharedPreferencesOnboardingRepository implements OnboardingRepository {
  SharedPreferencesOnboardingRepository([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _stepKey = 'onboarding.step';
  static const _intentionKey = 'onboarding.intention';
  static const _calorieTargetKey = 'onboarding.calorie_target';
  static const _completedVersionKey = 'onboarding.completed_version';
  static const _sexKey = 'onboarding.sex';
  static const _birthYearKey = 'onboarding.birth_year';
  static const _heightKey = 'onboarding.height_cm';
  static const _weightKey = 'onboarding.weight_kg';
  static const _targetWeightKey = 'onboarding.target_weight_kg';
  static const _activityKey = 'onboarding.activity';
  static const _goalKey = 'onboarding.goal';
  static const _paceKey = 'onboarding.pace';
  static const _dietKey = 'onboarding.diet';
  static const _unitsKey = 'onboarding.units';

  /// Every key this repository owns, so [restart] cannot fall behind the list
  /// as fields are added.
  static const _bodyKeys = <String>[
    _sexKey,
    _birthYearKey,
    _heightKey,
    _weightKey,
    _targetWeightKey,
    _activityKey,
    _goalKey,
    _paceKey,
    _dietKey,
    _unitsKey,
  ];

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
      body: BodyProfile(
        sex: BiologicalSex.fromWire(await _preferences.getString(_sexKey)),
        birthYear: await _preferences.getInt(_birthYearKey),
        heightCm: await _preferences.getDouble(_heightKey),
        weightKg: await _preferences.getDouble(_weightKey),
        targetWeightKg: await _preferences.getDouble(_targetWeightKey),
        activityLevel: ActivityLevel.fromWire(
          await _preferences.getString(_activityKey),
        ),
        goal: WeightGoal.fromWire(await _preferences.getString(_goalKey)),
        pace:
            GoalPace.fromWire(await _preferences.getString(_paceKey)) ??
            GoalPace.steady,
        dietPattern: DietPattern.fromWire(
          await _preferences.getString(_dietKey),
        ),
        measurementSystem:
            MeasurementSystem.fromWire(
              await _preferences.getString(_unitsKey),
            ) ??
            MeasurementSystem.metric,
      ),
    );
  }

  @override
  Future<void> saveDraft(OnboardingDraft draft) async {
    await _preferences.setInt(_stepKey, draft.step);
    await _writeString(_intentionKey, draft.intention?.name);
    await _writeInt(_calorieTargetKey, draft.dailyCalorieTarget);

    final body = draft.body;
    await _writeString(_sexKey, body.sex?.wire);
    await _writeInt(_birthYearKey, body.birthYear);
    await _writeDouble(_heightKey, body.heightCm);
    await _writeDouble(_weightKey, body.weightKg);
    await _writeDouble(_targetWeightKey, body.targetWeightKg);
    await _writeString(_activityKey, body.activityLevel?.wire);
    await _writeString(_goalKey, body.goal?.wire);
    await _writeString(_paceKey, body.pace.wire);
    await _writeString(_dietKey, body.dietPattern?.wire);
    await _writeString(_unitsKey, body.measurementSystem.wire);
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
    for (final key in _bodyKeys) {
      await _preferences.remove(key);
    }
  }

  Future<void> _writeString(String key, String? value) => value == null
      ? _preferences.remove(key)
      : _preferences.setString(key, value);

  Future<void> _writeInt(String key, int? value) => value == null
      ? _preferences.remove(key)
      : _preferences.setInt(key, value);

  Future<void> _writeDouble(String key, double? value) => value == null
      ? _preferences.remove(key)
      : _preferences.setDouble(key, value);
}
