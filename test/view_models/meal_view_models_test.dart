import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/data/meal_repository.dart';
import 'package:meal_clarity/src/domain/models.dart';
import 'package:meal_clarity/src/view_models/meal_detail_view_model.dart';
import 'package:meal_clarity/src/view_models/meal_flow_view_model.dart';
import 'package:meal_clarity/src/view_models/today_view_model.dart';

void main() {
  const item = MealItem(
    id: 'cheese',
    name: 'Beyaz Peynir',
    sourceText: 'peynir',
    portionLabel: '30 g',
    grams: 30,
    nutritionPer100g: Nutrition(calories: 300, protein: 20, carbs: 2, fat: 24),
    matchState: MatchState.checkAmount,
  );
  const draft = MealDraft(
    inputText: 'peynir',
    mealName: 'Kahvaltı',
    items: [item],
  );

  group('TodayViewModel', () {
    test('logs, updates, deletes, and restores a meal deterministically', () {
      final viewModel = TodayViewModel();
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      final loggedAt = DateTime(2026, 8, 17, 9, 5);
      final logged = viewModel.logDraft(draft, loggedAt);

      expect(logged.id, 'meal-${loggedAt.microsecondsSinceEpoch}');
      expect(logged.timeLabel, '09:05');
      expect(viewModel.meals, hasLength(1));
      expect(viewModel.total.calories, closeTo(90, 0.001));

      final updated = logged.copyWith(
        items: [item.copyWith(grams: 50, matchState: MatchState.matched)],
      );
      viewModel.updateMeal(updated);
      expect(viewModel.total.calories, closeTo(150, 0.001));

      final removed = viewModel.deleteMeal(logged.id);
      expect(removed?.id, logged.id);
      expect(viewModel.meals, isEmpty);

      viewModel.restoreMeal(updated);
      viewModel.restoreMeal(updated);
      expect(viewModel.meals, hasLength(1));
      expect(notifications, 4);
    });
  });

  group('MealFlowViewModel', () {
    test(
      'exposes analyzing and review states around repository work',
      () async {
        final repository = _ControllableRepository();
        final viewModel = MealFlowViewModel(repository: repository);

        final operation = viewModel.analyze('  peynir  ');

        expect(viewModel.step, MealFlowStep.analyzing);
        expect(repository.receivedInput, 'peynir');
        repository.complete(draft);
        await operation;

        expect(viewModel.step, MealFlowStep.review);
        expect(viewModel.draft?.reviewCount, 1);

        viewModel.updateItem(item.copyWith(matchState: MatchState.matched));
        expect(viewModel.draft?.reviewCount, 0);
      },
    );

    test(
      'returns to composer with a safe message on repository failure',
      () async {
        final viewModel = MealFlowViewModel(repository: _ThrowingRepository());

        await viewModel.analyze('peynir');

        expect(viewModel.step, MealFlowStep.compose);
        expect(viewModel.error, isNotEmpty);
        expect(viewModel.draft, isNull);
      },
    );
  });

  test('MealDetailViewModel recalculates nutrition after portion editing', () {
    const meal = LoggedMeal(
      id: 'breakfast',
      name: 'Kahvaltı',
      timeLabel: '09:05',
      items: [item],
    );
    final viewModel = MealDetailViewModel(meal: meal);

    final updated = viewModel.updatePortion(item, 50);

    expect(updated.items.single.grams, 50);
    expect(updated.items.single.matchState, MatchState.matched);
    expect(viewModel.nutrition.calories, closeTo(150, 0.001));
  });
}

class _ControllableRepository implements MealRepository {
  final _completer = Completer<MealDraft>();
  String? receivedInput;

  @override
  Future<MealDraft> analyze(String input) {
    receivedInput = input;
    return _completer.future;
  }

  void complete(MealDraft draft) => _completer.complete(draft);
}

class _ThrowingRepository implements MealRepository {
  @override
  Future<MealDraft> analyze(String input) async {
    throw StateError('network unavailable');
  }
}
