import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/l10n.dart';

import 'data/meal_repository.dart';
import 'catalog/food_catalog_repository.dart';
import 'data/mock_seed_data.dart';
import 'domain/models.dart';
import 'domain/nutrition_goals.dart';
import 'features/meal_detail_screen.dart';
import 'features/meal_flow.dart';
import 'features/analysis_screen.dart';
import 'features/profile_screen.dart';
import 'features/history_screen.dart';
import 'features/today_screen.dart';
import 'media/meal_photo_picker.dart';
import 'meals/data/cached_meal_repository.dart';
import 'sync/sync_status.dart';
import 'theme/app_theme.dart';
import 'util/haptics.dart';
import 'view_models/today_view_model.dart';
import 'widgets/liquid_glass_bottom_bar.dart';

class MealClarityApp extends StatelessWidget {
  const MealClarityApp({
    this.locale = const Locale('tr'),
    this.clock,
    super.key,
  });

  final Locale? locale;

  /// Freezes "now" for tests. Today renders the current date in its header and
  /// seeds its demo meals off the clock, which made every screenshot baseline
  /// expire at midnight.
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildTheme(),
      home: MealClarityShell(clock: clock),
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
    this.syncStatus,
    this.goals = NutritionGoals.fallback,
    this.locale,
    this.onLocaleChanged,
    this.onSignOut,
    this.onDeleteAccount,
    this.onEditGoals,
    this.clock,
    super.key,
  });

  final CachedMealRepository? cachedRepository;
  final MealRepository? analysisRepository;
  final FoodCatalogRepository? catalogRepository;
  final String? userId;
  final Future<void> Function()? onSyncRequested;

  /// Reports what the outbox is still holding. Absent in the mock-data build
  /// and in widget tests that never persist anything, where there is no queue
  /// to report on.
  final SyncStatusNotifier? syncStatus;

  final NutritionGoals goals;

  /// `null` means "follow the device". Only set when the user picked a language.
  final Locale? locale;
  final ValueChanged<Locale?>? onLocaleChanged;
  final Future<void> Function()? onSignOut;
  final Future<bool> Function()? onDeleteAccount;

  /// Reopens the setup flow so the daily target can be revised. When null
  /// the profile card stays read-only.
  final VoidCallback? onEditGoals;

  /// Source of "now" for the current day, the midnight rollover and the demo
  /// seed. Injectable so a screenshot baseline does not expire overnight.
  final DateTime Function()? clock;

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
  Timer? _midnightTimer;
  List<LoggedMeal> _historyMeals = const [];
  late DateTime _currentDay;
  int _selectedTab = 0;
  int _historyDayIndex = 0;
  int _analysisDays = 7;
  bool _historyLoaded = false;

  /// The page a programmatic tab change is flying towards.
  ///
  /// [PageView.onPageChanged] fires for every page the viewport crosses. During
  /// a tap-driven change that would light up each destination on the way past,
  /// so intermediate reports are ignored until the target is reached. Swipes
  /// leave this null and report normally, because there the intermediate pages
  /// are exactly what the finger is pointing at.
  int? _programmaticPage;
  int _navigationToken = 0;

  /// Meals removed on screen but whose removal has not come back through the
  /// data source yet.
  ///
  /// `deleteOptimistically` is a write followed by a stream emission, and
  /// History renders straight off that stream. Without this the row would sit
  /// there for a beat after the user confirmed the deletion, which reads as the
  /// tap not having registered and invites a second one.
  final Set<String> _removedMealIds = <String>{};

  bool get _isPersistent =>
      widget.cachedRepository != null && widget.userId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    _analysisRepository = widget.analysisRepository ?? MockMealRepository();
    _currentDay = _startOfToday();
    _todayViewModel = TodayViewModel(
      initialMeals: _isPersistent ? const [] : buildMockMeals(_now()),
      // Mock data is already in hand; a persistent day has not been read yet.
      hasLoaded: !_isPersistent,
    );
    if (_isPersistent) {
      _subscribeToDay();
      _historySubscription = widget.cachedRepository!
          .watchHistory(widget.userId!)
          .listen((meals) {
            if (!mounted) return;
            _pruneRemovedIds(meals);
            setState(() {
              _historyMeals = meals;
              _historyLoaded = true;
            });
          });
      unawaited(_warmPersistentState(_currentDay));
    } else {
      _historyLoaded = true;
    }
    _scheduleMidnightRollover();
  }

  /// Drops optimistic removals the data source has caught up with.
  ///
  /// Once a meal is genuinely gone from the incoming set there is nothing left
  /// to filter, and keeping the id would suppress a later meal that reuses it —
  /// which is exactly what undo does.
  void _pruneRemovedIds(List<LoggedMeal> incoming) {
    if (_removedMealIds.isEmpty) return;
    final present = incoming.map((meal) => meal.id).toSet();
    _removedMealIds.removeWhere((id) => !present.contains(id));
  }

  DateTime _now() => widget.clock?.call() ?? DateTime.now();

  DateTime _startOfToday() {
    final now = _now();
    return DateTime(now.year, now.month, now.day);
  }

  void _subscribeToDay() {
    _mealSubscription?.cancel();
    _mealSubscription = widget.cachedRepository!
        .watchDay(userId: widget.userId!, day: _currentDay)
        .listen((meals) {
          _pruneRemovedIds(meals);
          _todayViewModel.replaceAll(meals);
        });
  }

  /// A shell left open overnight used to keep serving yesterday's meals: the
  /// day was captured once in [initState]. It is now re-derived on resume and
  /// on a timer aimed at the next local midnight, whichever happens first.
  void _handleDayRollover() {
    final today = _startOfToday();
    if (today != _currentDay) {
      _currentDay = today;
      if (_isPersistent) {
        _subscribeToDay();
        unawaited(_warmPersistentState(today));
      }
      if (mounted) setState(() {});
    }
    _scheduleMidnightRollover();
  }

  void _scheduleMidnightRollover() {
    _midnightTimer?.cancel();
    final now = _now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(
      // A second of slack so the timer never fires a hair before the boundary
      // and re-arms for the same day.
      nextMidnight.difference(now) + const Duration(seconds: 1),
      _handleDayRollover,
    );
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
    _midnightTimer?.cancel();
    _mealSubscription?.cancel();
    _historySubscription?.cancel();
    _pageController.dispose();
    _todayViewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _handleDayRollover();
    if (_isPersistent) unawaited(_warmPersistentState(_currentDay));
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
    await _logDraft(draft);
  }

  Future<void> _logDraft(MealDraft draft) async {
    final loggedAt = draft.eatenAt ?? _now();
    final loggedMeal = _todayViewModel.logDraft(draft, loggedAt);
    if (_isPersistent) {
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
        if (!mounted) return;
        // Floating like the success snackbar: `extendBody: true` puts the
        // navigation bar over a fixed one.
        _showFloatingSnackBar(
          message: context.ota(
            'mealSaveDeviceError',
            tr: 'Öğün cihazına kaydedilemedi.',
            en: 'The meal could not be saved to your device.',
          ),
          actionLabel: context.ota(
            'commonRetry',
            tr: 'Tekrar dene',
            en: 'Try again',
          ),
          onAction: () => unawaited(_logDraft(draft)),
        );
        return;
      }
    }

    if (!mounted) return;
    // The one moment the app confirms that the thing the user came here to do
    // actually happened.
    AppHaptics.success();
    _showFloatingSnackBar(
      message: context.ota(
        'mealSavedMessage',
        tr: '{meal} kaydedildi',
        en: '{meal} saved',
        replacements: {'meal': draft.mealName},
      ),
      actionLabel: context.ota('commonUndo', tr: 'Geri al', en: 'Undo'),
      onAction: () {
        AppHaptics.arrived();
        _todayViewModel.deleteMeal(loggedMeal.id);
        if (_isPersistent) {
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
    );
  }

  /// Removes a meal from a list, keeping the removal reversible.
  ///
  /// The row already confirmed the intent before calling this, so there is no
  /// second dialog here — only the undo that makes the whole thing safe.
  void _deleteMeal(LoggedMeal meal) {
    setState(() => _removedMealIds.add(meal.id));
    _todayViewModel.deleteMeal(meal.id);
    if (_isPersistent) {
      unawaited(
        widget.cachedRepository!
            .deleteOptimistically(userId: widget.userId!, mealId: meal.id)
            .then((_) => widget.onSyncRequested?.call()),
      );
    }

    _showFloatingSnackBar(
      message: context.ota(
        'mealDeletedMessage',
        tr: '{meal} silindi',
        en: '{meal} deleted',
        replacements: {'meal': meal.name},
      ),
      actionLabel: context.ota('commonUndo', tr: 'Geri al', en: 'Undo'),
      onAction: () => _restoreMeal(meal),
    );
  }

  void _restoreMeal(LoggedMeal meal) {
    AppHaptics.arrived();
    setState(() => _removedMealIds.remove(meal.id));
    if (_isPersistent) {
      // Writing it back is enough: the Drift streams put it on whichever day it
      // was eaten, which for a meal swiped away in History is not today.
      unawaited(
        widget.cachedRepository!
            .saveOptimistically(
              userId: widget.userId!,
              meal: meal,
              eatenAt: meal.occurredAt,
            )
            .then((_) => widget.onSyncRequested?.call()),
      );
      return;
    }
    _todayViewModel.restoreMeal(meal);
  }

  void _showFloatingSnackBar({
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    // Deleting three meals in a row must not queue three bars the user then has
    // to sit through. The newest one replaces whatever is on screen.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          content: Text(message),
          action: SnackBarAction(
            label: actionLabel,
            textColor: AppColors.lime,
            onPressed: onAction,
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

  /// Built once. `Listenable.merge` returns a fresh object every call, so
  /// building it inside `build` made `ListenableBuilder` tear down and re-attach
  /// its subscription on every single frame.
  late final Listenable _repaintSources = widget.syncStatus == null
      ? _todayViewModel
      : Listenable.merge([_todayViewModel, widget.syncStatus]);

  @override
  Widget build(BuildContext context) {
    final syncStatus = widget.syncStatus;
    return ListenableBuilder(
      listenable: _repaintSources,
      builder: (context, _) {
        return Scaffold(
          extendBody: true,
          body: PageView(
            key: const Key('primary-tab-page-view'),
            controller: _pageController,
            allowImplicitScrolling: true,
            onPageChanged: (page) {
              final target = _programmaticPage;
              if (target != null && page != target) return;
              final tab = _tabOrder[page];
              if (_selectedTab != tab) setState(() => _selectedTab = tab);
            },
            children: [
              TodayScreen(
                key: const PageStorageKey('today-tab'),
                meals: _todayMeals,
                goals: widget.goals,
                day: _currentDay,
                isLoading: !_todayViewModel.hasLoaded,
                syncStatus: syncStatus?.status,
                onRetrySync: syncStatus?.retry,
                onDeleteMeal: _deleteMeal,
                onAddMeal: () => _showQuickAddSheet(context),
                onMealTap: (meal) => _openMeal(context, meal),
                onNavigationSelected: (index) =>
                    _handleNavigation(context, index),
                showBottomNavigationBar: false,
              ),
              HistoryScreen(
                key: const PageStorageKey('history-tab'),
                meals: _analysisMeals,
                isLoading: !_historyLoaded,
                onDeleteMeal: _deleteMeal,
                onAddMeal: () => _showQuickAddSheet(context),
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
                goals: widget.goals,
                onAddMeal: () => _showQuickAddSheet(context),
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
                goals: widget.goals,
                locale: widget.locale,
                onLocaleChanged: widget.onLocaleChanged,
                onSignOut: widget.onSignOut,
                onDeleteAccount: widget.onDeleteAccount,
                onEditGoals: widget.onEditGoals,
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
    if (!_pageController.hasClients) {
      if (index != _selectedTab) setState(() => _selectedTab = index);
      return;
    }
    final currentPage =
        (_pageController.page ?? _tabOrder.indexOf(_selectedTab).toDouble())
            .round();
    if (page == currentPage && index == _selectedTab) return;
    // The indicator moves now, not when the page lands. A control that waits
    // for its own animation before acknowledging the tap feels unresponsive
    // however fast the animation is.
    setState(() => _selectedTab = index);

    if (AppMotion.reduced(context)) {
      _programmaticPage = null;
      _pageController.jumpToPage(page);
      return;
    }

    final token = ++_navigationToken;
    // Set before the jump below, not after: `jumpToPage` reports a page change
    // of its own, and an unguarded one lights up the destination it lands on
    // next to instead of the one that was tapped.
    _programmaticPage = page;

    // Sliding across three pages at once is a blur, not a transition — the
    // destinations are peers, and Material's guidance for peers is that no
    // spatial travel between them is implied at all. Collapsing the trip to a
    // single page keeps the directional cue the swipe gesture establishes while
    // making every tab change take the same, short amount of time.
    if ((page - currentPage).abs() > 1) {
      _pageController.jumpToPage(page > currentPage ? page - 1 : page + 1);
    }

    _pageController
        .animateToPage(
          page,
          duration: AppMotion.standard,
          curve: AppMotion.curve,
        )
        .whenComplete(() {
          // A later tap, or a finger grabbing the page mid-flight, owns the
          // guard now; this completion is stale.
          if (!mounted || token != _navigationToken) return;
          _programmaticPage = null;
        });
  }

  List<LoggedMeal> get _todayMeals => _removedMealIds.isEmpty
      ? _todayViewModel.meals
      : _todayViewModel.meals
            .where((meal) => !_removedMealIds.contains(meal.id))
            .toList(growable: false);

  List<LoggedMeal> get _analysisMeals {
    final mealsById = <String, LoggedMeal>{
      for (final meal in _historyMeals) meal.id: meal,
      for (final meal in _todayViewModel.meals) meal.id: meal,
    }..removeWhere((id, _) => _removedMealIds.contains(id));
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
