import 'dart:async';

import 'package:flutter/material.dart';

import 'data/meal_repository.dart';
import 'data/mock_seed_data.dart';
import 'domain/models.dart';
import 'features/meal_detail_screen.dart';
import 'features/meal_flow.dart';
import 'features/history_screen.dart';
import 'features/today_screen.dart';
import 'meals/data/cached_meal_repository.dart';
import 'theme/app_theme.dart';
import 'view_models/today_view_model.dart';

class MealClarityApp extends StatelessWidget {
  const MealClarityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meal Clarity',
      theme: buildTheme(),
      home: const MealClarityShell(),
    );
  }
}

class MealClarityShell extends StatefulWidget {
  const MealClarityShell({
    this.cachedRepository,
    this.userId,
    this.onSyncRequested,
    super.key,
  });

  final CachedMealRepository? cachedRepository;
  final String? userId;
  final Future<void> Function()? onSyncRequested;

  @override
  State<MealClarityShell> createState() => _MealClarityShellState();
}

class _MealClarityShellState extends State<MealClarityShell> {
  final MealRepository _repository = MockMealRepository();
  late final TodayViewModel _todayViewModel;
  StreamSubscription<List<LoggedMeal>>? _mealSubscription;
  StreamSubscription<List<LoggedMeal>>? _historySubscription;
  List<LoggedMeal> _historyMeals = const [];
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
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
        ).subtract(const Duration(days: 30)),
        to: DateTime(day.year, day.month, day.day).add(const Duration(days: 1)),
      );
    } catch (_) {
      // Cache remains the source of truth while offline.
    }
  }

  @override
  void dispose() {
    _mealSubscription?.cancel();
    _historySubscription?.cancel();
    _todayViewModel.dispose();
    super.dispose();
  }

  Future<void> _startMealFlow(BuildContext context) async {
    final draft = await Navigator.of(context).push<MealDraft>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MealFlow(repository: _repository),
      ),
    );
    if (draft == null || !mounted) return;

    final loggedAt = DateTime.now();
    final loggedMeal = _todayViewModel.logDraft(draft, loggedAt);
    if (widget.cachedRepository != null && widget.userId != null) {
      try {
        await widget.cachedRepository!.saveOptimistically(
          userId: widget.userId!,
          meal: loggedMeal,
          eatenAt: loggedAt,
        );
        unawaited(widget.onSyncRequested?.call());
      } catch (_) {
        _todayViewModel.deleteMeal(loggedMeal.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Öğün cihazına kaydedilemedi.')),
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
        content: Text('${draft.mealName} kaydedildi'),
        action: SnackBarAction(
          label: 'Geri al',
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
        if (_selectedTab == 1) {
          return HistoryScreen(
            meals: _historyMeals,
            onMealTap: (meal) => _openMeal(context, meal),
            onTodayTap: () => setState(() => _selectedTab = 0),
            onProfileTap: () => _showProfileComingSoon(context),
          );
        }
        return TodayScreen(
          meals: _todayViewModel.meals,
          onAddMeal: () => _startMealFlow(context),
          onMealTap: (meal) => _openMeal(context, meal),
          onHistoryTap: () => setState(() => _selectedTab = 1),
          onProfileTap: () => _showProfileComingSoon(context),
        );
      },
    );
  }

  void _showProfileComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil ayarları sonraki sprintte.')),
    );
  }
}
