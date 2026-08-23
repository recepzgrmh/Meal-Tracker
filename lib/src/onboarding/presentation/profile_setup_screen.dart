import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../bootstrap/app_coordinator.dart';
import '../../theme/app_theme.dart';
import '../domain/body_profile.dart';
import '../domain/nutrition_plan.dart';
import '../domain/onboarding_draft.dart';
import 'flow_scaffold.dart';
import 'profile_setup_view_model.dart';

/// The questions that shape the user's daily targets, asked once they have an
/// account. Replaces the spinner that used to sit here and silently write a
/// profile the user had never been asked about.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    required this.viewModel,
    required this.coordinator,
    super.key,
  });

  final ProfileSetupViewModel viewModel;
  final AppCoordinator coordinator;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  /// Set once the user commits, so the saving pane replaces the questions
  /// instead of appearing alongside them.
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    widget.viewModel.initialize();
  }

  Future<void> _finish() async {
    setState(() => _submitted = true);
    await widget.coordinator.refreshOnboarding();
    await widget.coordinator.completeProfile();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.viewModel, widget.coordinator]),
      builder: (context, _) {
        final viewModel = widget.viewModel;
        if (viewModel.isLoading) {
          return const Scaffold(
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }
        if (_submitted) {
          return Scaffold(
            body: SafeArea(
              child: _SavingPane(
                coordinator: widget.coordinator,
                onEdit: () => setState(() => _submitted = false),
              ),
            ),
          );
        }

        final step = viewModel.step;
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                FlowHeader(
                  step: step,
                  stepCount: ProfileSetupViewModel.stepCount,
                  onBack: step == 0 ? null : viewModel.back,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : AppMotion.standard,
                    child: switch (step) {
                      ProfileSetupViewModel.sexAndAgeStep => _SexAndAgeStep(
                        key: const ValueKey('sex-age'),
                        viewModel: viewModel,
                      ),
                      ProfileSetupViewModel.bodyStep => _BodyStep(
                        key: const ValueKey('body'),
                        viewModel: viewModel,
                      ),
                      ProfileSetupViewModel.activityStep => _ActivityStep(
                        key: const ValueKey('activity'),
                        viewModel: viewModel,
                      ),
                      ProfileSetupViewModel.goalStep => _GoalStep(
                        key: const ValueKey('goal'),
                        viewModel: viewModel,
                      ),
                      ProfileSetupViewModel.dietStep => _DietStep(
                        key: const ValueKey('diet'),
                        viewModel: viewModel,
                      ),
                      ProfileSetupViewModel.intentionStep => _IntentionStep(
                        key: const ValueKey('intention'),
                        viewModel: viewModel,
                      ),
                      _ => _SummaryStep(
                        key: const ValueKey('summary'),
                        viewModel: viewModel,
                        onFinish: _finish,
                      ),
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Heading plus supporting line, repeated at the top of every step.
class _StepIntro extends StatelessWidget {
  const _StepIntro({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// The primary action every question step ends with.
class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: const Key('setup-continue'),
      onPressed: enabled ? onPressed : null,
      child: Text(
        context.ota('commonContinue', tr: 'Devam et', en: 'Continue'),
      ),
    );
  }
}

/// A numeric entry with a unit suffix and an inline error line.
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.error,
    required this.onChanged,
    this.fieldKey,
    this.decimal = false,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final NumericFieldError? error;
  final ValueChanged<String> onChanged;
  final Key? fieldKey;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        errorText: error == null ? null : _message(context, error!),
      ),
    );
  }

  static String _message(BuildContext context, NumericFieldError error) {
    return switch (error) {
      NumericFieldError.missing => context.ota(
        'setupFieldMissing',
        tr: 'Bu alan gerekli',
        en: 'This field is required',
      ),
      NumericFieldError.malformed => context.ota(
        'setupFieldMalformed',
        tr: 'Sadece sayı gir',
        en: 'Enter a number',
      ),
      NumericFieldError.outOfRange => context.ota(
        'setupFieldOutOfRange',
        tr: 'Bu değer beklenen aralığın dışında',
        en: 'That value is outside the expected range',
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// Step 1 — who you are
// ---------------------------------------------------------------------------

class _SexAndAgeStep extends StatefulWidget {
  const _SexAndAgeStep({required this.viewModel, super.key});

  final ProfileSetupViewModel viewModel;

  @override
  State<_SexAndAgeStep> createState() => _SexAndAgeStepState();
}

class _SexAndAgeStepState extends State<_SexAndAgeStep> {
  late final TextEditingController _age = TextEditingController(
    text: widget.viewModel.ageFieldValue(),
  );

  @override
  void dispose() {
    _age.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return FlowStepLayout(
      footer: _ContinueButton(
        enabled: viewModel.canAdvance,
        onPressed: viewModel.next,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIntro(
            title: context.ota(
              'setupBasicsTitle',
              tr: 'Önce seni tanıyalım',
              en: 'First, a little about you',
            ),
            body: context.ota(
              'setupBasicsBody',
              tr: 'Yaş ve cinsiyet, dinlenme halinde harcadığın enerjiyi hesaplayan denklemin girdileri.',
              en: 'Age and sex are inputs to the equation that estimates the energy you burn at rest.',
            ),
          ),
          for (final sex in BiologicalSex.values)
            FlowOptionCard(
              key: Key('setup-sex-${sex.wire}'),
              title: _sexTitle(context, sex),
              detail: _sexDetail(context, sex),
              selected: viewModel.body.sex == sex,
              onPressed: () => viewModel.selectSex(sex),
            ),
          const SizedBox(height: AppSpacing.md),
          _NumberField(
            fieldKey: const Key('setup-age'),
            controller: _age,
            label: context.ota('setupAgeLabel', tr: 'Yaş', en: 'Age'),
            suffix: context.ota('setupAgeUnit', tr: 'yıl', en: 'years'),
            error: viewModel.ageError,
            onChanged: viewModel.updateAge,
          ),
        ],
      ),
    );
  }

  static String _sexTitle(BuildContext context, BiologicalSex sex) {
    return switch (sex) {
      BiologicalSex.female => context.ota(
        'setupSexFemale',
        tr: 'Kadın',
        en: 'Female',
      ),
      BiologicalSex.male => context.ota(
        'setupSexMale',
        tr: 'Erkek',
        en: 'Male',
      ),
      BiologicalSex.unspecified => context.ota(
        'setupSexUnspecified',
        tr: 'Belirtmek istemiyorum',
        en: 'Prefer not to say',
      ),
    };
  }

  static String _sexDetail(BuildContext context, BiologicalSex sex) {
    if (sex != BiologicalSex.unspecified) return '';
    return context.ota(
      'setupSexUnspecifiedDetail',
      tr: 'İki değerin ortası kullanılır; tahmin biraz daha genel olur.',
      en: 'The midpoint of the two values is used; the estimate is a little broader.',
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — height and weight
// ---------------------------------------------------------------------------

class _BodyStep extends StatefulWidget {
  const _BodyStep({required this.viewModel, super.key});

  final ProfileSetupViewModel viewModel;

  @override
  State<_BodyStep> createState() => _BodyStepState();
}

class _BodyStepState extends State<_BodyStep> {
  final _height = TextEditingController();
  final _heightInches = TextEditingController();
  final _weight = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  /// Rewrites the fields from the stored profile. Called on entry and whenever
  /// the unit system changes, so the numbers on screen always match the unit
  /// beside them.
  void _syncControllers() {
    final height = widget.viewModel.heightFieldValues();
    _height.text = height.primary;
    _heightInches.text = height.secondary;
    _weight.text = widget.viewModel.weightFieldValue();
  }

  Future<void> _switchUnits(MeasurementSystem system) async {
    await widget.viewModel.selectMeasurementSystem(system);
    if (mounted) setState(_syncControllers);
  }

  @override
  void dispose() {
    _height.dispose();
    _heightInches.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final imperial = viewModel.isImperial;
    final bmi = viewModel.body.bmi;

    return FlowStepLayout(
      footer: _ContinueButton(
        enabled: viewModel.canAdvance,
        onPressed: viewModel.next,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIntro(
            title: context.ota(
              'setupBodyTitle',
              tr: 'Boyun ve kilon',
              en: 'Your height and weight',
            ),
            body: context.ota(
              'setupBodyBody',
              tr: 'Hedefin bu iki değerle ölçekleniyor. İstediğin zaman profilinden güncelleyebilirsin.',
              en: 'Your target scales with these two. You can update them from your profile any time.',
            ),
          ),
          SegmentedButton<MeasurementSystem>(
            key: const Key('setup-units'),
            segments: [
              ButtonSegment(
                value: MeasurementSystem.metric,
                label: Text(
                  context.ota('setupUnitsMetric', tr: 'cm / kg', en: 'cm / kg'),
                ),
              ),
              ButtonSegment(
                value: MeasurementSystem.imperial,
                label: Text(
                  context.ota(
                    'setupUnitsImperial',
                    tr: 'ft / lb',
                    en: 'ft / lb',
                  ),
                ),
              ),
            ],
            selected: {viewModel.body.measurementSystem},
            onSelectionChanged: (selection) => _switchUnits(selection.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (imperial)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _NumberField(
                    fieldKey: const Key('setup-height'),
                    controller: _height,
                    label: context.ota(
                      'setupHeightLabel',
                      tr: 'Boy',
                      en: 'Height',
                    ),
                    suffix: 'ft',
                    error: viewModel.heightError,
                    onChanged: (value) => viewModel.updateHeight(
                      value,
                      secondary: _heightInches.text,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _NumberField(
                    fieldKey: const Key('setup-height-inches'),
                    controller: _heightInches,
                    label: context.ota(
                      'setupHeightInchesLabel',
                      tr: 'İnç',
                      en: 'Inches',
                    ),
                    suffix: 'in',
                    error: null,
                    onChanged: (value) =>
                        viewModel.updateHeight(_height.text, secondary: value),
                  ),
                ),
              ],
            )
          else
            _NumberField(
              fieldKey: const Key('setup-height'),
              controller: _height,
              label: context.ota('setupHeightLabel', tr: 'Boy', en: 'Height'),
              suffix: 'cm',
              error: viewModel.heightError,
              onChanged: viewModel.updateHeight,
            ),
          const SizedBox(height: AppSpacing.md),
          _NumberField(
            fieldKey: const Key('setup-weight'),
            controller: _weight,
            decimal: true,
            label: context.ota('setupWeightLabel', tr: 'Kilo', en: 'Weight'),
            suffix: imperial ? 'lb' : 'kg',
            error: viewModel.weightError,
            onChanged: viewModel.updateWeight,
          ),
          if (bmi != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              context.ota(
                'setupBmiReadout',
                tr: 'Vücut kitle indeksin ≈ {bmi}',
                en: 'Your body mass index is ≈ {bmi}',
                replacements: {'bmi': bmi.toStringAsFixed(1)},
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 — activity
// ---------------------------------------------------------------------------

class _ActivityStep extends StatelessWidget {
  const _ActivityStep({required this.viewModel, super.key});

  final ProfileSetupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return FlowStepLayout(
      footer: _ContinueButton(
        enabled: viewModel.canAdvance,
        onPressed: viewModel.next,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIntro(
            title: context.ota(
              'setupActivityTitle',
              tr: 'Haftan nasıl geçiyor?',
              en: 'How does your week go?',
            ),
            body: context.ota(
              'setupActivityBody',
              tr: 'Tahmindeki en büyük belirsizlik burada. Emin değilsen bir alt seçeneği işaretle.',
              en: 'This is the biggest source of error in the estimate. If you are unsure, pick the level below.',
            ),
          ),
          for (final level in ActivityLevel.values)
            FlowOptionCard(
              key: Key('setup-activity-${level.wire}'),
              title: _title(context, level),
              detail: _detail(context, level),
              selected: viewModel.body.activityLevel == level,
              onPressed: () => viewModel.selectActivity(level),
            ),
        ],
      ),
    );
  }

  static String _title(BuildContext context, ActivityLevel level) {
    return switch (level) {
      ActivityLevel.sedentary => context.ota(
        'setupActivitySedentary',
        tr: 'Hareketsiz',
        en: 'Sedentary',
      ),
      ActivityLevel.light => context.ota(
        'setupActivityLight',
        tr: 'Hafif hareketli',
        en: 'Lightly active',
      ),
      ActivityLevel.moderate => context.ota(
        'setupActivityModerate',
        tr: 'Orta düzey',
        en: 'Moderately active',
      ),
      ActivityLevel.high => context.ota(
        'setupActivityHigh',
        tr: 'Çok hareketli',
        en: 'Very active',
      ),
      ActivityLevel.athlete => context.ota(
        'setupActivityAthlete',
        tr: 'Sporcu düzeyi',
        en: 'Athlete level',
      ),
    };
  }

  static String _detail(BuildContext context, ActivityLevel level) {
    return switch (level) {
      ActivityLevel.sedentary => context.ota(
        'setupActivitySedentaryDetail',
        tr: 'Masa başı iş, düzenli antrenman yok',
        en: 'Desk work, no regular training',
      ),
      ActivityLevel.light => context.ota(
        'setupActivityLightDetail',
        tr: 'Haftada 1–3 gün hafif egzersiz veya bol yürüyüş',
        en: '1–3 light sessions a week, or a lot of walking',
      ),
      ActivityLevel.moderate => context.ota(
        'setupActivityModerateDetail',
        tr: 'Haftada 3–5 gün antrenman',
        en: 'Training 3–5 days a week',
      ),
      ActivityLevel.high => context.ota(
        'setupActivityHighDetail',
        tr: 'Haftada 6–7 gün yoğun antrenman',
        en: 'Hard training 6–7 days a week',
      ),
      ActivityLevel.athlete => context.ota(
        'setupActivityAthleteDetail',
        tr: 'Günde iki antrenman veya ağır fiziksel iş',
        en: 'Two sessions a day, or heavy physical work',
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// Step 4 — goal, target weight, pace
// ---------------------------------------------------------------------------

class _GoalStep extends StatefulWidget {
  const _GoalStep({required this.viewModel, super.key});

  final ProfileSetupViewModel viewModel;

  @override
  State<_GoalStep> createState() => _GoalStepState();
}

class _GoalStepState extends State<_GoalStep> {
  late final TextEditingController _targetWeight = TextEditingController(
    text: widget.viewModel.targetWeightFieldValue(),
  );

  @override
  void dispose() {
    _targetWeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final goal = viewModel.body.goal;
    final wantsChange = goal != null && goal != WeightGoal.maintain;
    final plan = viewModel.plan;

    return FlowStepLayout(
      footer: _ContinueButton(
        enabled: viewModel.canAdvance,
        onPressed: viewModel.next,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIntro(
            title: context.ota(
              'setupGoalTitle',
              tr: 'Ne yapmak istiyorsun?',
              en: 'What are you after?',
            ),
            body: context.ota(
              'setupGoalBody',
              tr: 'Hızı vücut ağırlığının yüzdesi olarak belirliyoruz; güvenli aralığın dışına çıkmayız.',
              en: 'Pace is set as a share of your body weight, and never leaves the safe range.',
            ),
          ),
          for (final option in WeightGoal.values)
            FlowOptionCard(
              key: Key('setup-goal-${option.wire}'),
              title: _goalTitle(context, option),
              detail: _goalDetail(context, option),
              selected: goal == option,
              onPressed: () => viewModel.selectGoal(option),
            ),
          if (wantsChange) ...[
            const SizedBox(height: AppSpacing.md),
            _NumberField(
              fieldKey: const Key('setup-target-weight'),
              controller: _targetWeight,
              decimal: true,
              label: context.ota(
                'setupTargetWeightLabel',
                tr: 'Hedef kilo (isteğe bağlı)',
                en: 'Target weight (optional)',
              ),
              suffix: viewModel.isImperial ? 'lb' : 'kg',
              error: viewModel.targetWeightError,
              onChanged: viewModel.updateTargetWeight,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.ota('setupPaceLabel', tr: 'Tempo', en: 'Pace'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final pace in GoalPace.values)
              FlowOptionCard(
                key: Key('setup-pace-${pace.wire}'),
                title: _paceTitle(context, pace),
                detail: _paceDetail(context, pace),
                selected: viewModel.body.pace == pace,
                onPressed: () => viewModel.selectPace(pace),
              ),
            if (plan != null && plan.weeklyRateKg != 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _projection(context, plan),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ],
      ),
    );
  }

  static String _projection(BuildContext context, NutritionPlan plan) {
    final rate = plan.weeklyRateKg.abs().toStringAsFixed(2);
    if (plan.estimatedWeeks case final weeks?) {
      return context.ota(
        'setupPaceProjection',
        tr: '≈ haftada {rate} kg · hedefe yaklaşık {weeks} hafta',
        en: '≈ {rate} kg per week · about {weeks} weeks to your target',
        replacements: {'rate': rate, 'weeks': weeks},
      );
    }
    return context.ota(
      'setupPaceRateOnly',
      tr: '≈ haftada {rate} kg',
      en: '≈ {rate} kg per week',
      replacements: {'rate': rate},
    );
  }

  static String _goalTitle(BuildContext context, WeightGoal goal) {
    return switch (goal) {
      WeightGoal.lose => context.ota(
        'setupGoalLose',
        tr: 'Kilo vermek',
        en: 'Lose weight',
      ),
      WeightGoal.maintain => context.ota(
        'setupGoalMaintain',
        tr: 'Kilomu korumak',
        en: 'Maintain my weight',
      ),
      WeightGoal.gain => context.ota(
        'setupGoalGain',
        tr: 'Kilo almak',
        en: 'Gain weight',
      ),
    };
  }

  static String _goalDetail(BuildContext context, WeightGoal goal) {
    return switch (goal) {
      WeightGoal.lose => context.ota(
        'setupGoalLoseDetail',
        tr: 'Günlük hedefin bakım seviyesinin altına iner',
        en: 'Your daily target drops below maintenance',
      ),
      WeightGoal.maintain => context.ota(
        'setupGoalMaintainDetail',
        tr: 'Hedefin bakım seviyende kalır',
        en: 'Your target stays at maintenance',
      ),
      WeightGoal.gain => context.ota(
        'setupGoalGainDetail',
        tr: 'Günlük hedefin bakım seviyesinin üstüne çıkar',
        en: 'Your daily target rises above maintenance',
      ),
    };
  }

  static String _paceTitle(BuildContext context, GoalPace pace) {
    return switch (pace) {
      GoalPace.slow => context.ota('setupPaceSlow', tr: 'Yavaş', en: 'Slow'),
      GoalPace.steady => context.ota(
        'setupPaceSteady',
        tr: 'Dengeli',
        en: 'Steady',
      ),
      GoalPace.fast => context.ota('setupPaceFast', tr: 'Hızlı', en: 'Fast'),
    };
  }

  static String _paceDetail(BuildContext context, GoalPace pace) {
    return switch (pace) {
      GoalPace.slow => context.ota(
        'setupPaceSlowDetail',
        tr: 'Haftada vücut ağırlığının %0,25’i',
        en: '0.25% of body weight per week',
      ),
      GoalPace.steady => context.ota(
        'setupPaceSteadyDetail',
        tr: 'Haftada vücut ağırlığının %0,5’i',
        en: '0.5% of body weight per week',
      ),
      GoalPace.fast => context.ota(
        'setupPaceFastDetail',
        tr: 'Haftada vücut ağırlığının %0,75’i',
        en: '0.75% of body weight per week',
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// Step 5 — dietary pattern
// ---------------------------------------------------------------------------

class _DietStep extends StatelessWidget {
  const _DietStep({required this.viewModel, super.key});

  final ProfileSetupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return FlowStepLayout(
      footer: _ContinueButton(
        enabled: viewModel.canAdvance,
        onPressed: viewModel.next,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIntro(
            title: context.ota(
              'setupDietTitle',
              tr: 'Nasıl besleniyorsun?',
              en: 'How do you eat?',
            ),
            body: context.ota(
              'setupDietBody',
              tr: 'Bu seçim kaloriyi değil, kalorinin protein–karbonhidrat–yağ dağılımını belirler.',
              en: 'This does not change your calories — it changes how they split across protein, carbs, and fat.',
            ),
          ),
          for (final diet in DietPattern.values)
            FlowOptionCard(
              key: Key('setup-diet-${diet.wire}'),
              title: _title(context, diet),
              detail: _detail(context, diet),
              selected: viewModel.body.dietPattern == diet,
              onPressed: () => viewModel.selectDiet(diet),
            ),
        ],
      ),
    );
  }

  static String _title(BuildContext context, DietPattern diet) {
    return switch (diet) {
      DietPattern.balanced => context.ota(
        'setupDietBalanced',
        tr: 'Dengeli',
        en: 'Balanced',
      ),
      DietPattern.highProtein => context.ota(
        'setupDietHighProtein',
        tr: 'Yüksek proteinli',
        en: 'High protein',
      ),
      DietPattern.lowCarb => context.ota(
        'setupDietLowCarb',
        tr: 'Düşük karbonhidrat',
        en: 'Low carb',
      ),
      DietPattern.keto => context.ota(
        'setupDietKeto',
        tr: 'Ketojenik',
        en: 'Ketogenic',
      ),
      DietPattern.mediterranean => context.ota(
        'setupDietMediterranean',
        tr: 'Akdeniz',
        en: 'Mediterranean',
      ),
      DietPattern.pescatarian => context.ota(
        'setupDietPescatarian',
        tr: 'Pesketaryen',
        en: 'Pescatarian',
      ),
      DietPattern.vegetarian => context.ota(
        'setupDietVegetarian',
        tr: 'Vejetaryen',
        en: 'Vegetarian',
      ),
      DietPattern.vegan => context.ota(
        'setupDietVegan',
        tr: 'Vegan',
        en: 'Vegan',
      ),
    };
  }

  static String _detail(BuildContext context, DietPattern diet) {
    return switch (diet) {
      DietPattern.balanced => context.ota(
        'setupDietBalancedDetail',
        tr: 'Kısıtlama yok, orta düzey karbonhidrat ve yağ',
        en: 'No restrictions, moderate carbs and fat',
      ),
      DietPattern.highProtein => context.ota(
        'setupDietHighProteinDetail',
        tr: 'Protein hedefi en az 2 g/kg’a çekilir',
        en: 'Protein is raised to at least 2 g/kg',
      ),
      DietPattern.lowCarb => context.ota(
        'setupDietLowCarbDetail',
        tr: 'Karbonhidrat azaltılır, yağ artırılır',
        en: 'Fewer carbs, more fat',
      ),
      DietPattern.keto => context.ota(
        'setupDietKetoDetail',
        tr: 'Günlük karbonhidrat 25 g ile sınırlanır',
        en: 'Carbohydrate is capped at 25 g a day',
      ),
      DietPattern.mediterranean => context.ota(
        'setupDietMediterraneanDetail',
        tr: 'Karbonhidrat ağırlıklı, zeytinyağı odaklı yağ',
        en: 'Carb-forward, with fat mostly from olive oil',
      ),
      DietPattern.pescatarian => context.ota(
        'setupDietPescatarianDetail',
        tr: 'Balık var, kırmızı et ve kümes hayvanı yok',
        en: 'Fish yes, red meat and poultry no',
      ),
      DietPattern.vegetarian => context.ota(
        'setupDietVegetarianDetail',
        tr: 'Et, kümes hayvanı ve balık yok',
        en: 'No meat, poultry, or fish',
      ),
      DietPattern.vegan => context.ota(
        'setupDietVeganDetail',
        tr: 'Hiçbir hayvansal ürün yok',
        en: 'No animal products at all',
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// Step 6 — what the user wants to watch
// ---------------------------------------------------------------------------

class _IntentionStep extends StatelessWidget {
  const _IntentionStep({required this.viewModel, super.key});

  final ProfileSetupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return FlowStepLayout(
      footer: _ContinueButton(
        enabled: viewModel.canAdvance,
        onPressed: viewModel.next,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIntro(
            title: context.ota(
              'setupIntentionTitle',
              tr: 'Neye bakmak istersin?',
              en: 'What do you want to watch?',
            ),
            body: context.ota(
              'setupIntentionBody',
              tr: 'Uygulamanın önce hangi rakamı göstereceğini belirler. Sonradan değiştirebilirsin.',
              en: 'It decides which number the app leads with. You can change it later.',
            ),
          ),
          for (final intention in TrackingIntention.values)
            FlowOptionCard(
              key: Key('setup-intention-${intention.name}'),
              title: _title(context, intention),
              detail: _detail(context, intention),
              selected: viewModel.draft.intention == intention,
              onPressed: () => viewModel.selectIntention(intention),
            ),
        ],
      ),
    );
  }

  static String _title(BuildContext context, TrackingIntention intention) {
    return switch (intention) {
      TrackingIntention.understand => context.ota(
        'setupIntentionUnderstand',
        tr: 'Ne yediğimi anlamak',
        en: 'Understand what I eat',
      ),
      TrackingIntention.protein => context.ota(
        'setupIntentionProtein',
        tr: 'Proteini takip etmek',
        en: 'Track protein',
      ),
      TrackingIntention.calories => context.ota(
        'setupIntentionCalories',
        tr: 'Kaloriyi takip etmek',
        en: 'Track calories',
      ),
    };
  }

  static String _detail(BuildContext context, TrackingIntention intention) {
    return switch (intention) {
      TrackingIntention.understand => context.ota(
        'setupIntentionUnderstandDetail',
        tr: 'Rakamlar geride, öğünlerin önde',
        en: 'Meals up front, numbers behind them',
      ),
      TrackingIntention.protein => context.ota(
        'setupIntentionProteinDetail',
        tr: 'Protein hedefin öne çıkar',
        en: 'Your protein target leads',
      ),
      TrackingIntention.calories => context.ota(
        'setupIntentionCaloriesDetail',
        tr: 'Günlük kalori hedefin öne çıkar',
        en: 'Your daily calorie target leads',
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// Step 7 — the plan
// ---------------------------------------------------------------------------

class _SummaryStep extends StatefulWidget {
  const _SummaryStep({
    required this.viewModel,
    required this.onFinish,
    super.key,
  });

  final ProfileSetupViewModel viewModel;
  final Future<void> Function() onFinish;

  @override
  State<_SummaryStep> createState() => _SummaryStepState();
}

class _SummaryStepState extends State<_SummaryStep> {
  late final TextEditingController _override = TextEditingController(
    text: widget.viewModel.draft.dailyCalorieTarget?.toString() ?? '',
  );
  late bool _overriding = widget.viewModel.draft.dailyCalorieTarget != null;

  @override
  void dispose() {
    _override.dispose();
    super.dispose();
  }

  Future<void> _toggleOverride(bool value) async {
    setState(() => _overriding = value);
    if (!value) {
      _override.clear();
      await widget.viewModel.setCalorieOverride(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final plan = viewModel.plan;
    final theme = Theme.of(context);
    final overrideError = viewModel.validateCalorieTarget(_override.text);

    return FlowStepLayout(
      footer: FilledButton(
        key: const Key('setup-finish'),
        onPressed: plan == null || (_overriding && overrideError != null)
            ? null
            : widget.onFinish,
        child: Text(
          context.ota('setupFinishAction', tr: 'Planı kaydet', en: 'Save plan'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIntro(
            title: context.ota(
              'setupSummaryTitle',
              tr: 'Günlük planın',
              en: 'Your daily plan',
            ),
            body: context.ota(
              'setupSummaryBody',
              tr: 'Bu bir başlangıç noktası. Birkaç hafta izleyip gerekirse değiştir.',
              en: 'This is a starting point. Follow it for a few weeks and adjust if it does not match reality.',
            ),
          ),
          if (plan == null)
            Text(
              context.ota(
                'setupSummaryIncomplete',
                tr: 'Planı hesaplamak için önceki adımlara dönüp eksik cevapları tamamla.',
                en: 'Go back and fill in the missing answers so the plan can be calculated.',
              ),
              style: theme.textTheme.bodyMedium,
            )
          else ...[
            Text(
              context.ota(
                'setupSummaryCalories',
                tr: '{calories} kcal',
                en: '{calories} kcal',
                replacements: {'calories': plan.calories.round()},
              ),
              key: const Key('setup-summary-calories'),
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            _MacroRow(
              color: AppColors.protein,
              label: context.ota('macroProtein', tr: 'Protein', en: 'Protein'),
              grams: plan.proteinG,
            ),
            _MacroRow(
              color: AppColors.carbs,
              label: context.ota('macroCarbs', tr: 'Karbonhidrat', en: 'Carbs'),
              grams: plan.carbsG,
            ),
            _MacroRow(
              color: AppColors.fat,
              label: context.ota('macroFat', tr: 'Yağ', en: 'Fat'),
              grams: plan.fatG,
            ),
            const SizedBox(height: AppSpacing.md),
            if (plan.bmr case final bmr?)
              _WorkingRow(
                label: context.ota(
                  'setupSummaryBmr',
                  tr: 'Dinlenme metabolizması',
                  en: 'Resting metabolism',
                ),
                value: '${bmr.round()} kcal',
              ),
            if (plan.tdee case final tdee?)
              _WorkingRow(
                label: context.ota(
                  'setupSummaryTdee',
                  tr: 'Bakım seviyesi',
                  en: 'Maintenance',
                ),
                value: '${tdee.round()} kcal',
              ),
            for (final warning in plan.warnings) ...[
              const SizedBox(height: AppSpacing.xs),
              _WarningNote(warning: warning),
            ],
            const SizedBox(height: AppSpacing.lg),
            SwitchListTile.adaptive(
              key: const Key('setup-override-toggle'),
              contentPadding: EdgeInsets.zero,
              value: _overriding,
              onChanged: _toggleOverride,
              title: Text(
                context.ota(
                  'setupOverrideToggle',
                  tr: 'Hedefi kendim gireceğim',
                  en: 'I will set the target myself',
                ),
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (_overriding)
              _NumberField(
                fieldKey: const Key('setup-override'),
                controller: _override,
                label: context.ota(
                  'setupOverrideLabel',
                  tr: 'Günlük kalori hedefi',
                  en: 'Daily calorie target',
                ),
                suffix: 'kcal',
                error: null,
                onChanged: (value) async {
                  await viewModel.setCalorieOverride(value);
                  if (mounted) setState(() {});
                },
              ),
            if (_overriding && overrideError != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                context.ota(
                  'setupOverrideOutOfRange',
                  tr: 'Hedef 500 ile 10000 kcal arasında olmalı',
                  en: 'The target must be between 500 and 10000 kcal',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.destructive,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.ota(
                'setupMedicalDisclaimer',
                tr: 'Bu hesap bir tahmindir, tıbbi ya da beslenme tavsiyesi değildir. Bir sağlık durumun varsa bir uzmana danış.',
                en: 'This is an estimate, not medical or nutrition advice. If you have a health condition, talk to a professional.',
              ),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.color,
    required this.label,
    required this.grams,
  });

  final Color color;
  final String label;
  final double grams;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            '${grams.round()} g',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _WorkingRow extends StatelessWidget {
  const _WorkingRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.micro),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// Anything the engine had to correct, stated plainly rather than hidden.
class _WarningNote extends StatelessWidget {
  const _WarningNote({required this.warning});

  final PlanWarning warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.reviewSurface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Text(
        _message(context, warning),
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.reviewInk),
      ),
    );
  }

  static String _message(BuildContext context, PlanWarning warning) {
    return switch (warning) {
      PlanWarning.calorieFloorApplied => context.ota(
        'setupWarningFloor',
        tr: 'Seçtiğin tempo hedefi güvenli sınırın altına indiriyordu; hedef bu sınıra yükseltildi.',
        en: 'Your chosen pace would have pushed the target below the safe minimum, so it was raised to that minimum.',
      ),
      PlanWarning.paceReduced => context.ota(
        'setupWarningPace',
        tr: 'Seçtiğin tempo güvenli aralığın dışındaydı; en yakın güvenli hıza çekildi.',
        en: 'Your chosen pace was outside the safe range and was reduced to the nearest safe rate.',
      ),
      PlanWarning.underweightDeficit => context.ota(
        'setupWarningUnderweight',
        tr: 'Vücut kitle indeksin zaten düşük olduğu için kalori açığı uygulanmadı; hedef bakım seviyesinde.',
        en: 'Your body mass index is already low, so no deficit was applied — the target sits at maintenance.',
      ),
      PlanWarning.minorAge => context.ota(
        'setupWarningMinor',
        tr: 'Bu denklem 18 yaş altı için doğrulanmadı. Hedefi bir sağlık uzmanıyla konuş.',
        en: 'This equation is not validated under 18. Please go over the target with a health professional.',
      ),
      PlanWarning.proteinCappedByAmdr => context.ota(
        'setupWarningProteinCap',
        tr: 'Protein hedefi, günlük enerjinin %35’ini aşmaması için sınırlandı.',
        en: 'The protein target was capped so it stays under 35% of daily energy.',
      ),
    };
  }
}

/// The write to `profiles`, with the retry the old completion screen had.
class _SavingPane extends StatelessWidget {
  const _SavingPane({required this.coordinator, required this.onEdit});

  final AppCoordinator coordinator;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final failed = coordinator.profileError != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!failed) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  context.ota(
                    'profileSavingPreferences',
                    tr: 'Planın kaydediliyor…',
                    en: 'Saving your plan…',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                const Icon(Icons.cloud_off_outlined, size: 48),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  context.ota(
                    'profileSaveError',
                    tr: 'Plan kaydedilemedi. Bağlantını kontrol edip tekrar dene.',
                    en: 'Your plan could not be saved. Check your connection and try again.',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: coordinator.isCompletingProfile
                      ? null
                      : coordinator.completeProfile,
                  child: Text(
                    context.ota(
                      'commonRetry',
                      tr: 'Tekrar dene',
                      en: 'Try again',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onEdit,
                  child: Text(
                    context.ota(
                      'setupBackToPlan',
                      tr: 'Cevaplarıma dön',
                      en: 'Back to my answers',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
