import 'models.dart';

/// The part of the day a meal belongs to.
///
/// These are presentation buckets derived from the clock, not a property the
/// user picks and not something the server stores — nothing in the analysis
/// pipeline knows what "lunch" is. Deriving them keeps the grouping honest: it
/// can never disagree with the timestamp shown on the row.
///
/// The windows follow the ordinary Turkish eating day, with everything that
/// falls between the three main meals collected into [snack] rather than being
/// forced into the nearest one.
enum MealTimeOfDay {
  breakfast(fromMinutes: 5 * 60),
  lunch(fromMinutes: 11 * 60),
  afternoon(fromMinutes: 16 * 60),
  dinner(fromMinutes: 18 * 60),
  lateNight(fromMinutes: 23 * 60);

  const MealTimeOfDay({required this.fromMinutes});

  /// Start of the window, in minutes past midnight.
  final int fromMinutes;

  /// [afternoon] and [lateNight] are the same thing to the user — food outside
  /// the three main meals — but they sit on opposite sides of dinner, so they
  /// stay separate windows and share one label.
  bool get isSnack => this == afternoon || this == lateNight;

  static MealTimeOfDay forMinutes(int minutesOfDay) {
    if (minutesOfDay >= lateNight.fromMinutes) return lateNight;
    if (minutesOfDay >= dinner.fromMinutes) return dinner;
    if (minutesOfDay >= afternoon.fromMinutes) return afternoon;
    if (minutesOfDay >= lunch.fromMinutes) return lunch;
    if (minutesOfDay >= breakfast.fromMinutes) return breakfast;
    // Before 05:00 is the tail of the previous evening, not the start of a new
    // breakfast.
    return lateNight;
  }
}

class MealTimeGroup {
  const MealTimeGroup({required this.timeOfDay, required this.meals});

  final MealTimeOfDay timeOfDay;
  final List<LoggedMeal> meals;

  Nutrition get nutrition =>
      meals.fold(Nutrition.zero, (total, meal) => total + meal.nutrition);
}

/// Splits a day's meals into the parts of the day that actually contain food.
///
/// Empty windows are dropped rather than rendered as blank headers: a day with
/// one breakfast should read as one section, not as four sections three of
/// which apologise for being empty.
///
/// Groups are ordered by their earliest meal, and meals inside a group by time.
/// Ordering by the window's own start instead would put a 23:30 snack before a
/// 16:00 one, because both are "snack".
List<MealTimeGroup> groupMealsByTimeOfDay(List<LoggedMeal> meals) {
  if (meals.isEmpty) return const [];

  final buckets = <MealTimeOfDay, List<LoggedMeal>>{};
  final undated = <LoggedMeal>[];
  for (final meal in meals) {
    final minutes = meal.minutesOfDay;
    if (minutes == null) {
      undated.add(meal);
      continue;
    }
    buckets
        .putIfAbsent(MealTimeOfDay.forMinutes(minutes), () => <LoggedMeal>[])
        .add(meal);
  }

  int sortKey(LoggedMeal meal) => meal.minutesOfDay ?? 1 << 20;

  for (final bucket in buckets.values) {
    bucket.sort((left, right) => sortKey(left).compareTo(sortKey(right)));
  }

  final groups =
      buckets.entries
          .map(
            (entry) => MealTimeGroup(timeOfDay: entry.key, meals: entry.value),
          )
          .toList()
        ..sort(
          (left, right) =>
              sortKey(left.meals.first).compareTo(sortKey(right.meals.first)),
        );

  // A meal we cannot place still has to be reachable. It joins the last group
  // rather than inventing a sixth window the user has no name for.
  if (undated.isNotEmpty) {
    if (groups.isEmpty) {
      return [
        MealTimeGroup(timeOfDay: MealTimeOfDay.lateNight, meals: undated),
      ];
    }
    final last = groups.removeLast();
    groups.add(
      MealTimeGroup(
        timeOfDay: last.timeOfDay,
        meals: [...last.meals, ...undated],
      ),
    );
  }

  return groups;
}
