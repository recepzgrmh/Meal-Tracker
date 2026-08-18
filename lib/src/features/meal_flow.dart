import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';
import '../data/meal_repository.dart';
import '../catalog/food_catalog_repository.dart';
import '../domain/meal_analysis_input.dart';
import '../domain/models.dart';
import '../media/meal_photo_picker.dart';
import '../theme/app_theme.dart';
import '../view_models/meal_flow_view_model.dart';
import '../widgets/app_surfaces.dart';

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

  String? _localizedAnalysisError(BuildContext context) {
    if (_viewModel.error == null) return null;
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
    setState(() {
      _photo = null;
      _photoError = null;
    });
    try {
      final photo = await _photoPicker.pick(widget.initialPhotoSource!);
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

  Future<void> _showManualSearch({bool addToDraft = false}) async {
    final queryController = TextEditingController(
      text: _controller.text.trim(),
    );
    final locale = Localizations.localeOf(context).languageCode == 'en'
        ? 'en-US'
        : 'tr-TR';
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
            22,
            4,
            22,
            18 + MediaQuery.viewInsetsOf(sheetContext).bottom,
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
                const SizedBox(height: 8),
                Text(
                  context.l10n.catalogSearchExplanation,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 14),
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
                              context.ota(
                                'catalogCandidateSummary',
                                tr: '{alias} · {grams} g',
                                en: '{alias} · {grams} g',
                                replacements: {
                                  'alias': candidate.matchedAlias,
                                  'grams': candidate.defaultGrams.round(),
                                },
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              if (addToDraft) {
                                _viewModel.addManualFood(
                                  candidate,
                                  queryController.text.trim(),
                                );
                              } else {
                                _viewModel.selectManualFood(
                                  candidate,
                                  queryController.text.trim(),
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

  Future<MealItem?> _showTypeSheet(MealItem item) {
    final isSauce = item.name.toLowerCase().contains('sos');
    return showModalBottomSheet<MealItem>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSauce
                    ? context.ota(
                        'sauceTypeQuestion',
                        tr: 'Bu sos hangisine daha yakındı?',
                        en: 'Which sauce was this closest to?',
                      )
                    : context.l10n.mealTypeQuestion,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.mealTypeExplanation,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              for (final label
                  in isSauce
                      ? [
                          context.ota(
                            'yogurtSauceOption',
                            tr: 'Yoğurtlu',
                            en: 'Yogurt-based',
                          ),
                          context.ota(
                            'mayoSauceOption',
                            tr: 'Mayonezli',
                            en: 'Mayonnaise-based',
                          ),
                          context.ota('otherOption', tr: 'Diğer', en: 'Other'),
                          context.ota(
                            'unsureOption',
                            tr: 'Emin değilim',
                            en: 'Not sure',
                          ),
                        ]
                      : [
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
      ),
    );
  }

  Future<MealItem?> _showPortionSheet(MealItem item) async {
    final gramController = TextEditingController();
    final estimated = item.grams.clamp(5, 500).toDouble();
    final catalogOptions =
        item.portionOptions
            .where((option) => option.grams > 0)
            .toList(growable: false)
          ..sort((left, right) => left.grams.compareTo(right.grams));
    final options = catalogOptions.length >= 2
        ? catalogOptions
              .take(3)
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
              label: context.ota('mediumPortion', tr: 'Orta', en: 'Medium'),
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 30),
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
              const SizedBox(height: 8),
              Text(
                context.ota(
                  'portionQuestionBody',
                  tr: 'En yakın seçeneği seç. Besin değerlerini buna göre yeniden hesaplayacağız.',
                  en: 'Choose the closest option. We will recalculate the nutrition accordingly.',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
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
                            selected: options[index].grams == item.grams,
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
              const SizedBox(height: 22),
              Text(
                context.ota(
                  'orEnterGrams',
                  tr: 'veya gram gir',
                  en: 'or enter grams',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('portion-grams-input'),
                      controller: gramController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(suffixText: 'g'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 104,
                    child: FilledButton(
                      onPressed: () {
                        final grams = double.tryParse(
                          gramController.text.replaceAll(',', '.'),
                        );
                        if (grams == null || grams <= 0 || grams > 2000) return;
                        Navigator.pop(
                          context,
                          item.copyWith(
                            grams: grams,
                            portionLabel: '${grams.round()} g',
                            matchState: MatchState.matched,
                          ),
                        );
                      },
                      child: Text(
                        context.ota('applyAction', tr: 'Uygula', en: 'Apply'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    gramController.dispose();
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
            title: Text('', style: Theme.of(context).textTheme.titleMedium),
          ),
          body: SafeArea(
            top: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: switch (_viewModel.step) {
                MealFlowStep.compose =>
                  widget.initialPhotoSource == null
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
                        ),
                MealFlowStep.analyzing => _Analyzing(
                  key: ValueKey('analyzing'),
                  photo: _photo,
                ),
                MealFlowStep.review => _Review(
                  key: const ValueKey('review'),
                  draft: _viewModel.draft!,
                  photo: _photo,
                  onReviewItem: _reviewItem,
                  onRemoveItem: (item) => _viewModel.removeItem(item.id),
                  onAddMissing: _viewModel.canSearchCatalog
                      ? () => _showManualSearch(addToDraft: true)
                      : null,
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
      contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.76,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ScanGuideVisual(),
              const SizedBox(height: 20),
              Text(
                context.ota(
                  'scanGuideTitle',
                  tr: 'Yemeğini nasıl taratırsın?',
                  en: 'How to scan your meal',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                context.ota(
                  'scanGuideBody',
                  tr: 'Tabağın tamamı görünsün; telefonu mümkün olduğunca yukarıdan ve sabit tut.',
                  en: 'Keep the entire plate visible and hold your phone steady from above.',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              _GuideTip(
                icon: Icons.wb_sunny_outlined,
                text: context.ota(
                  'scanGuideLight',
                  tr: 'Aydınlık bir ortam kullan',
                  en: 'Use a well-lit area',
                ),
              ),
              const SizedBox(height: 10),
              _GuideTip(
                icon: Icons.center_focus_strong_rounded,
                text: context.ota(
                  'scanGuideFrame',
                  tr: 'Tüm yiyecekleri kadraja al',
                  en: 'Fit all foods in the frame',
                ),
              ),
              const SizedBox(height: 10),
              _GuideTip(
                icon: Icons.straighten_rounded,
                text: context.ota(
                  'scanGuidePortions',
                  tr: 'Porsiyonları kapatmamaya çalış',
                  en: 'Avoid covering the portions',
                ),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 4),
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

class _GuideTip extends StatelessWidget {
  const _GuideTip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
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
  });

  final MealPhotoAttachment? photo;
  final String? error;
  final MealPhotoSource source;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onRetake;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    if (photo == null) {
      return _PhotoLaunchState(error: error, onRetry: onRetake);
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
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
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
          const SizedBox(height: 6),
          Text(
            context.ota(
              'photoReadyBody',
              tr: 'Analizden önce tabağın tamamının göründüğünü kontrol et.',
              en: 'Make sure the whole plate is visible before analysis.',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.feature),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Image.memory(
                photo!.bytes,
                key: const Key('dedicated-photo-preview'),
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.ota(
              'photoContextQuestion',
              tr: 'Bir detay eklemek ister misin?',
              en: 'Would you like to add a detail?',
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 16),
          if (largeText)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                retakeButton,
                const SizedBox(height: 10),
                analyzeButton,
              ],
            )
          else
            Row(
              children: [
                Expanded(child: retakeButton),
                const SizedBox(width: 10),
                Expanded(child: analyzeButton),
              ],
            ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!, style: const TextStyle(color: AppColors.destructive)),
          ],
        ],
      ),
    );
  }
}

class _PhotoLaunchState extends StatelessWidget {
  const _PhotoLaunchState({required this.error, required this.onRetry});

  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
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
            const SizedBox(height: 18),
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
            const SizedBox(height: 7),
            Text(
              error ??
                  context.ota(
                    'cameraPreparingBody',
                    tr: 'Birazdan doğrudan çekim ekranına geçeceksin.',
                    en: 'You will go directly to the camera in a moment.',
                  ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (error != null) ...[
              const SizedBox(height: 18),
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
                    style: const TextStyle(color: AppColors.destructive),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    style: const TextStyle(color: AppColors.destructive),
                  ),
                  if (onManualSearch != null) ...[
                    const SizedBox(height: 8),
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
  const _Analyzing({required this.photo, super.key});

  final MealPhotoAttachment? photo;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            key: const Key('analysis-loading-center'),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (photo != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.feature),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.memory(
                          photo!.bytes,
                          key: const Key('analyzing-photo-preview'),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
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
                  Text(
                    context.l10n.mealAnalyzingFoods,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.ota(
                      'mealAnalyzingSummary',
                      tr: 'Yiyecekler ve porsiyonlar tahmin ediliyor.',
                      en: 'Estimating foods and portions.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
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
    required this.onAddMissing,
    required this.onLog,
  });

  final MealDraft draft;
  final MealPhotoAttachment? photo;
  final ValueChanged<MealItem> onReviewItem;
  final ValueChanged<MealItem> onRemoveItem;
  final VoidCallback? onAddMissing;
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
                context.ota(
                  'mealResultReadyTitle',
                  tr: 'Öğünün hazır',
                  en: 'Your meal is ready',
                ),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 7),
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
              const SizedBox(height: 18),
              if (photo != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.feature),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.memory(
                      photo!.bytes,
                      key: const Key('review-photo-preview'),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (draft.inputText.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.quoteSurface,
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
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 22),
              Text(
                context.ota(
                  'detectedFoodsTitle',
                  tr: 'Bulunan yiyecekler',
                  en: 'Detected foods',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.mealFoundCount(draft.items.length),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 20),
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
            border: Border(top: BorderSide(color: AppColors.separator)),
          ),
          child: Builder(
            builder: (context) {
              final largeText =
                  MediaQuery.textScalerOf(context).scale(14) >= 20;
              final edit = OutlinedButton(
                key: const Key('review-edit-button'),
                onPressed: draft.reviewCount > 0
                    ? () {
                        final item = draft.items.firstWhere(
                          (candidate) =>
                              candidate.matchState != MatchState.matched,
                        );
                        onReviewItem(item);
                      }
                    : onAddMissing,
                child: Text(
                  draft.reviewCount > 0
                      ? context.l10n.mealReviewPoints(draft.reviewCount)
                      : context.ota(
                          'editMealAction',
                          tr: 'Düzenle',
                          en: 'Edit',
                        ),
                ),
              );
              final save = FilledButton(
                key: const Key('review-primary-button'),
                onPressed: draft.items.isEmpty ? null : onLog,
                child: Text(context.l10n.mealLog),
              );
              final canEdit = draft.reviewCount > 0 || onAddMissing != null;
              if (!canEdit) return save;
              if (largeText) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [edit, const SizedBox(height: 10), save],
                );
              }
              return Row(
                children: [
                  Expanded(child: edit),
                  const SizedBox(width: 10),
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
  });

  final MealItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final needsReview = item.matchState != MatchState.matched;
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
            padding: const EdgeInsets.fromLTRB(16, 15, 12, 14),
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
                    IconButton(
                      tooltip: context.ota(
                        'removeFoodAction',
                        tr: 'Yiyeceği kaldır',
                        en: 'Remove food',
                      ),
                      onPressed: onRemove,
                      icon: const Icon(Icons.close_rounded, size: 19),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${needsReview ? '~' : ''}${item.grams.round()} g',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Text(
                      '${item.nutrition.calories.round()} kcal',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (needsReview) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
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
                        const SizedBox(width: 8),
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
              ],
            ),
          ),
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
    return HeroCardSurface(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 21),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.mealEstimatedTotal,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            context.ota(
              'calorieAmount',
              tr: '{amount} kcal',
              en: '{amount} kcal',
              replacements: {'amount': nutrition.calories.round()},
            ),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 22),
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
    final color = switch (label.toLowerCase()) {
      final value when value.contains('protein') => AppColors.protein,
      final value when value.contains('karbon') || value.contains('carb') =>
        AppColors.carbs,
      _ => AppColors.fat,
    };
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
          const SizedBox(height: 5),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
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
    return InkWell(
      key: Key('portion-${option.grams.round()}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.selectedSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.limeDark : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.25,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _PortionVisual(
                  foodName: foodName,
                  sizeClass: option.sizeClass,
                  imageUrl: option.imageUrl,
                  scale: visualScale,
                ),
              ),
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

class _PortionVisual extends StatelessWidget {
  const _PortionVisual({
    required this.foodName,
    required this.sizeClass,
    required this.imageUrl,
    required this.scale,
  });

  final String foodName;
  final String? sizeClass;
  final String? imageUrl;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final fallback = _relativeVisual();
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    final name = foodName.toLowerCase();
    final asset = name.contains('peynir')
        ? switch (sizeClass) {
            'small' => 'assets/images/portion_cheese_small.webp',
            'large' => 'assets/images/portion_cheese_large.webp',
            _ => 'assets/images/portion_cheese_regular.webp',
          }
        : null;
    return asset == null
        ? fallback
        : Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          );
  }

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

String _portionSizeLabel(BuildContext context, FoodPortionOption option) {
  return switch (option.sizeClass) {
    'small' => context.l10n.portionSmall,
    'regular' => context.ota('mediumPortion', tr: 'Orta', en: 'Medium'),
    'large' => context.l10n.portionLarge,
    _ => option.label,
  };
}
