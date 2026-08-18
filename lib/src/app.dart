import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/l10n.dart';

import 'data/meal_repository.dart';
import 'catalog/food_catalog_repository.dart';
import 'data/mock_seed_data.dart';
import 'domain/models.dart';
import 'features/meal_detail_screen.dart';
import 'features/meal_flow.dart';
import 'features/analysis_screen.dart';
import 'features/profile_screen.dart';
import 'features/history_screen.dart';
import 'features/today_screen.dart';
import 'media/meal_photo_picker.dart';
import 'meals/data/cached_meal_repository.dart';
import 'theme/app_theme.dart';
import 'view_models/today_view_model.dart';
import 'widgets/liquid_glass_bottom_bar.dart';

class MealClarityApp extends StatelessWidget {
  const MealClarityApp({this.locale = const Locale('tr'), super.key});

  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildTheme(),
      home: const MealClarityShell(),
    );
  }
}

class MealClarityShell extends StatefulWidget {
  const MealClarityShell({
    this.cachedRepository,
    this.analysisRepository,
    this.catalogRepository,
    this.userId,
    this.onSyncRequested,
    super.key,
  });

  final CachedMealRepository? cachedRepository;
  final MealRepository? analysisRepository;
  final FoodCatalogRepository? catalogRepository;
  final String? userId;
  final Future<void> Function()? onSyncRequested;

  @override
  State<MealClarityShell> createState() => _MealClarityShellState();
}

class _MealClarityShellState extends State<MealClarityShell>
    with WidgetsBindingObserver {
  static const _tabOrder = <int>[0, 1, 3, 4];

  late final MealRepository _analysisRepository;
  late final TodayViewModel _todayViewModel;
  late final PageController _pageController;
  StreamSubscription<List<LoggedMeal>>? _mealSubscription;
  StreamSubscription<List<LoggedMeal>>? _historySubscription;
  List<LoggedMeal> _historyMeals = const [];
  int _selectedTab = 0;
  int _historyDayIndex = 0;
  int _analysisDays = 7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    _analysisRepository = widget.analysisRepository ?? MockMealRepository();
    final persistent = widget.cachedRepository != null && widget.userId != null;
    _todayViewModel = TodayViewModel(
      initialMeals: persistent ? const [] : buildMockMeals(),
    );
    if (persistent) {
      final now = DateTime.now();
      _mealSubscription = widget.cachedRepository!
          .watchDay(userId: widget.userId!, day: now)
          .listen(_todayViewModel.replaceAll);
      _historySubscription = widget.cachedRepository!
          .watchHistory(widget.userId!)
          .listen((meals) {
            if (!mounted) return;
            setState(() => _historyMeals = meals);
          });
      unawaited(_warmPersistentState(now));
    }
  }

  Future<void> _warmPersistentState(DateTime day) async {
    await widget.onSyncRequested?.call();
    try {
      await widget.cachedRepository!.refreshWindow(
        userId: widget.userId!,
        from: DateTime(
          day.year,
          day.month,
          day.day,
        ).subtract(const Duration(days: 90)),
        to: DateTime(day.year, day.month, day.day).add(const Duration(days: 1)),
      );
    } catch (_) {
      // Cache remains the source of truth while offline.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mealSubscription?.cancel();
    _historySubscription?.cancel();
    _pageController.dispose();
    _todayViewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        widget.cachedRepository != null &&
        widget.userId != null) {
      unawaited(_warmPersistentState(DateTime.now()));
    }
  }

  Future<void> _startMealFlow(
    BuildContext context, {
    MealPhotoSource? initialPhotoSource,
  }) async {
    final draft = await Navigator.of(context).push<MealDraft>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MealFlow(
          repository: _analysisRepository,
          catalogRepository: widget.catalogRepository,
          initialPhotoSource: initialPhotoSource,
        ),
      ),
    );
    if (draft == null || !mounted) return;

    final loggedAt = DateTime.now();
    final loggedMeal = _todayViewModel.logDraft(draft, loggedAt);
    if (widget.cachedRepository != null && widget.userId != null) {
      try {
        if (draft.analysisRunId != null) {
          await widget.cachedRepository!.saveAnalyzedOptimistically(
            userId: widget.userId!,
            meal: loggedMeal,
            draft: draft,
            eatenAt: loggedAt,
          );
        } else {
          await widget.cachedRepository!.saveOptimistically(
            userId: widget.userId!,
            meal: loggedMeal,
            eatenAt: loggedAt,
          );
        }
        unawaited(widget.onSyncRequested?.call());
      } catch (_) {
        _todayViewModel.deleteMeal(loggedMeal.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.ota(
                  'mealSaveDeviceError',
                  tr: 'Öğün cihazına kaydedilemedi.',
                  en: 'The meal could not be saved to your device.',
                ),
              ),
            ),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          context.ota(
            'mealSavedMessage',
            tr: '{meal} kaydedildi',
            en: '{meal} saved',
            replacements: {'meal': draft.mealName},
          ),
        ),
        action: SnackBarAction(
          label: context.ota('commonUndo', tr: 'Geri al', en: 'Undo'),
          textColor: AppColors.lime,
          onPressed: () {
            _todayViewModel.deleteMeal(loggedMeal.id);
            if (widget.cachedRepository != null && widget.userId != null) {
              unawaited(
                widget.cachedRepository!
                    .deleteOptimistically(
                      userId: widget.userId!,
                      mealId: loggedMeal.id,
                    )
                    .then((_) => widget.onSyncRequested?.call()),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _showQuickAddSheet(BuildContext context) async {
    final mode = await showModalBottomSheet<_MealEntryMode>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        final largeText = MediaQuery.textScalerOf(sheetContext).scale(14) >= 20;
        final galleryButton = OutlinedButton.icon(
          key: const Key('add-meal-gallery'),
          onPressed: () => Navigator.pop(sheetContext, _MealEntryMode.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(
            context.ota(
              'chooseFromGallery',
              tr: 'Galeriden seç',
              en: 'Choose from gallery',
            ),
          ),
        );
        final textButton = OutlinedButton.icon(
          key: const Key('add-meal-text'),
          onPressed: () => Navigator.pop(sheetContext, _MealEntryMode.text),
          icon: const Icon(Icons.edit_note_rounded),
          label: Text(
            context.ota('addByTyping', tr: 'Yazarak ekle', en: 'Add by typing'),
          ),
        );
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          context.ota(
                            'quickAddSheetTitle',
                            tr: 'Öğün ekle',
                            en: 'Add meal',
                          ),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.ota(
                            'quickAddSheetBody',
                            tr: 'Yemeğini göster,\ngerisini birlikte halledelim.',
                            en: 'Show us your meal,\nand we will handle the rest together.',
                          ),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  _PrimaryCaptureAction(
                    key: const Key('add-meal-camera'),
                    onTap: () =>
                        Navigator.pop(sheetContext, _MealEntryMode.camera),
                  ),
                  const SizedBox(height: 10),
                  if (largeText)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        galleryButton,
                        const SizedBox(height: 10),
                        textButton,
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(child: galleryButton),
                        const SizedBox(width: 10),
                        Expanded(child: textButton),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (mode == null || !context.mounted) return;
    final source = switch (mode) {
      _MealEntryMode.text => null,
      _MealEntryMode.camera => MealPhotoSource.camera,
      _MealEntryMode.gallery => MealPhotoSource.gallery,
    };
    await _startMealFlow(context, initialPhotoSource: source);
  }

  Future<void> _openMeal(BuildContext context, LoggedMeal meal) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MealDetailScreen(
          meal: meal,
          onUpdate: (updated) {
            _todayViewModel.updateMeal(updated);
            if (widget.cachedRepository != null && widget.userId != null) {
              unawaited(
                widget.cachedRepository!
                    .saveOptimistically(userId: widget.userId!, meal: updated)
                    .then((_) => widget.onSyncRequested?.call()),
              );
            }
          },
          onDelete: () {
            _todayViewModel.deleteMeal(meal.id);
            if (widget.cachedRepository != null && widget.userId != null) {
              unawaited(
                widget.cachedRepository!
                    .deleteOptimistically(
                      userId: widget.userId!,
                      mealId: meal.id,
                    )
                    .then((_) => widget.onSyncRequested?.call()),
              );
            }
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _todayViewModel,
      builder: (context, _) {
        return Scaffold(
          extendBody: true,
          body: PageView(
            key: const Key('primary-tab-page-view'),
            controller: _pageController,
            allowImplicitScrolling: true,
            onPageChanged: (page) {
              final tab = _tabOrder[page];
              if (_selectedTab != tab) setState(() => _selectedTab = tab);
            },
            children: [
              TodayScreen(
                key: const PageStorageKey('today-tab'),
                meals: _todayViewModel.meals,
                onAddMeal: () => _showQuickAddSheet(context),
                onMealTap: (meal) => _openMeal(context, meal),
                onNavigationSelected: (index) =>
                    _handleNavigation(context, index),
                showBottomNavigationBar: false,
              ),
              HistoryScreen(
                key: const PageStorageKey('history-tab'),
                meals: _analysisMeals,
                selectedDayIndex: _historyDayIndex,
                onSelectedDayIndexChanged: (index) {
                  setState(() => _historyDayIndex = index);
                },
                onMealTap: (meal) => _openMeal(context, meal),
                onNavigationSelected: (index) =>
                    _handleNavigation(context, index),
                showBottomNavigationBar: false,
              ),
              AnalysisScreen(
                key: const PageStorageKey('analysis-tab'),
                meals: _analysisMeals,
                selectedDays: _analysisDays,
                onSelectedDaysChanged: (days) {
                  setState(() => _analysisDays = days);
                },
                onMealTap: (meal) => _openMeal(context, meal),
                onNavigationSelected: (index) =>
                    _handleNavigation(context, index),
                showBottomNavigationBar: false,
              ),
              ProfileScreen(
                key: const PageStorageKey('profile-tab'),
                onNavigationSelected: (index) =>
                    _handleNavigation(context, index),
                showBottomNavigationBar: false,
              ),
            ],
          ),
          bottomNavigationBar: LiquidGlassBottomBar(
            selectedIndex: _selectedTab,
            onDestinationSelected: (index) => _handleNavigation(context, index),
          ),
        );
      },
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index == 2) {
      unawaited(_showQuickAddSheet(context));
      return;
    }
    final page = _tabOrder.indexOf(index);
    if (page < 0) return;
    final currentPage = _pageController.hasClients
        ? (_pageController.page ?? _tabOrder.indexOf(_selectedTab).toDouble())
              .round()
        : _tabOrder.indexOf(_selectedTab);
    if (page == currentPage && index == _selectedTab) return;
    setState(() => _selectedTab = index);
    final shouldJump =
        MediaQuery.disableAnimationsOf(context) ||
        (page - currentPage).abs() > 1;
    if (shouldJump) {
      _pageController.jumpToPage(page);
    } else {
      unawaited(
        _pageController.animateToPage(
          page,
          duration: AppMotion.standard,
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  List<LoggedMeal> get _analysisMeals {
    final mealsById = <String, LoggedMeal>{
      for (final meal in _historyMeals) meal.id: meal,
      for (final meal in _todayViewModel.meals) meal.id: meal,
    };
    final meals = mealsById.values.toList(growable: false);
    meals.sort((left, right) {
      final leftDate = left.occurredAt;
      final rightDate = right.occurredAt;
      if (leftDate != null && rightDate != null) {
        return rightDate.compareTo(leftDate);
      }
      return right.timeLabel.compareTo(left.timeLabel);
    });
    return meals;
  }
}

enum _MealEntryMode { text, camera, gallery }

class _PrimaryCaptureAction extends StatelessWidget {
  const _PrimaryCaptureAction({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.standardCard),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.standardCard),
          side: const BorderSide(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: double.infinity,
              minHeight: 152,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: AppColors.limeSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_camera_outlined, size: 27),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.ota(
                      'takePhoto',
                      tr: 'Fotoğraf çek',
                      en: 'Take photo',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.ota(
                      'fastestLoggingMethod',
                      tr: 'En hızlı kayıt yöntemi',
                      en: 'The fastest way to log',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
