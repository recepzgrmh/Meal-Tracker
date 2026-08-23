/// The inputs the calorie engine needs, deliberately free of Flutter and of
/// any persistence concern so the algorithm around them stays plain Dart.
///
/// None of this is a medical or nutrition prescription. Every coefficient here
/// is a published population average used to produce a *starting estimate* the
/// user can override.
library;

/// Food groups a dietary pattern rules out. Kept on the pattern itself so the
/// analysis pipeline can reuse the same source of truth later.
enum DietaryExclusion {
  meat('meat'),
  poultry('poultry'),
  fish('fish'),
  dairy('dairy'),
  egg('egg'),
  honey('honey');

  const DietaryExclusion(this.wire);

  final String wire;
}

/// Drives the sex constant of the Mifflin-St Jeor equation and the calorie
/// floor. `unspecified` is a real answer, not a missing one.
enum BiologicalSex {
  female('female', -161, 1200),
  male('male', 5, 1500),

  /// The midpoint of the two published constants, so a user who declines the
  /// question still gets an estimate instead of being pushed into a bucket.
  unspecified('unspecified', -78, 1200);

  const BiologicalSex(this.wire, this.mifflinConstant, this.calorieFloor);

  final String wire;

  /// The trailing constant of `10·kg + 6.25·cm − 5·age + c`.
  final double mifflinConstant;

  /// Lowest daily intake to suggest without medical supervision
  /// (2013 AHA/ACC/TOS obesity guideline: 1200 kcal women, 1500 kcal men).
  final double calorieFloor;

  static BiologicalSex? fromWire(String? value) =>
      values.where((item) => item.wire == value).firstOrNull;
}

/// Physical activity level, the multiplier applied to BMR to reach TDEE.
/// This is the single largest source of error in the estimate, which is why
/// each option is described to the user with concrete behaviour, not adverbs.
enum ActivityLevel {
  sedentary('sedentary', 1.2, 1.2),
  light('light', 1.375, 1.4),
  moderate('moderate', 1.55, 1.6),
  high('high', 1.725, 1.8),
  athlete('athlete', 1.9, 2.0);

  const ActivityLevel(this.wire, this.multiplier, this.proteinPerKg);

  final String wire;

  /// Physical activity level (PAL) factor. Absorbs the thermic effect of food.
  final double multiplier;

  /// Baseline protein target in grams per kilogram of reference weight.
  final double proteinPerKg;

  static ActivityLevel? fromWire(String? value) =>
      values.where((item) => item.wire == value).firstOrNull;
}

enum WeightGoal {
  lose('lose'),
  maintain('maintain'),
  gain('gain');

  const WeightGoal(this.wire);

  final String wire;

  static WeightGoal? fromWire(String? value) =>
      values.where((item) => item.wire == value).firstOrNull;
}

/// How fast the user wants to move, expressed as a share of body weight per
/// week rather than a fixed calorie number: 0.5 kg/week is routine at 120 kg
/// and aggressive at 55 kg.
enum GoalPace {
  slow('slow', 0.0025, 0.00125),
  steady('steady', 0.005, 0.0025),
  fast('fast', 0.0075, 0.00375);

  const GoalPace(this.wire, this.lossShare, this.gainShare);

  final String wire;

  /// Fraction of body weight to lose per week.
  final double lossShare;

  /// Fraction of body weight to gain per week. Lean tissue accrues far slower
  /// than fat is lost, so the surplus side is roughly half the deficit side.
  final double gainShare;

  static GoalPace? fromWire(String? value) =>
      values.where((item) => item.wire == value).firstOrNull;
}

/// Splits the energy left after protein into carbohydrate and fat, and records
/// which food groups the pattern rules out.
enum DietPattern {
  balanced('balanced', carbShare: 0.55),
  highProtein('high_protein', carbShare: 0.50, minProteinPerKg: 2.0),
  lowCarb('low_carb', carbShare: 0.30),
  keto('keto', carbShare: 0, fixedCarbGrams: 25, maxProteinPerKg: 1.6),
  mediterranean('mediterranean', carbShare: 0.60),
  pescatarian(
    'pescatarian',
    carbShare: 0.55,
    exclusions: {DietaryExclusion.meat, DietaryExclusion.poultry},
  ),
  vegetarian(
    'vegetarian',
    carbShare: 0.58,
    exclusions: {
      DietaryExclusion.meat,
      DietaryExclusion.poultry,
      DietaryExclusion.fish,
    },
  ),
  vegan(
    'vegan',
    carbShare: 0.62,
    exclusions: {
      DietaryExclusion.meat,
      DietaryExclusion.poultry,
      DietaryExclusion.fish,
      DietaryExclusion.dairy,
      DietaryExclusion.egg,
      DietaryExclusion.honey,
    },
  );

  const DietPattern(
    this.wire, {
    required this.carbShare,
    this.fixedCarbGrams,
    this.minProteinPerKg,
    this.maxProteinPerKg,
    this.exclusions = const {},
  });

  final String wire;

  /// Share of the post-protein energy that goes to carbohydrate; the rest is
  /// fat. Ignored when [fixedCarbGrams] is set.
  final double carbShare;

  /// An absolute daily carbohydrate ceiling in grams. Ketogenic patterns are
  /// defined by a gram cap, not by a percentage.
  final double? fixedCarbGrams;

  final double? minProteinPerKg;
  final double? maxProteinPerKg;

  final Set<DietaryExclusion> exclusions;

  static DietPattern? fromWire(String? value) =>
      values.where((item) => item.wire == value).firstOrNull;
}

/// Presentation only. Height and weight are always stored in cm and kg.
enum MeasurementSystem {
  metric('metric'),
  imperial('imperial');

  const MeasurementSystem(this.wire);

  final String wire;

  static MeasurementSystem? fromWire(String? value) =>
      values.where((item) => item.wire == value).firstOrNull;
}

/// The setup answers, all optional because the flow fills them one step at a
/// time and a partially answered profile has to survive the app being killed.
class BodyProfile {
  const BodyProfile({
    this.sex,
    this.birthYear,
    this.heightCm,
    this.weightKg,
    this.targetWeightKg,
    this.activityLevel,
    this.goal,
    this.pace = GoalPace.steady,
    this.dietPattern,
    this.measurementSystem = MeasurementSystem.metric,
  });

  final BiologicalSex? sex;
  final int? birthYear;
  final double? heightCm;
  final double? weightKg;
  final double? targetWeightKg;
  final ActivityLevel? activityLevel;
  final WeightGoal? goal;
  final GoalPace pace;
  final DietPattern? dietPattern;
  final MeasurementSystem measurementSystem;

  static const minHeightCm = 100.0;
  static const maxHeightCm = 250.0;
  static const minWeightKg = 30.0;
  static const maxWeightKg = 400.0;
  static const minAge = 13;
  static const maxAge = 120;

  /// Age in whole years. Only the birth year is collected, so this is accurate
  /// to within a year — well inside the equation's own error band.
  int? ageAt(DateTime now) {
    if (birthYear case final year?) return now.year - year;
    return null;
  }

  double? get bmi {
    if (heightCm case final height?) {
      if (weightKg case final weight?) {
        final metres = height / 100;
        return weight / (metres * metres);
      }
    }
    return null;
  }

  /// True once every answer the calculator needs is present and in range.
  bool isCompleteAt(DateTime now) {
    final age = ageAt(now);
    return sex != null &&
        age != null &&
        age >= minAge &&
        age <= maxAge &&
        heightCm != null &&
        heightCm! >= minHeightCm &&
        heightCm! <= maxHeightCm &&
        weightKg != null &&
        weightKg! >= minWeightKg &&
        weightKg! <= maxWeightKg &&
        activityLevel != null &&
        goal != null &&
        dietPattern != null;
  }

  BodyProfile copyWith({
    BiologicalSex? sex,
    int? birthYear,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    ActivityLevel? activityLevel,
    WeightGoal? goal,
    GoalPace? pace,
    DietPattern? dietPattern,
    MeasurementSystem? measurementSystem,
    bool clearTargetWeight = false,
  }) {
    return BodyProfile(
      sex: sex ?? this.sex,
      birthYear: birthYear ?? this.birthYear,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: clearTargetWeight
          ? null
          : targetWeightKg ?? this.targetWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      pace: pace ?? this.pace,
      dietPattern: dietPattern ?? this.dietPattern,
      measurementSystem: measurementSystem ?? this.measurementSystem,
    );
  }
}
