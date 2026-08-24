import 'package:flutter/foundation.dart';

import '../data/onboarding_repository.dart';
import '../domain/body_profile.dart';
import '../domain/calorie_calculator.dart';
import '../domain/nutrition_plan.dart';
import '../domain/onboarding_draft.dart';
import '../domain/unit_conversion.dart';

/// Why a typed number was rejected. Like [CalorieTargetError] these carry no
/// message: the copy belongs to the UI layer, which localises it once.
enum NumericFieldError { missing, malformed, outOfRange }

/// Why a calorie override was rejected.
enum CalorieTargetError { outOfRange }

/// Drives the post-sign-in setup flow: the questions the calorie engine needs,
/// the live estimate, and the manual override.
///
/// Text edits are held in memory and flushed to the repository on step
/// changes rather than on every keystroke; discrete choices persist
/// immediately, because those are the answers a user would be annoyed to
/// retype after a crash.
class ProfileSetupViewModel extends ChangeNotifier {
  ProfileSetupViewModel(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Question steps. The saving phase that follows is not one of them.
  static const stepCount = 7;

  static const sexAndAgeStep = 0;
  static const bodyStep = 1;
  static const activityStep = 2;
  static const goalStep = 3;
  static const dietStep = 4;
  static const intentionStep = 5;
  static const summaryStep = 6;

  final OnboardingRepository _repository;
  final DateTime Function() _clock;

  OnboardingDraft _draft = const OnboardingDraft();
  int _step = 0;
  bool _isLoading = true;

  NumericFieldError? _ageError;
  NumericFieldError? _heightError;
  NumericFieldError? _weightError;
  NumericFieldError? _targetWeightError;

  OnboardingDraft get draft => _draft;
  BodyProfile get body => _draft.body;
  NutritionPlan? get plan => _draft.plan;
  int get step => _step;
  bool get isLoading => _isLoading;

  NumericFieldError? get ageError => _ageError;
  NumericFieldError? get heightError => _heightError;
  NumericFieldError? get weightError => _weightError;
  NumericFieldError? get targetWeightError => _targetWeightError;

  bool get isImperial => body.measurementSystem == MeasurementSystem.imperial;

  Future<void> initialize() async {
    _draft = await _repository.loadDraft();
    _isLoading = false;
    notifyListeners();
  }

  /// True once the current step holds a usable answer. The flow never blocks
  /// on a question it can answer itself — only on ones it cannot.
  bool get canAdvance => switch (_step) {
    sexAndAgeStep => body.sex != null && _ageIsValid,
    bodyStep =>
      body.heightCm != null &&
          body.weightKg != null &&
          _heightError == null &&
          _weightError == null,
    activityStep => body.activityLevel != null,
    goalStep => body.goal != null && _targetWeightError == null,
    dietStep => body.dietPattern != null,
    intentionStep => _draft.intention != null,
    _ => true,
  };

  bool get _ageIsValid {
    final age = body.ageAt(_clock());
    return _ageError == null &&
        age != null &&
        age >= BodyProfile.minAge &&
        age <= BodyProfile.maxAge;
  }

  Future<void> goTo(int step) async {
    _step = step.clamp(0, stepCount - 1);
    notifyListeners();
    await _repository.saveDraft(_draft);
  }

  Future<void> next() => goTo(_step + 1);

  Future<void> back() => goTo(_step - 1);

  // --- discrete answers, persisted immediately -----------------------------

  Future<void> selectSex(BiologicalSex value) =>
      _applyBody(body.copyWith(sex: value));

  Future<void> selectActivity(ActivityLevel value) =>
      _applyBody(body.copyWith(activityLevel: value));

  Future<void> selectPace(GoalPace value) =>
      _applyBody(body.copyWith(pace: value));

  Future<void> selectDiet(DietPattern value) =>
      _applyBody(body.copyWith(dietPattern: value));

  /// Choosing to maintain drops any target weight: it would only contradict
  /// the goal on the summary screen.
  Future<void> selectGoal(WeightGoal value) {
    return _applyBody(
      body.copyWith(
        goal: value,
        clearTargetWeight: value == WeightGoal.maintain,
      ),
    );
  }

  Future<void> selectIntention(TrackingIntention value) async {
    _draft = _draft.copyWith(intention: value);
    notifyListeners();
    await _repository.saveDraft(_draft);
  }

  /// Switching units never changes the stored body: only how it is shown.
  Future<void> selectMeasurementSystem(MeasurementSystem value) =>
      _applyBody(body.copyWith(measurementSystem: value));

  // --- typed answers, held until the step changes --------------------------

  void updateAge(String raw) {
    final (:value, :error) = _parse(
      raw,
      min: BodyProfile.minAge.toDouble(),
      max: BodyProfile.maxAge.toDouble(),
    );
    _ageError = error;
    _draft = _draft.copyWith(
      body: body.copyWith(
        birthYear: value == null ? null : _clock().year - value.round(),
      ),
    );
    notifyListeners();
  }

  /// [secondary] carries the inches half of a feet-and-inches entry and is
  /// ignored in metric.
  void updateHeight(String raw, {String secondary = ''}) {
    final (:value, :error) = isImperial
        ? _parseImperialHeight(raw, secondary)
        : _parse(
            raw,
            min: BodyProfile.minHeightCm,
            max: BodyProfile.maxHeightCm,
          );
    _heightError = error;
    _draft = _draft.copyWith(body: body.copyWith(heightCm: value));
    notifyListeners();
  }

  void updateWeight(String raw) {
    final (:value, :error) = _parseWeight(raw);
    _weightError = error;
    _draft = _draft.copyWith(body: body.copyWith(weightKg: value));
    notifyListeners();
  }

  /// An empty target weight is a valid answer, not an error: the plan simply
  /// loses its projection.
  void updateTargetWeight(String raw) {
    if (raw.trim().isEmpty) {
      _targetWeightError = null;
      _draft = _draft.copyWith(body: body.copyWith(clearTargetWeight: true));
      notifyListeners();
      return;
    }
    final (:value, :error) = _parseWeight(raw);
    _targetWeightError = error;
    _draft = _draft.copyWith(body: body.copyWith(targetWeightKg: value));
    notifyListeners();
  }

  // --- manual override -----------------------------------------------------

  CalorieTargetError? validateCalorieTarget(String raw) {
    if (raw.trim().isEmpty) return null;
    final value = int.tryParse(raw.trim());
    if (value == null ||
        value < CalorieCalculator.minCalories ||
        value > CalorieCalculator.maxCalories) {
      return CalorieTargetError.outOfRange;
    }
    return null;
  }

  /// Passing null or an unparseable value hands the target back to the engine.
  Future<void> setCalorieOverride(String? raw) async {
    final trimmed = raw?.trim() ?? '';
    final value = trimmed.isEmpty ? null : int.tryParse(trimmed);
    final valid = value != null && validateCalorieTarget(trimmed) == null;
    _draft = _draft.copyWith(
      dailyCalorieTarget: valid ? value : null,
      clearCalorieTarget: !valid,
    );
    notifyListeners();
    await _repository.saveDraft(_draft);
  }

  // --- display helpers -----------------------------------------------------

  /// The height entry fields for the current unit system: centimetres, or
  /// feet plus inches.
  ({String primary, String secondary}) heightFieldValues() {
    final height = body.heightCm;
    if (height == null) return (primary: '', secondary: '');
    if (!isImperial) {
      return (primary: height.round().toString(), secondary: '');
    }
    final imperial = ImperialHeight.fromCentimetres(height);
    return (
      primary: imperial.feet.toString(),
      secondary: imperial.inches.toString(),
    );
  }

  String weightFieldValue() => _weightDisplay(body.weightKg);

  String targetWeightFieldValue() => _weightDisplay(body.targetWeightKg);

  String ageFieldValue() => body.ageAt(_clock())?.toString() ?? '';

  String _weightDisplay(double? kilograms) {
    if (kilograms == null) return '';
    final shown = isImperial ? kilogramsToPounds(kilograms) : kilograms;
    return shown.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  }

  // --- internals -----------------------------------------------------------

  Future<void> _applyBody(BodyProfile updated) async {
    _draft = _draft.copyWith(body: updated);
    notifyListeners();
    await _repository.saveDraft(_draft);
  }

  ({double? value, NumericFieldError? error}) _parse(
    String raw, {
    required double min,
    required double max,
  }) {
    final trimmed = raw.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) return (value: null, error: NumericFieldError.missing);
    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      return (value: null, error: NumericFieldError.malformed);
    }
    if (parsed < min || parsed > max) {
      return (value: null, error: NumericFieldError.outOfRange);
    }
    return (value: parsed, error: null);
  }

  ({double? value, NumericFieldError? error}) _parseWeight(String raw) {
    if (!isImperial) {
      return _parse(
        raw,
        min: BodyProfile.minWeightKg,
        max: BodyProfile.maxWeightKg,
      );
    }
    final pounds = _parse(
      raw,
      min: kilogramsToPounds(BodyProfile.minWeightKg),
      max: kilogramsToPounds(BodyProfile.maxWeightKg),
    );
    return (
      value: pounds.value == null ? null : poundsToKilograms(pounds.value!),
      error: pounds.error,
    );
  }

  ({double? value, NumericFieldError? error}) _parseImperialHeight(
    String feet,
    String inches,
  ) {
    final feetPart = _parse(feet, min: 3, max: 8);
    if (feetPart.error != null) return feetPart;
    // Inches may legitimately be left blank; it reads as an exact foot.
    final inchesText = inches.trim();
    final inchesPart = inchesText.isEmpty
        ? (value: 0.0, error: null)
        : _parse(inchesText, min: 0, max: 11);
    if (inchesPart.error != null) return inchesPart;

    final centimetres = ImperialHeight(
      feet: feetPart.value!.round(),
      inches: inchesPart.value!.round(),
    ).centimetres;

    if (centimetres < BodyProfile.minHeightCm ||
        centimetres > BodyProfile.maxHeightCm) {
      return (value: null, error: NumericFieldError.outOfRange);
    }
    return (value: centimetres, error: null);
  }
}
