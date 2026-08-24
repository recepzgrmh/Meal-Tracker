import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import 'flow_scaffold.dart';
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
  @override
  void initState() {
    super.initState();
    widget.viewModel.initialize();
  }

  Future<void> _goTo(int step) async {
    await widget.viewModel.goToStep(step);
    await widget.onDraftChanged();
  }

  Future<void> _finish() async {
    await widget.viewModel.finishDraft();
    await widget.onDraftChanged();
  }

  Future<void> _signIn() async {
    await widget.viewModel.skipToSignIn();
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
                FlowHeader(
                  step: step,
                  stepCount: 3,
                  onBack: step == 0 ? null : () => _goTo(step - 1),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : AppMotion.standard,
                    child: switch (step) {
                      0 => _WelcomeStep(
                        key: const ValueKey('welcome'),
                        onContinue: () => _goTo(1),
                        onSignIn: _signIn,
                      ),
                      1 => _PhotoGuideStep(
                        key: const ValueKey('photo-guide'),
                        onContinue: () => _goTo(2),
                      ),
                      _ => _TextDemoStep(
                        key: const ValueKey('text-demo'),
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
    return FlowStepLayout(
      centerContent: true,
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
            key: const Key('onboarding-sign-in'),
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
          Text(
            context.ota(
              'onboardingWelcomeTitle',
              tr: 'Yemeğini kaydetmenin daha doğal yolu.',
              en: 'A more natural way to log your meals.',
            ),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.ota(
              'onboardingWelcomeBody',
              tr: 'Fotoğrafını çek veya ne yediğini yaz. Gerisini birlikte netleştiririz.',
              en: 'Take a photo or write what you ate. We clarify the rest together.',
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.large),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.asset(
                'assets/images/onboarding_breakfast_hero.webp',
                fit: BoxFit.cover,
                alignment: const Alignment(0, 0.22),
                semanticLabel: context.ota(
                  'onboardingHeroSemantics',
                  tr: 'Yumurta, simit ve beyaz peynirden oluşan kahvaltı tabağı',
                  en: 'A breakfast plate with eggs, simit, and white cheese',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoGuideStep extends StatelessWidget {
  const _PhotoGuideStep({required this.onContinue, super.key});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return FlowStepLayout(
      footer: FilledButton(
        key: const Key('photo-guide-continue'),
        onPressed: onContinue,
        child: Text(
          context.ota('onboardingContinue', tr: 'Devam et', en: 'Continue'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.ota(
              'photoGuideTitle',
              tr: 'Tabağını net görelim.',
              en: 'Let us see the whole plate.',
            ),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.ota(
              'photoGuideBody',
              tr: 'Yemeğin tamamı kadrajda ve iyi ışıkta olsun. Gerisini biz çözeriz.',
              en: 'Keep the whole meal in frame and well lit. We handle the rest.',
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _CameraGuideVisual(),
          const SizedBox(height: AppSpacing.lg),
          _GuideTip(
            icon: Icons.center_focus_strong_rounded,
            label: context.ota(
              'photoGuideWholePlate',
              tr: 'Tabağın tamamı görünsün',
              en: 'Keep the whole plate visible',
            ),
          ),
          _GuideTip(
            icon: Icons.light_mode_outlined,
            label: context.ota(
              'photoGuideLight',
              tr: 'İyi ışık kullan',
              en: 'Use good lighting',
            ),
          ),
          _GuideTip(
            icon: Icons.zoom_out_rounded,
            label: context.ota(
              'photoGuideDistance',
              tr: 'Çok yakından çekme',
              en: 'Do not shoot too close',
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraGuideVisual extends StatelessWidget {
  const _CameraGuideVisual();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.ota(
        'photoGuideImageSemantics',
        tr: 'Kadrajın tamamında görünen, iyi aydınlatılmış bir kahvaltı tabağı örneği',
        en: 'Example of a well-lit breakfast plate fully visible in frame',
      ),
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/images/breakfast.png', fit: BoxFit.cover),
                const ColoredBox(color: Color(0x12000000)),
                const CustomPaint(painter: _FrameCornersPainter()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FrameCornersPainter extends CustomPainter {
  const _FrameCornersPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const inset = 22.0;
    const length = 30.0;
    final path = Path()
      ..moveTo(inset, inset + length)
      ..lineTo(inset, inset)
      ..lineTo(inset + length, inset)
      ..moveTo(size.width - inset - length, inset)
      ..lineTo(size.width - inset, inset)
      ..lineTo(size.width - inset, inset + length)
      ..moveTo(inset, size.height - inset - length)
      ..lineTo(inset, size.height - inset)
      ..lineTo(inset + length, size.height - inset)
      ..moveTo(size.width - inset - length, size.height - inset)
      ..lineTo(size.width - inset, size.height - inset)
      ..lineTo(size.width - inset, size.height - inset - length);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_FrameCornersPainter oldDelegate) => false;
}

class _GuideTip extends StatelessWidget {
  const _GuideTip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.brand),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

enum _DemoPhase { waiting, typing, analyzing, results, clarify, complete }

class _TextDemoStep extends StatefulWidget {
  const _TextDemoStep({required this.onFinish, super.key});

  final VoidCallback onFinish;

  @override
  State<_TextDemoStep> createState() => _TextDemoStepState();
}

class _TextDemoStepState extends State<_TextDemoStep> {
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  _DemoPhase _phase = _DemoPhase.waiting;
  int _visibleRows = 0;
  int? _selectedGrams;
  int _sequence = 0;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playDemo());
  }

  @override
  void dispose() {
    _sequence++;
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _playDemo() async {
    final run = ++_sequence;
    final text = context.ota(
      'textDemoMeal',
      tr: '2 yumurta, yarım simit ve biraz beyaz peynir yedim',
      en: 'I ate 2 eggs, half a simit, and some white cheese',
    );

    if (_reduceMotion) {
      setState(() {
        _inputController.text = text;
        _phase = _DemoPhase.clarify;
        _visibleRows = 3;
      });
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted || run != _sequence) return;
    setState(() => _phase = _DemoPhase.typing);
    _inputFocus.requestFocus();

    for (var index = 0; index < text.length; index++) {
      final char = text[index];
      final pause = char == ' '
          ? 70
          : char == ','
          ? 120
          : 38 + (index % 4) * 6;
      await Future<void>.delayed(Duration(milliseconds: pause));
      if (!mounted || run != _sequence) return;
      _inputController.value = TextEditingValue(
        text: text.substring(0, index + 1),
        selection: TextSelection.collapsed(offset: index + 1),
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted || run != _sequence) return;
    _inputFocus.unfocus();
    setState(() => _phase = _DemoPhase.analyzing);
    await Future<void>.delayed(const Duration(milliseconds: 720));

    for (var row = 1; row <= 3; row++) {
      if (!mounted || run != _sequence) return;
      setState(() {
        _phase = _DemoPhase.results;
        _visibleRows = row;
      });
      await Future<void>.delayed(const Duration(milliseconds: 220));
    }
    if (!mounted || run != _sequence) return;
    setState(() => _phase = _DemoPhase.clarify);
  }

  void _selectPortion(int grams) {
    setState(() {
      _selectedGrams = grams;
      _phase = _DemoPhase.complete;
    });
  }

  @override
  Widget build(BuildContext context) {
    final complete = _phase == _DemoPhase.complete;
    return FlowStepLayout(
      footer: AnimatedSwitcher(
        duration: _reduceMotion ? Duration.zero : AppMotion.standard,
        child: complete
            ? FilledButton(
                key: const Key('onboarding-finish'),
                onPressed: widget.onFinish,
                child: Text(
                  context.ota(
                    'onboardingStartAction',
                    tr: 'Başlayalım',
                    en: 'Let’s begin',
                  ),
                ),
              )
            : const SizedBox(height: 52),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.ota(
              'textDemoTitle',
              tr: 'İstersen sadece yaz.',
              en: 'Or simply write it.',
            ),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.ota(
              'textDemoBody',
              tr: 'Nasıl söylüyorsan öyle.',
              en: 'Just as you would say it.',
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            key: const Key('demo-meal-input'),
            controller: _inputController,
            focusNode: _inputFocus,
            readOnly: true,
            showCursor: _phase == _DemoPhase.typing,
            maxLines: 3,
            minLines: 2,
            decoration: InputDecoration(
              hintText: context.ota(
                'textDemoPlaceholder',
                tr: 'Ne yedin?',
                en: 'What did you eat?',
              ),
              suffixIcon: AnimatedContainer(
                duration: _reduceMotion ? Duration.zero : AppMotion.fast,
                margin: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: _phase.index >= _DemoPhase.analyzing.index
                      ? AppColors.brand
                      : AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: _phase.index >= _DemoPhase.analyzing.index
                      ? AppColors.onDark
                      : AppColors.muted,
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: _reduceMotion ? Duration.zero : AppMotion.standard,
            alignment: Alignment.topCenter,
            child: _phase == _DemoPhase.analyzing
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: _AnalyzingLine(),
                  )
                : const SizedBox.shrink(),
          ),
          if (_visibleRows > 0) ...[
            const SizedBox(height: AppSpacing.md),
            AnimatedOpacity(
              opacity: _phase.index >= _DemoPhase.clarify.index ? 0.48 : 1,
              duration: _reduceMotion ? Duration.zero : AppMotion.fast,
              child: Column(
                children: [
                  _RevealRow(
                    visible: _visibleRows >= 1,
                    title: context.ota(
                      'demoEggsTitle',
                      tr: '2 yumurta',
                      en: '2 eggs',
                    ),
                    detail: context.ota(
                      'demoEggsDetail',
                      tr: '2 adet',
                      en: '2 pieces',
                    ),
                  ),
                  _RevealRow(
                    visible: _visibleRows >= 2,
                    title: context.ota(
                      'demoSimitTitle',
                      tr: 'Yarım simit',
                      en: 'Half a simit',
                    ),
                    detail: context.ota(
                      'demoSimitDetail',
                      tr: '½ adet',
                      en: '½ piece',
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_visibleRows >= 3)
            _UncertainMealRow(
              phase: _phase,
              selectedGrams: _selectedGrams,
              onSelected: _selectPortion,
            ),
          if (complete) ...[
            const SizedBox(height: AppSpacing.lg),
            _NutritionResult(grams: _selectedGrams!),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.ota(
                'humanLoopMessage',
                tr: 'Emin olduğumuzu çözeriz. Emin olmadığımızda yalnızca gerekli şeyi sana sorarız.',
                en: 'We resolve what we know. When unsure, we ask only what matters.',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _AnalyzingLine extends StatefulWidget {
  @override
  State<_AnalyzingLine> createState() => _AnalyzingLineState();
}

class _AnalyzingLineState extends State<_AnalyzingLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation(AppColors.brand),
            strokeWidth: 2,
            semanticsLabel: context.ota(
              'analysisInProgress',
              tr: 'Öğün çözümleniyor',
              en: 'Analyzing meal',
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          context.ota(
            'analysisInProgress',
            tr: 'Öğünün çözümleniyor…',
            en: 'Analyzing your meal…',
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _RevealRow extends StatelessWidget {
  const _RevealRow({
    required this.visible,
    required this.title,
    required this.detail,
  });

  final bool visible;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      duration: reduceMotion ? Duration.zero : AppMotion.standard,
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 8),
          child: child,
        ),
      ),
      child: _MealResultRow(title: title, detail: detail),
    );
  }
}

class _MealResultRow extends StatelessWidget {
  const _MealResultRow({
    required this.title,
    required this.detail,
    this.confirmed = true,
  });

  final String title;
  final String detail;
  final bool confirmed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title, $detail',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: confirmed
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: AppColors.brand,
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(detail, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UncertainMealRow extends StatelessWidget {
  const _UncertainMealRow({
    required this.phase,
    required this.selectedGrams,
    required this.onSelected,
  });

  final _DemoPhase phase;
  final int? selectedGrams;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final complete = phase == _DemoPhase.complete;
    return AnimatedContainer(
      key: const Key('demo-cheese-row'),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppMotion.standard,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        complete ? AppSpacing.xs : AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: complete ? Colors.transparent : AppColors.reviewSurface,
        border: Border(
          left: BorderSide(
            color: complete ? Colors.transparent : AppColors.warning,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MealResultRow(
            title: context.ota(
              'demoCheeseTitle',
              tr: 'Beyaz peynir',
              en: 'White cheese',
            ),
            detail: complete
                ? '$selectedGrams g'
                : context.ota(
                    'demoCheeseClarify',
                    tr: 'Miktarı netleştirelim',
                    en: 'Let’s clarify the amount',
                  ),
            confirmed: complete,
          ),
          if (!complete) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.ota(
                'demoCheeseQuestion',
                tr: 'Yaklaşık ne kadardı?',
                en: 'About how much was it?',
              ),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [30, 50, 75, 100]
                  .map(
                    (grams) => _PortionButton(
                      grams: grams,
                      suggested: grams == 50,
                      onPressed: () => onSelected(grams),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _PortionButton extends StatelessWidget {
  const _PortionButton({
    required this.grams,
    required this.suggested,
    required this.onPressed,
  });

  final int grams;
  final bool suggested;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: Key('demo-portion-$grams'),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, AppTouchTarget.minimum),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        backgroundColor: suggested ? AppColors.surface : Colors.transparent,
        side: BorderSide(color: suggested ? AppColors.brand : AppColors.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
      ),
      child: Text('$grams g'),
    );
  }
}

class _NutritionResult extends StatelessWidget {
  const _NutritionResult({required this.grams});

  final int grams;

  int get _calories => 290 + (grams * 2.5).round();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: TweenAnimationBuilder<double>(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 420),
        tween: Tween(begin: _calories - 25, end: _calories.toDouble()),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '≈ ${value.round()} kcal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              context.ota(
                'demoMacros',
                tr: '24 g protein · 32 g karbonhidrat · 21 g yağ',
                en: '24 g protein · 32 g carbs · 21 g fat',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
