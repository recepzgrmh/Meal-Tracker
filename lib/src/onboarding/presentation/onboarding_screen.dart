import 'package:flutter/material.dart';

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
      setState(() => _calorieError = error);
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
            body: Center(child: CircularProgressIndicator()),
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
                    tooltip: 'Geri',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
          ),
          const Spacer(),
          Semantics(
            label: '3 adımdan ${step + 1}.si',
            child: Text(
              '${step + 1} / 3',
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
            child: const Text('Nasıl çalıştığını gör'),
          ),
          TextButton(
            onPressed: onSignIn,
            child: const Text('Zaten hesabım var'),
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
            'Yemeğini anlat. Gerisini birlikte netleştirelim.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Doğal şekilde yaz; yalnızca sonucu gerçekten etkileyen noktaları kontrol et.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
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
        child: Text(analyzed ? 'Anladım, devam et' : 'Örneği analiz et'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emin olduğumuzu çözeriz.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Belirsizliği saklamayız. Yalnızca önemli olduğunda sana sorarız.',
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
                      const _DetectedItem(
                        title: '2 Yumurta',
                        detail: '2 adet · yüksek güven',
                        needsReview: false,
                      ),
                      const _DetectedItem(
                        title: 'Simit',
                        detail: '½ adet · yüksek güven',
                        needsReview: false,
                      ),
                      const _DetectedItem(
                        title: 'Beyaz peynir',
                        detail: 'Miktarı kontrol et',
                        needsReview: true,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _PortionChoice(
                            label: 'Az',
                            asset: 'assets/images/portion_cheese_small.webp',
                            selected: selectedPortion == 'small',
                            onTap: () => onSelectPortion('small'),
                          ),
                          const SizedBox(width: 8),
                          _PortionChoice(
                            label: 'Tahmin',
                            asset: 'assets/images/portion_cheese_regular.webp',
                            selected: selectedPortion == 'regular',
                            onTap: () => onSelectPortion('regular'),
                          ),
                          const SizedBox(width: 8),
                          _PortionChoice(
                            label: 'Fazla',
                            asset: 'assets/images/portion_cheese_large.webp',
                            selected: selectedPortion == 'large',
                            onTap: () => onSelectPortion('large'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Görseller göreli seçimdir; kesin miktarı her zaman girebilirsin.',
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
      child: const Text('“2 yumurta, biraz peynir ve yarım simit”'),
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
        label: '$label peynir porsiyonu',
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
        child: const Text('Hesabımı oluştur'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sana uygun bir başlangıç yapalım.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Burada yalnızca uygulamanın neyi öne çıkaracağını seçiyorsun.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          _IntentTile(
            title: 'Ne yediğimi daha iyi anlamak',
            value: TrackingIntention.understand,
            groupValue: intention,
            onChanged: onIntentionChanged,
          ),
          _IntentTile(
            title: 'Proteinimi takip etmek',
            value: TrackingIntention.protein,
            groupValue: intention,
            onChanged: onIntentionChanged,
          ),
          _IntentTile(
            title: 'Kalori hedefimi takip etmek',
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
                labelText: 'Günlük hedef (isteğe bağlı)',
                suffixText: 'kcal',
                errorText: calorieError,
                helperText:
                    'Demo önerisi: 2.100 kcal — tıbbi tavsiye değildir.',
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Meal Clarity tahmin sunar; tıbbi tavsiye vermez.',
            style: TextStyle(color: AppColors.muted),
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
