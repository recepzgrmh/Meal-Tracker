import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';
import '../data/meal_repository.dart';
import '../catalog/food_catalog_repository.dart';
import '../domain/meal_analysis_input.dart';
import '../domain/models.dart';
import '../media/meal_photo_picker.dart';
import '../theme/app_theme.dart';
import '../util/formatters.dart';
import '../util/haptics.dart';
import '../view_models/meal_flow_view_model.dart';
import '../widgets/app_surfaces.dart';

/// One ratio for the meal photo across compose, analyze and review. The steps
/// used to disagree (4/5 then 16/9), so the same plate was recropped as the
/// user advanced; the taller frame keeps a whole plate visible.
const _photoAspectRatio = 4 / 5;

/// Accepted range of the exact-gram entry in the portion sheet.
const _minPortionGrams = 1.0;
const _maxPortionGrams = 2000.0;

class MealFlow extends StatefulWidget {
  const MealFlow({
    super.key,
    required this.repository,
    this.catalogRepository,
    this.photoPicker,
    this.initialPhotoSource,
  });

  final MealRepository repository;
  final FoodCatalogRepository? catalogRepository;
  final MealPhotoPicker? photoPicker;
  final MealPhotoSource? initialPhotoSource;

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

  /// Set when the user abandons the dedicated photo flow, so the text composer
  /// takes over even though the screen was launched from the camera.
  bool _preferTextComposer = false;

  String? _localizedAnalysisError(BuildContext context) {
    if (_viewModel.errorKind == null) return null;
    return switch (_viewModel.errorKind) {
      MealAnalysisFailureKind.noMatch => context.ota(
        'mealErrorNoMatch',
        tr: 'Bu yiyeceği katalogda güvenle eşleştiremedik. Daha açık tarif etmeyi dene.',
        en: 'We could not confidently match this food. Try describing it more clearly.',
      ),
      MealAnalysisFailureKind.unauthenticated => context.ota(
        'mealErrorUnauthenticated',
        tr: 'Oturumun yenilenmeli. Tekrar giriş yapıp deneyebilirsin.',
        en: 'Your session needs to be refreshed. Sign in again and retry.',
      ),
      MealAnalysisFailureKind.invalidRequest => context.ota(
        'mealErrorInvalidRequest',
        tr: 'Açıklamayı anlayamadık. Daha kısa ve net yazmayı dene.',
        en: 'We could not understand the description. Try making it shorter and clearer.',
      ),
      MealAnalysisFailureKind.rateLimited => context.ota(
        'mealErrorRateLimited',
        tr: 'Çok hızlı deneme yaptın. Biraz bekleyip tekrar dene.',
        en: 'You tried too quickly. Wait a moment and retry.',
      ),
      // Only a transport or provider failure justifies pointing at the user's
      // connection. A server fault is ours, and saying otherwise sends them to
      // debug their wifi over our bug.
      MealAnalysisFailureKind.serverError => context.ota(
        'mealErrorServer',
        tr: 'Bizim tarafımızda bir sorun çıktı. Birazdan tekrar deneyebilirsin.',
        en: 'Something went wrong on our side. You can try again shortly.',
      ),
      _ => context.ota(
        'mealErrorUnavailable',
        tr: 'Öğünü analiz edemedik. Bağlantını kontrol edip tekrar dene.',
        en: 'We could not analyze the meal. Check your connection and try again.',
      ),
    };
  }

  @override
  void initState() {
    super.initState();
    _viewModel = MealFlowViewModel(
      repository: widget.repository,
      catalogRepository: widget.catalogRepository,
    );
    _photoPicker = widget.photoPicker ?? ImagePickerMealPhotoPicker();
    _controller.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialPhotoSource == null) {
        _focusNode.requestFocus();
      } else {
        _startInitialPhotoFlow();
      }
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
    // Several seconds have passed with the phone likely face-down or the user
    // looking elsewhere. This is the "come back, it's ready" tap — and it only
    // fires on the path that actually reached a result, so a failure or a
    // response the view model discarded as stale stays silent.
    if (!mounted || _viewModel.step != MealFlowStep.review) return;
    AppHaptics.arrived();
    await _runClarificationQueue();
  }

  /// Asks the questions the analysis could not answer on its own, one sheet at
  /// a time, before the review screen is read.
  ///
  /// These sheets existed before but only opened when the user thought to tap
  /// the flagged row, so the most consequential number in the meal — how much
  /// of an amorphous food was on the plate — was left at a default that the
  /// user never saw a prompt to correct. Portion is the dominant error source
  /// in dietary self-report, so it is asked, not offered.
  ///
  /// Dismissing a sheet skips that item and moves on: this walks the user
  /// through the questions, it does not trap them behind one.
  Future<void> _runClarificationQueue() async {
    final queued = _viewModel.draft?.items
        .where(
          (item) =>
              item.matchState == MatchState.checkType ||
              item.matchState == MatchState.checkAmount,
        )
        .map((item) => item.id)
        .toList(growable: false);
    if (queued == null || queued.isEmpty) return;

    for (final id in queued) {
      if (!mounted) return;
      // Answering one question rebuilds the draft, so each item is re-read by
      // id rather than held across the await: an earlier answer (or a manual
      // edit inside a sheet) may already have resolved this one.
      final items = _viewModel.draft?.items ?? const <MealItem>[];
      final index = items.indexWhere((item) => item.id == id);
      if (index < 0) continue;
      final current = items[index];
      if (current.matchState == MatchState.matched ||
          current.matchState == MatchState.notFound) {
        continue;
      }
      await _reviewItem(current);
    }
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

  Future<void> _startInitialPhotoFlow() async {
    final source = widget.initialPhotoSource!;
    if (source == MealPhotoSource.camera) {
      final shouldContinue = await _showScanGuideIfNeeded();
      if (!shouldContinue) {
        if (mounted) Navigator.pop(context);
        return;
      }
    }
    try {
      final photo = await _photoPicker.pick(source);
      if (!mounted) return;
      if (photo == null) {
        Navigator.pop(context);
        return;
      }
      _setPhoto(photo);
    } catch (_) {
      if (mounted) setState(() => _photoError = context.l10n.mealPhotoError);
    }
  }

  Future<bool> _showScanGuideIfNeeded() async {
    const key = 'meal_scan_guide_seen';
    try {
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getBool(key) == true) return true;
      if (!mounted) return false;
      final shouldContinue = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _ScanGuideDialog(),
      );
      if (shouldContinue == true) await preferences.setBool(key, true);
      return shouldContinue == true;
    } catch (_) {
      return true;
    }
  }

  Future<void> _retakeDedicatedPhoto() async {
    final previous = _photo;
    setState(() {
      _photo = null;
      _photoError = null;
    });
    try {
      final photo = await _photoPicker.pick(widget.initialPhotoSource!);
      if (!mounted) return;
      // Cancelling a retake used to close the whole flow. The previous photo
      // comes back instead so the user can retry or leave deliberately.
      if (photo == null) {
        setState(() => _photo = previous);
        return;
      }
      _setPhoto(photo);
    } catch (_) {
      if (mounted) {
        setState(() {
          _photo = previous;
          _photoError = context.l10n.mealPhotoError;
        });
      }
    }
  }

  void _continueWithText() {
    setState(() {
      _photo = null;
      _photoError = null;
      _preferTextComposer = true;
    });
    _focusNode.requestFocus();
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
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
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

  Future<void> _editEatenAt() async {
    final now = DateTime.now();
    final current = _viewModel.draft?.eatenAt ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;
    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    // A meal cannot have been eaten in the future; the time picker has no
    // bounds of its own, so today's picks are clamped to now.
    _viewModel.setEatenAt(picked.isAfter(DateTime.now()) ? null : picked);
  }

  /// One sheet, three intents: start a draft from scratch, add a missing food
  /// to the draft, or — when [replaceItem] is set — swap an AI-estimate row
  /// for the picked catalog food.
  Future<void> _showManualSearch({
    bool addToDraft = false,
    MealItem? replaceItem,
  }) async {
    final queryController = TextEditingController(
      text: replaceItem != null
          ? (replaceItem.sourceText.trim().isNotEmpty
                ? replaceItem.sourceText.trim()
                : replaceItem.canonicalName.trim())
          : _controller.text.trim(),
    );
    final locale = _catalogLocale(context);
    final mealName = _localizedMealName(context, DateTime.now());
    await _viewModel.searchCatalog(queryController.text, locale);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xxs,
            AppSpacing.page,
            AppSpacing.lg + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.catalogSearchTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.catalogSearchExplanation,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('manual-catalog-query'),
                  controller: queryController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: context.l10n.catalogSearchHint,
                    suffixIcon: IconButton(
                      onPressed: () => _viewModel.searchCatalog(
                        queryController.text,
                        locale,
                      ),
                      icon: const Icon(Icons.search_rounded),
                    ),
                  ),
                  onSubmitted: (value) =>
                      _viewModel.searchCatalog(value, locale),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _viewModel,
                    builder: (context, _) {
                      if (_viewModel.isSearchingCatalog) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (_viewModel.catalogSearchError != null) {
                        return Center(
                          child: Text(context.l10n.catalogSearchError),
                        );
                      }
                      if (_viewModel.catalogResults.isEmpty) {
                        return Center(
                          child: Text(context.l10n.catalogSearchEmpty),
                        );
                      }
                      return ListView.separated(
                        itemCount: _viewModel.catalogResults.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final candidate = _viewModel.catalogResults[index];
                          return ListTile(
                            key: Key('catalog-result-${candidate.foodId}'),
                            contentPadding: EdgeInsets.zero,
                            title: Text(candidate.name),
                            subtitle: Text(
                              // Without a published portion there is no gram
                              // figure to show; showing the alias alone is
                              // honest, inventing one is not.
                              candidate.defaultGrams == null
                                  ? candidate.matchedAlias
                                  : context.ota(
                                      'catalogCandidateSummary',
                                      tr: '{alias} · {grams} g',
                                      en: '{alias} · {grams} g',
                                      replacements: {
                                        'alias': candidate.matchedAlias,
                                        'grams': candidate.defaultGrams!
                                            .round(),
                                      },
                                    ),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              if (replaceItem != null) {
                                _viewModel.replaceWithManualFood(
                                  replaceItem,
                                  candidate,
                                  queryController.text.trim(),
                                );
                              } else if (addToDraft) {
                                _viewModel.addManualFood(
                                  candidate,
                                  queryController.text.trim(),
                                );
                              } else {
                                _viewModel.selectManualFood(
                                  candidate,
                                  queryController.text.trim(),
                                  mealName: mealName,
                                );
                              }
                              Navigator.pop(sheetContext);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    queryController.dispose();
  }

  /// The "which type?" question, answered from the catalog.
  ///
  /// Without a catalog there is nothing real to choose between, so the flow
  /// asks about the amount instead of rendering options that cannot change the
  /// nutrition.
  Future<MealItem?> _showTypeSheet(MealItem item) async {
    if (!_viewModel.canSearchCatalog) return _showPortionSheet(item);
    final locale = _catalogLocale(context);
    await _viewModel.searchItemVariants(item, locale);
    if (!mounted) return null;
    return showModalBottomSheet<MealItem>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xxs,
            AppSpacing.page,
            AppSpacing.x28,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.mealTypeQuestion,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.mealTypeExplanation,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _viewModel,
                    builder: (context, _) {
                      if (_viewModel.isSearchingVariants) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (_viewModel.variantSearchError != null) {
                        return _SheetMessage(
                          text: context.l10n.catalogSearchError,
                        );
                      }
                      final candidates = _viewModel.variantResults;
                      if (candidates.isEmpty) {
                        return _SheetMessage(
                          text: context.l10n.catalogSearchEmpty,
                        );
                      }
                      return ListView.separated(
                        itemCount: candidates.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final candidate = candidates[index];
                          return ListTile(
                            key: Key('variant-${candidate.foodId}'),
                            contentPadding: EdgeInsets.zero,
                            title: Text(naturalFoodDisplayName(candidate.name)),
                            subtitle: Text(
                              context.ota(
                                'caloriesPer100g',
                                tr: '{amount} kcal / 100 g',
                                en: '{amount} kcal / 100 g',
                                replacements: {
                                  'amount': candidate.caloriesPer100g.round(),
                                },
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.pop(
                              sheetContext,
                              _applyVariant(item, candidate),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  MealItem _applyVariant(MealItem item, CatalogFoodCandidate candidate) =>
      item.copyWith(
        foodId: candidate.foodId,
        canonicalName: candidate.name,
        displayName: naturalFoodDisplayName(candidate.name),
        // `nutritionSource` is a database identity ("canonical_v2_lean:cf2_9a15…")
        // and was being shown to the user verbatim. The catalog row's own name
        // is the provenance that actually answers "where did this number come
        // from".
        sourceName: candidate.name,
        nutritionPer100g: Nutrition(
          calories: candidate.caloriesPer100g,
          protein: candidate.proteinPer100g,
          carbs: candidate.carbsPer100g,
          fat: candidate.fatPer100g,
        ),
        confidence: candidate.score,
        matchMethod: 'variant',
        matchState: MatchState.matched,
      );

  Future<MealItem?> _showPortionSheet(MealItem item) async {
    final estimated = item.grams.clamp(5, 500).toDouble();
    final catalogOptions = _rankedCatalogPortions(item.portionOptions);
    final options = catalogOptions.length >= 2
        ? catalogOptions
              .map(
                (option) => (
                  label: _portionSizeLabel(context, option),
                  detail: '${option.grams.round()} g',
                  grams: option.grams,
                  sizeClass: option.sizeClass,
                  imageUrl: option.imageUrl,
                ),
              )
              .toList(growable: false)
        : <
            ({
              String label,
              String detail,
              double grams,
              String? sizeClass,
              String? imageUrl,
            })
          >[
            (
              label: context.l10n.portionSmall,
              detail: '${(estimated * .5).round()} g',
              grams: (estimated * .5).roundToDouble(),
              sizeClass: 'small',
              imageUrl: null,
            ),
            (
              label: _regularPortionLabel(context),
              detail: '${estimated.round()} g',
              grams: estimated,
              sizeClass: 'regular',
              imageUrl: null,
            ),
            (
              label: context.l10n.portionLarge,
              detail: '${(estimated * 1.5).round()} g',
              grams: (estimated * 1.5).roundToDouble(),
              sizeClass: 'large',
              imageUrl: null,
            ),
          ];
    final result = await showModalBottomSheet<MealItem>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        // Large text and small phones push the three reference cards plus the
        // exact-gram row past the sheet height, so the content scrolls instead
        // of overflowing.
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xxs,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.ota(
                    'portionQuestion',
                    tr: '{item} miktarı',
                    en: '{item} amount',
                    replacements: {'item': item.name},
                  ),
                  key: const Key('portion-title'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.ota(
                    'portionQuestionBody',
                    tr: 'En yakın seçeneği seç. Besin değerlerini buna göre yeniden hesaplayacağız.',
                    en: 'Choose the closest option. We will recalculate the nutrition accordingly.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final largeText =
                        MediaQuery.textScalerOf(context).scale(14) >= 20;
                    final width = largeText
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 20) / 3;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (var index = 0; index < options.length; index++)
                          SizedBox(
                            width: width,
                            child: _PortionOption(
                              option: options[index],
                              foodName: item.name,
                              visualScale: (index + 1) / options.length,
                              // Doubles almost never compare equal, so the
                              // current portion used to look unselected.
                              selected:
                                  (options[index].grams - item.grams).abs() <
                                  0.5,
                              onTap: () => Navigator.pop(
                                context,
                                item.copyWith(
                                  grams: options[index].grams,
                                  portionLabel:
                                      '${options[index].grams.round()} g',
                                  matchState: MatchState.matched,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  context.ota(
                    'orEnterGrams',
                    tr: 'veya gram gir',
                    en: 'or enter grams',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                _PortionGramField(
                  onApply: (grams) => Navigator.pop(
                    context,
                    item.copyWith(
                      grams: grams,
                      portionLabel: '${grams.round()} g',
                      matchState: MatchState.matched,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return result;
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
              _stepTitle(context, _viewModel.step),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          body: SafeArea(
            top: false,
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : AppMotion.slow,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: switch (_viewModel.step) {
                MealFlowStep.compose =>
                  widget.initialPhotoSource == null || _preferTextComposer
                      ? _Composer(
                          key: const ValueKey('composer'),
                          controller: _controller,
                          focusNode: _focusNode,
                          error: _localizedAnalysisError(context),
                          photoError: _photoError,
                          photo: _photo,
                          onAddPhoto: _showPhotoSourceSheet,
                          onRemovePhoto: () => setState(() => _photo = null),
                          onAnalyze: _analyze,
                          onManualSearch:
                              _viewModel.manualSearchSuggested &&
                                  _viewModel.canSearchCatalog
                              ? _showManualSearch
                              : null,
                        )
                      : _DedicatedPhotoComposer(
                          key: const ValueKey('dedicated-photo-composer'),
                          photo: _photo,
                          error:
                              _photoError ?? _localizedAnalysisError(context),
                          source: widget.initialPhotoSource!,
                          controller: _controller,
                          focusNode: _focusNode,
                          onRetake: _retakeDedicatedPhoto,
                          onAnalyze: _analyze,
                          onUseText: _continueWithText,
                        ),
                MealFlowStep.analyzing => _Analyzing(
                  key: const ValueKey('analyzing'),
                  photo: _photo,
                  onCancel: _viewModel.showComposer,
                ),
                MealFlowStep.review => _Review(
                  key: const ValueKey('review'),
                  draft: _viewModel.draft!,
                  photo: _photo,
                  onReviewItem: _reviewItem,
                  onRemoveItem: (item) => _viewModel.removeItem(item.id),
                  onReplaceItem: _viewModel.canSearchCatalog
                      ? (item) => _showManualSearch(replaceItem: item)
                      : null,
                  onAddMissing: _viewModel.canSearchCatalog
                      ? () => _showManualSearch(addToDraft: true)
                      : null,
                  onEditEatenAt: _editEatenAt,
                  onLog: () => Navigator.pop(context, _viewModel.draft),
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanGuideDialog extends StatelessWidget {
  const _ScanGuideDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.feature),
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.page,
        AppSpacing.page,
        AppSpacing.lg,
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.76,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ScanGuideVisual(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.ota(
                  'scanGuideTitle',
                  tr: 'Yemeğini nasıl taratırsın?',
                  en: 'How to scan your meal',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.ota(
                  'scanGuideBody',
                  tr: 'Tabağın tamamı görünsün; telefonu mümkün olduğunca yukarıdan ve sabit tut.',
                  en: 'Keep the entire plate visible and hold your phone steady from above.',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                key: const Key('open-meal-camera-button'),
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(
                  context.ota(
                    'openCameraAction',
                    tr: 'Kamerayı aç',
                    en: 'Open camera',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  context.ota('notNowAction', tr: 'Şimdi değil', en: 'Not now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanGuideVisual extends StatelessWidget {
  const _ScanGuideVisual();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: context.ota(
        'scanGuideImageSemantics',
        tr: 'Telefon kamerasıyla yukarıdan taranan yemek tabağı',
        en: 'A plate of food scanned from above with a phone camera',
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.feature),
        child: SizedBox(
          height: 145,
          width: double.infinity,
          child: Image.asset(
            'assets/images/meal-scan-guide.webp',
            fit: BoxFit.cover,
            cacheWidth: 900,
          ),
        ),
      ),
    );
  }
}

class _DedicatedPhotoComposer extends StatelessWidget {
  const _DedicatedPhotoComposer({
    super.key,
    required this.photo,
    required this.error,
    required this.source,
    required this.controller,
    required this.focusNode,
    required this.onRetake,
    required this.onAnalyze,
    required this.onUseText,
  });

  final MealPhotoAttachment? photo;
  final String? error;
  final MealPhotoSource source;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onRetake;
  final VoidCallback onAnalyze;
  final VoidCallback onUseText;

  @override
  Widget build(BuildContext context) {
    if (photo == null) {
      return _PhotoLaunchState(
        error: error,
        onRetry: onRetake,
        onUseText: onUseText,
      );
    }
    final largeText = MediaQuery.textScalerOf(context).scale(14) >= 20;
    final retakeButton = OutlinedButton.icon(
      key: const Key('retake-photo-button'),
      onPressed: onRetake,
      icon: Icon(
        source == MealPhotoSource.camera
            ? Icons.refresh_rounded
            : Icons.photo_library_outlined,
      ),
      label: Text(
        source == MealPhotoSource.camera
            ? context.ota('retakePhotoAction', tr: 'Yeniden çek', en: 'Retake')
            : context.ota(
                'chooseAnotherPhotoAction',
                tr: 'Başka fotoğraf',
                en: 'Another photo',
              ),
      ),
    );
    final analyzeButton = FilledButton.icon(
      key: const Key('analyze-photo-button'),
      onPressed: onAnalyze,
      icon: const Icon(Icons.search_rounded),
      label: Text(
        context.ota(
          'analyzePhotoAction',
          tr: 'Öğünü analiz et',
          en: 'Analyze meal',
        ),
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.xs,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.ota(
              'photoReadyTitle',
              tr: 'Fotoğraf hazır',
              en: 'Photo ready',
            ),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.tiny),
          Text(
            context.ota(
              'photoReadyBody',
              tr: 'Analizden önce tabağın tamamının göründüğünü kontrol et.',
              en: 'Make sure the whole plate is visible before analysis.',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.feature),
            child: AspectRatio(
              aspectRatio: _photoAspectRatio,
              child: Image.memory(
                photo!.bytes,
                key: const Key('dedicated-photo-preview'),
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.ota(
              'photoContextQuestion',
              tr: 'Bir detay eklemek ister misin?',
              en: 'Would you like to add a detail?',
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            key: const Key('photo-context-input'),
            controller: controller,
            focusNode: focusNode,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: context.ota(
                'photoContextHint',
                tr: 'Pilav tavuğun altında, sos yoğurtlu...',
                en: 'The rice is under the chicken, the sauce is yogurt-based...',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (largeText)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                retakeButton,
                const SizedBox(height: AppSpacing.sm),
                analyzeButton,
              ],
            )
          else
            Row(
              children: [
                Expanded(child: retakeButton),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: analyzeButton),
              ],
            ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              liveRegion: true,
              child: Text(
                error!,
                style: const TextStyle(color: AppColors.destructive),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('use-text-instead-button'),
              onPressed: onUseText,
              icon: const Icon(Icons.edit_note_rounded),
              label: Text(_describeMealInsteadLabel(context)),
            ),
          ),
        ],
      ),
    );
  }
}

String _describeMealInsteadLabel(BuildContext context) => context.ota(
  'describeMealInsteadAction',
  tr: 'Fotoğrafsız devam et',
  en: 'Continue without a photo',
);

class _PhotoLaunchState extends StatelessWidget {
  const _PhotoLaunchState({
    required this.error,
    required this.onRetry,
    required this.onUseText,
  });

  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onUseText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.limeSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_camera_outlined, size: 31),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              error == null
                  ? context.ota(
                      'cameraPreparing',
                      tr: 'Kamera hazırlanıyor',
                      en: 'Preparing camera',
                    )
                  : context.ota(
                      'cameraOpenErrorTitle',
                      tr: 'Kamera açılamadı',
                      en: 'Could not open camera',
                    ),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              liveRegion: error != null,
              child: Text(
                error ??
                    context.ota(
                      'cameraPreparingBody',
                      tr: 'Birazdan doğrudan çekim ekranına geçeceksin.',
                      en: 'You will go directly to the camera in a moment.',
                    ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  context.ota(
                    'commonRetry',
                    tr: 'Tekrar dene',
                    en: 'Try again',
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            TextButton.icon(
              onPressed: onUseText,
              icon: const Icon(Icons.edit_note_rounded),
              label: Text(_describeMealInsteadLabel(context)),
            ),
          ],
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
    required this.onManualSearch,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? error;
  final String? photoError;
  final MealPhotoAttachment? photo;
  final VoidCallback onAddPhoto;
  final VoidCallback onRemovePhoto;
  final VoidCallback onAnalyze;
  final VoidCallback? onManualSearch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.md,
          AppSpacing.page,
          AppSpacing.lg,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.mealComposeTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.mealComposeSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  key: const Key('meal-input'),
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 4,
                  maxLines: 7,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: context.l10n.mealInputHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
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
                      borderRadius: BorderRadius.circular(AppRadius.feature),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: _photoAspectRatio,
                            child: Image.memory(
                              photo!.bytes,
                              key: const Key('meal-photo-preview'),
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            ),
                          ),
                          Positioned(
                            top: AppSpacing.xs,
                            right: AppSpacing.xs,
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
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.mealPhotoHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (photoError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      photoError!,
                      style: const TextStyle(color: AppColors.destructive),
                    ),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      error!,
                      style: const TextStyle(color: AppColors.destructive),
                    ),
                  ),
                  if (onManualSearch != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    OutlinedButton.icon(
                      key: const Key('manual-catalog-search-button'),
                      onPressed: onManualSearch,
                      icon: const Icon(Icons.search_rounded),
                      label: Text(context.l10n.catalogSearchAction),
                    ),
                  ],
                ],
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

class _Analyzing extends StatelessWidget {
  const _Analyzing({required this.photo, required this.onCancel, super.key});

  final MealPhotoAttachment? photo;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            key: const Key('analysis-loading-center'),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (photo != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.feature),
                      child: AspectRatio(
                        aspectRatio: _photoAspectRatio,
                        child: Image.memory(
                          photo!.bytes,
                          key: const Key('analyzing-photo-preview'),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  const SizedBox(
                    width: AppSpacing.x56,
                    height: AppSpacing.x56,
                    child: CircularProgressIndicator(
                      strokeWidth: 5,
                      color: AppColors.lime,
                      backgroundColor: AppColors.line,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    context.l10n.mealAnalyzingFoods,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.ota(
                      'mealAnalyzingSummary',
                      tr: 'Yiyecekler ve porsiyonlar tahmin ediliyor.',
                      en: 'Estimating foods and portions.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    key: const Key('cancel-analysis-button'),
                    onPressed: onCancel,
                    child: Text(
                      context.ota(
                        'cancelAnalysisAction',
                        tr: 'Analizi iptal et',
                        en: 'Cancel analysis',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({
    super.key,
    required this.draft,
    required this.photo,
    required this.onReviewItem,
    required this.onRemoveItem,
    required this.onReplaceItem,
    required this.onAddMissing,
    required this.onEditEatenAt,
    required this.onLog,
  });

  final MealDraft draft;
  final MealPhotoAttachment? photo;
  final ValueChanged<MealItem> onReviewItem;
  final ValueChanged<MealItem> onRemoveItem;

  /// Opens the manual catalog search to swap an AI-estimate row for a real
  /// catalog food. Null when no catalog is available to search.
  final ValueChanged<MealItem>? onReplaceItem;
  final VoidCallback? onAddMissing;
  final VoidCallback onEditEatenAt;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final nutrition = draft.nutrition;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              AppSpacing.xl,
            ),
            children: [
              Text(
                context.ota(
                  'mealResultReadyTitle',
                  tr: 'Öğünün hazır',
                  en: 'Your meal is ready',
                ),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.tiny),
              Text(
                draft.reviewCount == 0
                    ? context.ota(
                        'mealReviewReadyBody',
                        tr: 'Yiyecekleri ve toplamları senin için eşleştirdik.',
                        en: 'We matched the foods and totals for you.',
                      )
                    : context.l10n.mealReviewImpactCount(draft.reviewCount),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (photo != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.feature),
                  child: AspectRatio(
                    aspectRatio: _photoAspectRatio,
                    child: Image.memory(
                      photo!.bytes,
                      key: const Key('review-photo-preview'),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (draft.inputText.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.quoteSurface,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote_rounded, size: 19),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          draft.inputText,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              _EatenAtRow(eatenAt: draft.eatenAt, onEdit: onEditEatenAt),
              const SizedBox(height: AppSpacing.xl),
              Text(
                context.ota(
                  'detectedFoodsTitle',
                  tr: 'Bulunan yiyecekler',
                  en: 'Detected foods',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.tiny),
              Text(
                context.l10n.mealFoundCount(draft.items.length),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.compactCard),
                  border: Border.all(color: AppColors.line),
                  boxShadow: AppShadows.card,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < draft.items.length;
                      index++
                    ) ...[
                      _FoodItemRow(
                        item: draft.items[index],
                        onTap: () => onReviewItem(draft.items[index]),
                        onRemove: () => onRemoveItem(draft.items[index]),
                        onReplace:
                            draft.items[index].isAiEstimate &&
                                onReplaceItem != null
                            ? () => onReplaceItem!(draft.items[index])
                            : null,
                      ),
                      if (index < draft.items.length - 1)
                        const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: AppColors.separator,
                        ),
                    ],
                  ],
                ),
              ),
              if (draft.unmatchedText.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _UnmatchedWarning(
                  texts: draft.unmatchedText,
                  onSearch: onAddMissing,
                ),
              ],
              if (onAddMissing != null)
                TextButton.icon(
                  onPressed: onAddMissing,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    context.ota(
                      'addMissingFoodAction',
                      tr: 'Eksik yiyecek ekle',
                      en: 'Add missing food',
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              _MealTotals(nutrition: nutrition),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.md + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.separator)),
          ),
          child: Builder(
            builder: (context) {
              final largeText =
                  MediaQuery.textScalerOf(context).scale(14) >= 20;
              final save = FilledButton(
                key: const Key('review-primary-button'),
                onPressed: draft.items.isEmpty ? null : onLog,
                child: Text(context.l10n.mealLog),
              );
              // The secondary button used to switch between "review" and "add a
              // missing food" behind one changing label. Adding a food lives in
              // the list; this button only ever opens the next open question,
              // and disappears once there is none.
              if (draft.reviewCount == 0) return save;
              final review = OutlinedButton(
                key: const Key('review-edit-button'),
                onPressed: () => onReviewItem(
                  draft.items.firstWhere(
                    (candidate) => candidate.matchState != MatchState.matched,
                  ),
                ),
                child: Text(context.l10n.mealReviewPoints(draft.reviewCount)),
              );
              if (largeText) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    review,
                    const SizedBox(height: AppSpacing.sm),
                    save,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: review),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: save),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FoodItemRow extends StatelessWidget {
  const _FoodItemRow({
    required this.item,
    required this.onTap,
    required this.onRemove,
    this.onReplace,
  });

  final MealItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  /// Offered on AI-estimate rows only: replaces the estimate with a catalog
  /// food through the manual search.
  final VoidCallback? onReplace;

  @override
  Widget build(BuildContext context) {
    final needsReview = item.matchState != MatchState.matched;
    // The estimate keeps its `~` even after the portion question is answered:
    // the nutrition itself is still a model guess, not a catalog row.
    final approximate = needsReview || item.isAiEstimate;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: needsReview ? AppColors.reviewSurface : Colors.transparent,
        border: needsReview
            ? const Border(left: BorderSide(color: AppColors.warning, width: 3))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    // A compact visual density shrank this below the 48 px the
                    // rest of the app guarantees.
                    IconButton(
                      tooltip: context.ota(
                        'removeFoodAction',
                        tr: 'Yiyeceği kaldır',
                        en: 'Remove food',
                      ),
                      onPressed: onRemove,
                      icon: const Icon(Icons.close_rounded, size: 19),
                      constraints: const BoxConstraints(
                        minWidth: AppTouchTarget.minimum,
                        minHeight: AppTouchTarget.minimum,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.tiny),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${approximate ? '~' : ''}${item.grams.round()} g',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Text(
                      '${item.isAiEstimate ? '~' : ''}'
                      '${item.nutrition.calories.round()} kcal',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (item.isAiEstimate) ...[
                  const SizedBox(height: AppSpacing.xs),
                  const _AiEstimateChip(),
                ] else if (item.foodId != null &&
                    item.sourceName.isNotEmpty) ...[
                  // Provenance for catalog-grounded rows; estimate rows carry
                  // the AI chip instead, and it says everything this would.
                  const SizedBox(height: AppSpacing.xs),
                  _ProvenanceLabel(sourceName: item.sourceName),
                ],
                if (needsReview) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: .72),
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: AppColors.reviewInk,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            item.matchState == MatchState.checkAmount
                                ? context.l10n.mealCheckAmount
                                : context.l10n.mealCheckType,
                            style: const TextStyle(
                              color: AppColors.reviewInk,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.reviewInk,
                        ),
                      ],
                    ),
                  ),
                ],
                if (onReplace != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: Key('replace-estimate-${item.id}'),
                      onPressed: onReplace,
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: Text(
                        context.ota(
                          'replaceEstimateAction',
                          tr: 'Katalogdan seç',
                          en: 'Choose from catalog',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The mark that says this row's nutrition came from the model, not the
/// curated catalog. Deliberately not the orange review palette: review means
/// "answer a question", this means "different provenance", and the two can
/// appear on the same row.
class _AiEstimateChip extends StatelessWidget {
  const _AiEstimateChip();

  @override
  Widget build(BuildContext context) {
    final label = context.ota(
      'aiEstimateChip',
      tr: 'Yapay zekâ tahmini',
      en: 'AI estimate',
    );
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Container(
          key: const Key('ai-estimate-chip'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.micro,
          ),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: Border.all(color: AppColors.brand),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 13,
                color: AppColors.brandStrong,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.brandStrong,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where a catalog-grounded row's nutrition comes from. A quiet label, not a
/// judgement — numeric confidence deliberately stays out of the UI.
class _ProvenanceLabel extends StatelessWidget {
  const _ProvenanceLabel({required this.sourceName});

  final String sourceName;

  @override
  Widget build(BuildContext context) {
    final label = context.ota(
      'nutritionSourceLabel',
      tr: 'Kaynak: {source}',
      en: 'Source: {source}',
      replacements: {'source': sourceName},
    );
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Text(
          label,
          key: const Key('provenance-label'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
      ),
    );
  }
}

/// The foods the server could neither ground nor estimate. Non-blocking: the
/// meal stays loggable, this row only names what is missing and offers the
/// manual search as the way to add it.
class _UnmatchedWarning extends StatelessWidget {
  const _UnmatchedWarning({required this.texts, required this.onSearch});

  final List<String> texts;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    final message = context.ota(
      'unmatchedItemsWarning',
      tr: 'Eşleştirilemedi: {items}',
      en: 'Could not match: {items}',
      replacements: {'items': texts.join(', ')},
    );
    return Container(
      key: const Key('unmatched-warning'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      // The review rows' warning grammar: tinted surface, left accent. No
      // corner radius — a non-uniform border cannot carry one.
      decoration: const BoxDecoration(
        color: AppColors.reviewSurface,
        border: Border(left: BorderSide(color: AppColors.warning, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.reviewInk,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.reviewInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (onSearch != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            TextButton.icon(
              key: const Key('unmatched-search-button'),
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(
                context.ota(
                  'unmatchedSearchAction',
                  tr: 'Katalogdan ekle',
                  en: 'Add from catalog',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MealTotals extends StatelessWidget {
  const _MealTotals({required this.nutrition});

  final Nutrition nutrition;

  @override
  Widget build(BuildContext context) {
    return HeroCardSurface(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.lg,
        AppSpacing.page,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.mealEstimatedTotal,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.ota(
              'calorieAmount',
              tr: '{amount} kcal',
              en: '{amount} kcal',
              replacements: {'amount': nutrition.calories.round()},
            ),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _TotalMacro(
                label: context.l10n.macroProtein,
                value: nutrition.protein,
                color: AppColors.protein,
              ),
              _TotalMacro(
                label: context.l10n.macroCarbs,
                value: nutrition.carbs,
                color: AppColors.carbs,
              ),
              _TotalMacro(
                label: context.l10n.macroFat,
                value: nutrition.fat,
                color: AppColors.fat,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalMacro extends StatelessWidget {
  const _TotalMacro({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;

  /// Passed in rather than derived from [label]: the colour used to depend on
  /// the localized text, so a third locale silently painted every macro pink.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.ota(
              'gramAmount',
              tr: '{amount} g',
              en: '{amount} g',
              replacements: {'amount': value.round()},
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.tiny),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Exact-gram entry for the portion sheet.
///
/// The controller lives with the field rather than with the sheet: a modal
/// route keeps rebuilding its content through the exit animation, so a
/// controller disposed the moment `showModalBottomSheet` returns is used after
/// disposal and the sheet throws instead of applying the value.
class _PortionGramField extends StatefulWidget {
  const _PortionGramField({required this.onApply});

  final ValueChanged<double> onApply;

  @override
  State<_PortionGramField> createState() => _PortionGramFieldState();
}

class _PortionGramFieldState extends State<_PortionGramField> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Out-of-range input used to make the button look broken: it parsed, failed
  /// the bounds check and returned without a word.
  void _apply() {
    final grams = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (grams == null || grams < _minPortionGrams || grams > _maxPortionGrams) {
      setState(
        () => _error = context.ota(
          'portionGramsRangeError',
          tr: '{min} ile {max} g arasında bir değer gir.',
          en: 'Enter a value between {min} and {max} g.',
          replacements: {
            'min': _minPortionGrams.round(),
            'max': _maxPortionGrams.round(),
          },
        ),
      );
      return;
    }
    setState(() => _error = null);
    widget.onApply(grams);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Semantics(
            liveRegion: _error != null,
            child: TextField(
              key: const Key('portion-grams-input'),
              controller: _controller,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _apply(),
              decoration: InputDecoration(
                suffixText: 'g',
                errorText: _error,
                helperText: _error == null
                    ? context.ota(
                        'portionGramsRangeHint',
                        tr: '{min}-{max} g',
                        en: '{min}-{max} g',
                        replacements: {
                          'min': _minPortionGrams.round(),
                          'max': _maxPortionGrams.round(),
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 104,
          child: FilledButton(
            onPressed: _apply,
            child: Text(context.ota('applyAction', tr: 'Uygula', en: 'Apply')),
          ),
        ),
      ],
    );
  }
}

class _PortionOption extends StatelessWidget {
  const _PortionOption({
    required this.option,
    required this.foodName,
    required this.visualScale,
    required this.selected,
    required this.onTap,
  });

  final ({
    String label,
    String detail,
    double grams,
    String? sizeClass,
    String? imageUrl,
  })
  option;
  final String foodName;
  final double visualScale;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = '$foodName, ${option.label}, ${option.detail}';
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: InkWell(
        key: Key('portion-${option.grams.round()}'),
        // Moving between discrete portions is the one place in this flow where
        // the tap changes a value rather than navigating, which is exactly what
        // a selection tick is for.
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.fast,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.selectedSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(
              color: selected ? AppColors.limeDark : AppColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 1.25,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    child: _PortionVisual(
                      imageUrl: option.imageUrl,
                      scale: visualScale,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  option.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  option.detail,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The reference picture on a portion card.
///
/// Only a reviewed [imageUrl] from the catalog earns a photograph. Bundled
/// assets used to be picked by testing the localized food name for `peynir`,
/// which no English name could ever match and no third locale could extend;
/// without a food-id-to-asset mapping in the catalog the schematic is the only
/// honest fallback.
class _PortionVisual extends StatelessWidget {
  const _PortionVisual({required this.imageUrl, required this.scale});

  final String? imageUrl;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final fallback = _relativeVisual();
    if (imageUrl == null || imageUrl!.isEmpty) return fallback;
    return Image.network(
      imageUrl!,
      key: const Key('portion-reference-image'),
      fit: BoxFit.cover,
      // A reviewed reference is the whole point of the card, so hold the
      // layout with a neutral placeholder instead of collapsing to the
      // schematic while the bytes are still in flight.
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(),
      // Offline, 404 or a revoked object: fall back to the relative drawing,
      // which never claims photographic precision.
      errorBuilder: (_, _, _) => fallback,
    );
  }

  Widget _placeholder() => const ColoredBox(
    key: Key('portion-reference-placeholder'),
    color: AppColors.surfaceMuted,
    child: Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );

  Widget _relativeVisual() => ColoredBox(
    color: AppColors.surfaceMuted,
    child: CustomPaint(painter: _PortionScalePainter(scale)),
  );
}

class _PortionScalePainter extends CustomPainter {
  const _PortionScalePainter(this.scale);

  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final plateRadius = size.shortestSide * .34;
    canvas.drawCircle(
      center,
      plateRadius,
      Paint()
        ..color = AppColors.surface
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      plateRadius,
      Paint()
        ..color = AppColors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final foodRadius = plateRadius * (.28 + .45 * scale.clamp(.2, 1));
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, plateRadius * .08),
        width: foodRadius * 2,
        height: foodRadius * 1.25,
      ),
      Paint()..color = AppColors.lime,
    );
  }

  @override
  bool shouldRepaint(_PortionScalePainter oldDelegate) =>
      oldDelegate.scale != scale;
}

/// A centred sentence for the empty and failed states of a sheet list.
class _SheetMessage extends StatelessWidget {
  const _SheetMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );
}

/// When the meal was eaten, with an edit affordance. `null` reads as "now" and
/// is resolved at log time, so the default never drifts while the sheet is open.
class _EatenAtRow extends StatelessWidget {
  const _EatenAtRow({required this.eatenAt, required this.onEdit});

  final DateTime? eatenAt;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final value = eatenAt;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, size: 19),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value == null
                  ? context.ota(
                      'eatenAtNow',
                      tr: 'Şimdi yendi',
                      en: 'Eaten now',
                    )
                  : context.ota(
                      'eatenAtValue',
                      tr: '{date} · {time}',
                      en: '{date} · {time}',
                      replacements: {
                        'date': formatFullDate(context, value),
                        'time': formatTimeOfDay(context, value),
                      },
                    ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          TextButton(
            key: const Key('edit-eaten-at-button'),
            onPressed: onEdit,
            child: Text(
              context.ota('changeTimeAction', tr: 'Değiştir', en: 'Change'),
            ),
          ),
        ],
      ),
    );
  }
}

String _stepTitle(BuildContext context, MealFlowStep step) => switch (step) {
  MealFlowStep.compose => context.ota(
    'mealStepComposeTitle',
    tr: 'Öğün ekle',
    en: 'Add meal',
  ),
  MealFlowStep.analyzing => context.ota(
    'mealStepAnalyzingTitle',
    tr: 'Analiz',
    en: 'Analysis',
  ),
  MealFlowStep.review => context.ota(
    'mealStepReviewTitle',
    tr: 'Kontrol',
    en: 'Review',
  ),
};

String _catalogLocale(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'en' ? 'en-US' : 'tr-TR';

/// The view model used to return Turkish literals here, which then became the
/// stored meal name every screen shows. The name is resolved at the UI layer so
/// [MealDraft.mealName] stays a plain, already-localized string for storage.
String _localizedMealName(BuildContext context, DateTime time) =>
    switch (time.hour) {
      >= 5 && < 11 => context.ota(
        'mealNameBreakfast',
        tr: 'Kahvaltı',
        en: 'Breakfast',
      ),
      >= 11 && < 16 => context.ota(
        'mealNameLunch',
        tr: 'Öğle yemeği',
        en: 'Lunch',
      ),
      >= 16 && < 22 => context.ota(
        'mealNameDinner',
        tr: 'Akşam yemeği',
        en: 'Dinner',
      ),
      _ => context.ota('mealNameSnack', tr: 'Atıştırma', en: 'Snack'),
    };

String _portionSizeLabel(BuildContext context, FoodPortionOption option) {
  return switch (option.sizeClass) {
    'small' => context.l10n.portionSmall,
    'regular' => _regularPortionLabel(context),
    'large' => context.l10n.portionLarge,
    _ => option.label,
  };
}

String _regularPortionLabel(BuildContext context) =>
    context.ota('portionRegular', tr: 'Normal', en: 'Regular');

/// Picks the three controlled reference portions to offer, ascending by weight.
///
/// The catalog is the source of truth for the gram values, so reviewed
/// small/regular/large records win over ad-hoc labels. When a food has not been
/// classified yet the three lightest positive portions are used, which keeps the
/// sheet working for legacy catalog rows.
List<FoodPortionOption> _rankedCatalogPortions(
  List<FoodPortionOption> options,
) {
  final positive = options.where((option) => option.grams > 0).toList()
    ..sort((left, right) => left.grams.compareTo(right.grams));

  final classified = <FoodPortionOption>[
    for (final sizeClass in const ['small', 'regular', 'large'])
      ...positive.where((option) => option.sizeClass == sizeClass).take(1),
  ];
  if (classified.length == 3) return classified;
  return positive.take(3).toList(growable: false);
}
