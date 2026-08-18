import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../domain/onboarding_draft.dart';
import 'onboarding_view_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.viewModel,
    required this.onDraftChanged,
    super.key,
  });

  final OnboardingViewModel viewModel;
  final Future<void> Function() onDraftChanged;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _calorieController = TextEditingController();
  bool _demoAnalyzed = false;
  String _portion = 'regular';
  String? _calorieError;

  @override
  void initState() {
    super.initState();
    widget.viewModel.initialize().then((_) {
      if (!mounted) return;
      final target = widget.viewModel.draft.dailyCalorieTarget;
      if (target != null) _calorieController.text = '$target';
    });
  }

  @override
  void dispose() {
    _calorieController.dispose();
    super.dispose();
  }

  Future<void> _goTo(int step) async {
    await widget.viewModel.goToStep(step);
    await widget.onDraftChanged();
  }

  Future<void> _finish() async {
    final error = widget.viewModel.validateCalorieTarget(
      _calorieController.text,
    );
    if (error != null) {
      setState(
        () => _calorieError = context.ota(
          'calorieTargetValidation',
          tr: '500–10.000 kcal arasında bir değer gir veya alanı boş bırak.',
          en: 'Enter a value between 500–10,000 kcal or leave the field blank.',
        ),
      );
      return;
    }
    await widget.viewModel.setCalorieTarget(_calorieController.text);
    await widget.viewModel.finishDraft();
    await widget.onDraftChanged();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        if (widget.viewModel.isLoading) {
          return const Scaffold(
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }
        final step = widget.viewModel.draft.step.clamp(0, 2);
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _OnboardingHeader(
                  step: step,
                  onBack: step == 0 ? null : () => _goTo(step - 1),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: switch (step) {
                      0 => _WelcomeStep(
                        key: const ValueKey('welcome'),
                        onContinue: () => _goTo(1),
                        onSignIn: _finish,
                      ),
                      1 => _AccuracyDemoStep(
                        key: const ValueKey('demo'),
                        analyzed: _demoAnalyzed,
                        selectedPortion: _portion,
                        onAnalyze: () => setState(() => _demoAnalyzed = true),
                        onSelectPortion: (value) =>
                            setState(() => _portion = value),
                        onContinue: () => _goTo(2),
                      ),
                      _ => _PersonalizationStep(
                        key: const ValueKey('personalization'),
                        viewModel: widget.viewModel,
                        calorieController: _calorieController,
                        calorieError: _calorieError,
                        onFinish: _finish,
                        onIntentionChanged: (intention) async {
                          await widget.viewModel.selectIntention(intention);
                          setState(() => _calorieError = null);
                        },
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

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.step, required this.onBack});

  final int step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 4),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: onBack == null
                ? null
                : IconButton(
                    tooltip: context.ota('commonBack', tr: 'Geri', en: 'Back'),
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
          ),
          const Spacer(),
          Semantics(
            label: context.ota(
              'onboardingStepSemantics',
              tr: '3 adımdan {step}.si',
              en: 'Step {step} of 3',
              replacements: {'step': step + 1},
            ),
            child: Text(
              context.ota(
                'onboardingStepCounter',
                tr: '{step} / 3',
                en: '{step} / 3',
                replacements: {'step': step + 1},
              ),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({
    required this.onContinue,
    required this.onSignIn,
    super.key,
  });

  final VoidCallback onContinue;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      footer: Column(
        children: [
          FilledButton(
            key: const Key('onboarding-continue'),
            onPressed: onContinue,
            child: Text(
              context.ota(
                'onboardingSeeHowAction',
                tr: 'Nasıl çalıştığını gör',
                en: 'See how it works',
              ),
            ),
          ),
          TextButton(
            onPressed: onSignIn,
            child: Text(
              context.ota(
                'onboardingExistingAccount',
                tr: 'Zaten hesabım var',
                en: 'I already have an account',
              ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MEAL CLARITY',
            style: TextStyle(
              color: AppColors.limeDark,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.ota(
              'onboardingWelcomeTitle',
              tr: 'Yemeğini anlat. Gerisini birlikte netleştirelim.',
              en: 'Describe your meal. We will clarify the rest together.',
            ),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            context.ota(
              'onboardingWelcomeBody',
              tr: 'Doğal şekilde yaz; yalnızca sonucu gerçekten etkileyen noktaları kontrol et.',
              en: 'Write naturally; only review details that truly affect the result.',
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.feature),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.asset(
                'assets/images/onboarding_breakfast_hero.webp',
                fit: BoxFit.cover,
                alignment: const Alignment(0, 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccuracyDemoStep extends StatelessWidget {
  const _AccuracyDemoStep({
    required this.analyzed,
    required this.selectedPortion,
    required this.onAnalyze,
    required this.onSelectPortion,
    required this.onContinue,
    super.key,
  });

  final bool analyzed;
  final String selectedPortion;
  final VoidCallback onAnalyze;
  final ValueChanged<String> onSelectPortion;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      footer: FilledButton(
        key: const Key('demo-continue'),
        onPressed: analyzed ? onContinue : onAnalyze,
        child: Text(
          analyzed
              ? context.ota(
                  'onboardingDemoContinue',
                  tr: 'Anladım, devam et',
                  en: 'Got it, continue',
                )
              : context.ota(
                  'onboardingAnalyzeExample',
                  tr: 'Örneği analiz et',
                  en: 'Analyze the example',
                ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.ota(
              'onboardingAccuracyTitle',
              tr: 'Emin olduğumuzu çözeriz.',
              en: 'We resolve what we are sure about.',
            ),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            context.ota(
              'onboardingAccuracyBody',
              tr: 'Belirsizliği saklamayız. Yalnızca önemli olduğunda sana sorarız.',
              en: 'We do not hide uncertainty. We ask only when it matters.',
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          const _DemoInput(),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            child: analyzed
                ? Column(
                    children: [
                      _DetectedItem(
                        title: context.ota(
                          'demoEggsTitle',
                          tr: '2 Yumurta',
                          en: '2 Eggs',
                        ),
                        detail: context.ota(
                          'demoEggsDetail',
                          tr: '2 adet · yüksek güven',
                          en: '2 pieces · high confidence',
                        ),
                        needsReview: false,
                      ),
                      _DetectedItem(
                        title: context.ota(
                          'demoSimitTitle',
                          tr: 'Simit',
                          en: 'Simit',
                        ),
                        detail: context.ota(
                          'demoSimitDetail',
                          tr: '½ adet · yüksek güven',
                          en: '½ piece · high confidence',
                        ),
                        needsReview: false,
                      ),
                      _DetectedItem(
                        title: context.ota(
                          'demoCheeseTitle',
                          tr: 'Beyaz peynir',
                          en: 'White cheese',
                        ),
                        detail: context.ota(
                          'demoCheeseDetail',
                          tr: 'Miktarı kontrol et',
                          en: 'Check the amount',
                        ),
                        needsReview: true,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _PortionChoice(
                            label: context.l10n.portionSmall,
                            asset: 'assets/images/portion_cheese_small.webp',
                            selected: selectedPortion == 'small',
                            onTap: () => onSelectPortion('small'),
                          ),
                          const SizedBox(width: 8),
                          _PortionChoice(
                            label: context.l10n.portionEstimate,
                            asset: 'assets/images/portion_cheese_regular.webp',
                            selected: selectedPortion == 'regular',
                            onTap: () => onSelectPortion('regular'),
                          ),
                          const SizedBox(width: 8),
                          _PortionChoice(
                            label: context.l10n.portionLarge,
                            asset: 'assets/images/portion_cheese_large.webp',
                            selected: selectedPortion == 'large',
                            onTap: () => onSelectPortion('large'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.ota(
                          'onboardingPortionHint',
                          tr: 'Görseller göreli seçimdir; kesin miktarı her zaman girebilirsin.',
                          en: 'Images are relative choices; you can always enter the exact amount.',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _DemoInput extends StatelessWidget {
  const _DemoInput();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        context.ota(
          'onboardingDemoInput',
          tr: '“2 yumurta, biraz peynir ve yarım simit”',
          en: '“2 eggs, some cheese, and half a simit”',
        ),
      ),
    );
  }
}

class _DetectedItem extends StatelessWidget {
  const _DetectedItem({
    required this.title,
    required this.detail,
    required this.needsReview,
  });

  final String title;
  final String detail;
  final bool needsReview;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title, $detail',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          needsReview ? Icons.help_outline_rounded : Icons.check_circle_rounded,
          color: needsReview ? AppColors.warning : AppColors.limeDark,
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(detail),
      ),
    );
  }
}

class _PortionChoice extends StatelessWidget {
  const _PortionChoice({
    required this.label,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: context.ota(
          'cheesePortionSemantics',
          tr: '{label} peynir porsiyonu',
          en: '{label} cheese portion',
          replacements: {'label': label},
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.limeDark : AppColors.line,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(asset, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (selected) ...[
                      const Icon(Icons.check, size: 14),
                      const SizedBox(width: 2),
                    ],
                    Flexible(
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonalizationStep extends StatelessWidget {
  const _PersonalizationStep({
    required this.viewModel,
    required this.calorieController,
    required this.calorieError,
    required this.onFinish,
    required this.onIntentionChanged,
    super.key,
  });

  final OnboardingViewModel viewModel;
  final TextEditingController calorieController;
  final String? calorieError;
  final VoidCallback onFinish;
  final ValueChanged<TrackingIntention> onIntentionChanged;

  @override
  Widget build(BuildContext context) {
    final intention = viewModel.draft.intention;
    return _StepFrame(
      footer: FilledButton(
        key: const Key('onboarding-finish'),
        onPressed: intention == null ? null : onFinish,
        child: Text(
          context.ota(
            'createAccountAction',
            tr: 'Hesabımı oluştur',
            en: 'Create my account',
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.ota(
              'personalizationTitle',
              tr: 'Sana uygun bir başlangıç yapalım.',
              en: 'Let us tailor your starting point.',
            ),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            context.ota(
              'personalizationBody',
              tr: 'Burada yalnızca uygulamanın neyi öne çıkaracağını seçiyorsun.',
              en: 'Here you only choose what the app should emphasize.',
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          _IntentTile(
            key: const Key('intent-understand'),
            title: context.ota(
              'intentUnderstand',
              tr: 'Ne yediğimi daha iyi anlamak',
              en: 'Better understand what I eat',
            ),
            value: TrackingIntention.understand,
            groupValue: intention,
            onChanged: onIntentionChanged,
          ),
          _IntentTile(
            title: context.ota(
              'intentProtein',
              tr: 'Proteinimi takip etmek',
              en: 'Track my protein',
            ),
            value: TrackingIntention.protein,
            groupValue: intention,
            onChanged: onIntentionChanged,
          ),
          _IntentTile(
            title: context.ota(
              'intentCalories',
              tr: 'Kalori hedefimi takip etmek',
              en: 'Track my calorie goal',
            ),
            value: TrackingIntention.calories,
            groupValue: intention,
            onChanged: onIntentionChanged,
          ),
          if (intention == TrackingIntention.calories) ...[
            const SizedBox(height: 12),
            TextField(
              key: const Key('calorie-target'),
              controller: calorieController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.ota(
                  'dailyGoalOptional',
                  tr: 'Günlük hedef (isteğe bağlı)',
                  en: 'Daily goal (optional)',
                ),
                suffixText: 'kcal',
                errorText: calorieError,
                helperText: context.ota(
                  'dailyGoalHelper',
                  tr: 'Demo önerisi: 2.100 kcal — tıbbi tavsiye değildir.',
                  en: 'Demo suggestion: 2,100 kcal — not medical advice.',
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            context.ota(
              'medicalDisclaimer',
              tr: 'Meal Clarity tahmin sunar; tıbbi tavsiye vermez.',
              en: 'Meal Clarity provides estimates, not medical advice.',
            ),
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _IntentTile extends StatelessWidget {
  const _IntentTile({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    super.key,
  });

  final String title;
  final TrackingIntention value;
  final TrackingIntention? groupValue;
  final ValueChanged<TrackingIntention> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.limeDark : AppColors.line,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? AppColors.limeDark : AppColors.muted,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepFrame extends StatelessWidget {
  const _StepFrame({required this.child, required this.footer});

  final Widget child;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: child,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: footer,
          ),
        ],
      ),
    );
  }
}
