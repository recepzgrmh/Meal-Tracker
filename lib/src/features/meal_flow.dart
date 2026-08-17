import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../data/meal_repository.dart';
import '../domain/meal_analysis_input.dart';
import '../domain/models.dart';
import '../media/meal_photo_picker.dart';
import '../theme/app_theme.dart';
import '../view_models/meal_flow_view_model.dart';

class MealFlow extends StatefulWidget {
  const MealFlow({super.key, required this.repository, this.photoPicker});

  final MealRepository repository;
  final MealPhotoPicker? photoPicker;

  @override
  State<MealFlow> createState() => _MealFlowState();
}

class _MealFlowState extends State<MealFlow> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late final MealFlowViewModel _viewModel;
  late final MealPhotoPicker _photoPicker;
  MealPhotoAttachment? _photo;
  String? _photoError;

  @override
  void initState() {
    super.initState();
    _viewModel = MealFlowViewModel(repository: widget.repository);
    _photoPicker = widget.photoPicker ?? ImagePickerMealPhotoPicker();
    _controller.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _recoverLostPhoto();
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    _focusNode.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _analyze() async {
    if (_controller.text.trim().isEmpty && _photo == null) return;
    FocusScope.of(context).unfocus();
    final language = Localizations.localeOf(context).languageCode;
    await _viewModel.analyze(
      MealAnalysisInput(
        text: _controller.text.trim(),
        locale: language == 'en' ? 'en-US' : 'tr-TR',
        photo: _photo,
      ),
    );
  }

  Future<void> _recoverLostPhoto() async {
    try {
      final photo = await _photoPicker.recoverLost();
      if (photo != null && mounted) _setPhoto(photo);
    } catch (_) {
      // Recovery is best-effort and should never block text meal logging.
    }
  }

  Future<void> _pickPhoto(MealPhotoSource source) async {
    try {
      final photo = await _photoPicker.pick(source);
      if (photo != null && mounted) _setPhoto(photo);
    } catch (_) {
      if (mounted) setState(() => _photoError = context.l10n.mealPhotoError);
    }
  }

  void _setPhoto(MealPhotoAttachment photo) {
    setState(() {
      if (photo.byteLength > 8 * 1024 * 1024) {
        _photo = null;
        _photoError = context.l10n.mealPhotoTooLarge;
      } else {
        _photo = photo;
        _photoError = null;
      }
    });
  }

  Future<void> _showPhotoSourceSheet() async {
    final source = await showModalBottomSheet<MealPhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(context.l10n.mealCamera),
                onTap: () => Navigator.pop(context, MealPhotoSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(context.l10n.mealGallery),
                onTap: () => Navigator.pop(context, MealPhotoSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source != null && mounted) await _pickPhoto(source);
  }

  Future<void> _reviewItem(MealItem item) async {
    final updated = item.matchState == MatchState.checkType
        ? await _showTypeSheet(item)
        : await _showPortionSheet(item);
    if (updated == null || !mounted) return;
    _viewModel.updateItem(updated);
  }

  Future<MealItem?> _showTypeSheet(MealItem item) {
    return showModalBottomSheet<MealItem>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.mealTypeQuestion,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.mealTypeExplanation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            for (final label in [
              context.l10n.yogurtWhole,
              context.l10n.yogurtStrained,
              context.l10n.yogurtLight,
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(label),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(
                  context,
                  item.copyWith(matchState: MatchState.matched),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<MealItem?> _showPortionSheet(MealItem item) {
    final options = <({String label, String detail, double grams})>[
      (label: context.l10n.portionSmall, detail: '≈ 15 g', grams: 15),
      (label: context.l10n.portionEstimate, detail: '≈ 30 g', grams: 30),
      (label: context.l10n.portionLarge, detail: '≈ 50 g', grams: 50),
    ];
    return showModalBottomSheet<MealItem>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.mealCheeseAmountQuestion,
              key: const Key('portion-title'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.mealCheeseAmountExplanation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                for (var index = 0; index < options.length; index++) ...[
                  Expanded(
                    child: _PortionOption(
                      option: options[index],
                      selected: options[index].grams == item.grams,
                      onTap: () => Navigator.pop(
                        context,
                        item.copyWith(
                          grams: options[index].grams,
                          portionLabel: '${options[index].grams.round()} g',
                          matchState: MatchState.matched,
                        ),
                      ),
                    ),
                  ),
                  if (index < options.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: () {},
                child: Text(context.l10n.portionExact),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => PopScope(
        canPop: _viewModel.step == MealFlowStep.compose,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _viewModel.step != MealFlowStep.compose) {
            _viewModel.showComposer();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.canvas,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              tooltip: _viewModel.step == MealFlowStep.compose
                  ? context.l10n.commonClose
                  : context.l10n.commonBack,
              onPressed: () {
                if (_viewModel.step == MealFlowStep.compose) {
                  Navigator.pop(context);
                } else {
                  _viewModel.showComposer();
                }
              },
              icon: Icon(
                _viewModel.step == MealFlowStep.compose
                    ? Icons.close_rounded
                    : Icons.arrow_back_rounded,
              ),
            ),
            title: Text(
              _viewModel.step == MealFlowStep.review
                  ? context.l10n.mealReviewTitle
                  : '',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: switch (_viewModel.step) {
              MealFlowStep.compose => _Composer(
                key: const ValueKey('composer'),
                controller: _controller,
                focusNode: _focusNode,
                error: _viewModel.error,
                photoError: _photoError,
                photo: _photo,
                onAddPhoto: _showPhotoSourceSheet,
                onRemovePhoto: () => setState(() => _photo = null),
                onAnalyze: _analyze,
              ),
              MealFlowStep.analyzing => const _Analyzing(
                key: ValueKey('analyzing'),
              ),
              MealFlowStep.review => _Review(
                key: const ValueKey('review'),
                draft: _viewModel.draft!,
                onReviewItem: _reviewItem,
                onLog: () => Navigator.pop(context, _viewModel.draft),
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.error,
    required this.photoError,
    required this.photo,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onAnalyze,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? error;
  final String? photoError;
  final MealPhotoAttachment? photo;
  final VoidCallback onAddPhoto;
  final VoidCallback onRemovePhoto;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 34),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.mealComposeTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 9),
                Text(
                  context.l10n.mealComposeSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                TextField(
                  key: const Key('meal-input'),
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 4,
                  maxLines: 7,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: context.l10n.mealInputHint,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 10, bottom: 68),
                      child: IconButton.filled(
                        tooltip: context.l10n.mealVoiceInput,
                        onPressed: () {},
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.lime,
                          foregroundColor: AppColors.ink,
                        ),
                        icon: const Icon(Icons.mic_none_rounded),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (photo == null)
                  OutlinedButton.icon(
                    key: const Key('add-photo-button'),
                    onPressed: onAddPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(context.l10n.mealAddPhoto),
                  )
                else
                  Semantics(
                    label: context.l10n.mealPhotoSelected,
                    image: true,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.memory(
                              photo!.bytes,
                              key: const Key('meal-photo-preview'),
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton.filled(
                              key: const Key('remove-photo-button'),
                              tooltip: context.l10n.mealRemovePhoto,
                              onPressed: onRemovePhoto,
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.mealPhotoHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (photoError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    photoError!,
                    style: const TextStyle(color: Color(0xFFD93025)),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    style: const TextStyle(color: Color(0xFFD93025)),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  context.l10n.mealQuickTry,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ExampleChip(
                      label: context.l10n.mealQuickEggCheeseLabel,
                      onTap: () => controller.text =
                          context.l10n.mealQuickEggCheeseValue,
                    ),
                    _ExampleChip(
                      label: context.l10n.mealQuickYogurtLabel,
                      onTap: () =>
                          controller.text = context.l10n.mealQuickYogurtValue,
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton(
                  key: const Key('analyze-button'),
                  onPressed: controller.text.trim().isEmpty && photo == null
                      ? null
                      : onAnalyze,
                  child: Text(context.l10n.mealAnalyze),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _Analyzing extends StatefulWidget {
  const _Analyzing({super.key});

  @override
  State<_Analyzing> createState() => _AnalyzingState();
}

class _AnalyzingState extends State<_Analyzing> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _advance();
  }

  Future<void> _advance() async {
    while (mounted && _index < 2) {
      await Future<void>.delayed(const Duration(milliseconds: 280));
      if (mounted) setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = [
      context.l10n.mealAnalyzingFoods,
      context.l10n.mealAnalyzingPortions,
      context.l10n.mealAnalyzingAmbiguity,
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 5,
                color: AppColors.lime,
                backgroundColor: AppColors.line,
              ),
            ),
            const SizedBox(height: 26),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                labels[_index],
                key: ValueKey(_index),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.mealCatalogNutrition,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({
    super.key,
    required this.draft,
    required this.onReviewItem,
    required this.onLog,
  });

  final MealDraft draft;
  final ValueChanged<MealItem> onReviewItem;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final nutrition = draft.nutrition;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            children: [
              Text(
                draft.reviewCount == 0
                    ? context.l10n.mealMatchedCount(draft.items.length)
                    : context.l10n.mealFoundCount(draft.items.length),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                draft.reviewCount == 0
                    ? context.l10n.mealReadyToLog
                    : context.l10n.mealReviewImpactCount(draft.reviewCount),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F3E5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote_rounded, size: 19),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        draft.inputText,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              for (final item in draft.items)
                _FoodItemRow(item: item, onTap: () => onReviewItem(item)),
              const SizedBox(height: 16),
              _MealTotals(nutrition: nutrition),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            22,
            14,
            22,
            14 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: FilledButton(
            key: const Key('review-primary-button'),
            onPressed: draft.reviewCount == 0
                ? onLog
                : () {
                    final item = draft.items.firstWhere(
                      (candidate) => candidate.matchState != MatchState.matched,
                    );
                    onReviewItem(item);
                  },
            child: Text(
              draft.reviewCount == 0
                  ? context.l10n.mealLog
                  : context.l10n.mealReviewPoints(draft.reviewCount),
            ),
          ),
        ),
      ],
    );
  }
}

class _FoodItemRow extends StatelessWidget {
  const _FoodItemRow({required this.item, required this.onTap});

  final MealItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final needsReview = item.matchState != MatchState.matched;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: needsReview ? AppColors.warning : AppColors.line,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: needsReview
                    ? const Color(0xFFFFF3E4)
                    : const Color(0xFFF0F3E5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                item.id == 'egg'
                    ? Icons.egg_alt_outlined
                    : item.id == 'simit'
                    ? Icons.bakery_dining_outlined
                    : Icons.restaurant_outlined,
                color: needsReview ? AppColors.warning : AppColors.limeDark,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.sourceText} → ${item.portionLabel}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (needsReview) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.matchState == MatchState.checkAmount
                          ? context.l10n.mealCheckAmount
                          : context.l10n.mealCheckType,
                      style: const TextStyle(
                        color: Color(0xFFD36B00),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.nutrition.calories.round()}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('kcal', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _MealTotals extends StatelessWidget {
  const _MealTotals({required this.nutrition});

  final Nutrition nutrition;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.mealEstimatedTotal,
            style: const TextStyle(color: Color(0xFFBFC1B9), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            '${nutrition.calories.round()} kcal',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _TotalMacro(
                label: context.l10n.macroProtein,
                value: nutrition.protein,
              ),
              _TotalMacro(
                label: context.l10n.macroCarbs,
                value: nutrition.carbs,
              ),
              _TotalMacro(label: context.l10n.macroFat, value: nutrition.fat),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalMacro extends StatelessWidget {
  const _TotalMacro({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFBFC1B9), fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            '${value.round()} g',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortionOption extends StatelessWidget {
  const _PortionOption({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ({String label, String detail, double grams}) option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('portion-${option.grams.round()}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF4FAD8) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.limeDark : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? AppColors.limeDark : AppColors.muted,
            ),
            const SizedBox(height: 10),
            Text(option.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 3),
            Text(option.detail, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
