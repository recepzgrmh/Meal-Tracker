import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/domain/meal_time_of_day.dart';
import 'package:meal_clarity/src/domain/models.dart';

void main() {
  const item = MealItem(
    id: 'egg',
    name: 'Yumurta',
    sourceText: 'yumurta',
    portionLabel: '1 adet',
    grams: 100,
    nutritionPer100g: Nutrition(calories: 100, protein: 10, carbs: 1, fat: 5),
    matchState: MatchState.matched,
  );

  LoggedMeal mealAt(String id, int hour, int minute) => LoggedMeal(
    id: id,
    name: id,
    timeLabel:
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    occurredAt: DateTime(2026, 8, 22, hour, minute),
    items: const [item],
  );

  group('MealTimeOfDay.forMinutes', () {
    test('places each window by its boundaries', () {
      expect(MealTimeOfDay.forMinutes(5 * 60), MealTimeOfDay.breakfast);
      expect(MealTimeOfDay.forMinutes(10 * 60 + 59), MealTimeOfDay.breakfast);
      expect(MealTimeOfDay.forMinutes(11 * 60), MealTimeOfDay.lunch);
      expect(MealTimeOfDay.forMinutes(15 * 60 + 59), MealTimeOfDay.lunch);
      expect(MealTimeOfDay.forMinutes(16 * 60), MealTimeOfDay.afternoon);
      expect(MealTimeOfDay.forMinutes(18 * 60), MealTimeOfDay.dinner);
      expect(MealTimeOfDay.forMinutes(22 * 60 + 59), MealTimeOfDay.dinner);
      expect(MealTimeOfDay.forMinutes(23 * 60), MealTimeOfDay.lateNight);
    });

    test(
      'treats the small hours as the tail of the evening, not breakfast',
      () {
        expect(MealTimeOfDay.forMinutes(0), MealTimeOfDay.lateNight);
        expect(MealTimeOfDay.forMinutes(4 * 60 + 59), MealTimeOfDay.lateNight);
        expect(MealTimeOfDay.lateNight.isSnack, isTrue);
        expect(MealTimeOfDay.afternoon.isSnack, isTrue);
        expect(MealTimeOfDay.dinner.isSnack, isFalse);
      },
    );
  });

  group('groupMealsByTimeOfDay', () {
    test('returns nothing for an empty day', () {
      expect(groupMealsByTimeOfDay(const []), isEmpty);
    });

    test('drops windows with no food in them', () {
      final groups = groupMealsByTimeOfDay([mealAt('a', 8, 30)]);

      expect(groups, hasLength(1));
      expect(groups.single.timeOfDay, MealTimeOfDay.breakfast);
      expect(groups.single.meals.single.id, 'a');
    });

    test('orders groups by their earliest meal, not by the window', () {
      // A late-night snack and an afternoon one share a label but sit on
      // opposite sides of dinner; ordering by window would put 23:30 first.
      final groups = groupMealsByTimeOfDay([
        mealAt('late', 23, 30),
        mealAt('dinner', 19, 0),
        mealAt('afternoon', 16, 30),
        mealAt('breakfast', 8, 0),
      ]);

      expect(groups.map((group) => group.meals.single.id), [
        'breakfast',
        'afternoon',
        'dinner',
        'late',
      ]);
    });

    test('orders meals inside a group by time', () {
      final groups = groupMealsByTimeOfDay([
        mealAt('second', 13, 0),
        mealAt('first', 11, 30),
      ]);

      expect(groups.single.meals.map((meal) => meal.id), ['first', 'second']);
    });

    test('sums the calories of everything in a group', () {
      final groups = groupMealsByTimeOfDay([
        mealAt('a', 12, 0),
        mealAt('b', 13, 0),
      ]);

      expect(groups.single.nutrition.calories, 200);
    });

    test('falls back to the rendered time when there is no timestamp', () {
      const withoutDate = LoggedMeal(
        id: 'legacy',
        name: 'legacy',
        timeLabel: '19:15',
        items: [item],
      );

      final groups = groupMealsByTimeOfDay([withoutDate]);

      expect(groups.single.timeOfDay, MealTimeOfDay.dinner);
    });

    test('keeps an unplaceable meal visible instead of dropping it', () {
      const unplaceable = LoggedMeal(
        id: 'broken',
        name: 'broken',
        timeLabel: 'later',
        items: [item],
      );

      final groups = groupMealsByTimeOfDay([mealAt('a', 8, 0), unplaceable]);

      expect(
        groups.expand((group) => group.meals).map((meal) => meal.id),
        containsAll(<String>['a', 'broken']),
      );
    });

    test('an unplaceable meal on its own still forms a group', () {
      const unplaceable = LoggedMeal(
        id: 'broken',
        name: 'broken',
        timeLabel: '',
        items: [item],
      );

      final groups = groupMealsByTimeOfDay([unplaceable]);

      expect(groups.single.meals.single.id, 'broken');
    });
  });

  group('LoggedMeal.minutesOfDay', () {
    test('prefers the timestamp over the label', () {
      final meal = LoggedMeal(
        id: 'a',
        name: 'a',
        timeLabel: '23:59',
        occurredAt: DateTime(2026, 8, 22, 8, 30),
        items: const [item],
      );

      expect(meal.minutesOfDay, 8 * 60 + 30);
    });

    test('rejects a label that is not a clock time', () {
      for (final label in ['', 'noon', '25:00', '08:99', '8']) {
        expect(
          LoggedMeal(
            id: 'a',
            name: 'a',
            timeLabel: label,
            items: const [item],
          ).minutesOfDay,
          isNull,
          reason: 'label "$label" should not parse',
        );
      }
    });
  });
}
