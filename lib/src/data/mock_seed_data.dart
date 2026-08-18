import '../domain/models.dart';

List<LoggedMeal> buildMockMeals() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return [
    LoggedMeal(
      id: 'lunch',
      name: 'Öğle Yemeği',
      timeLabel: '12:34',
      occurredAt: today.add(const Duration(hours: 12, minutes: 34)),
      imageAsset: 'assets/images/chicken-salad.png',
      items: const [
        MealItem(
          id: 'chicken-salad',
          name: 'Tavuklu salata',
          sourceText: 'tavuklu salata',
          portionLabel: '1 büyük kase',
          grams: 350,
          nutritionPer100g: Nutrition(
            calories: 174.3,
            protein: 12,
            carbs: 8,
            fat: 10,
          ),
          matchState: MatchState.matched,
        ),
      ],
    ),
    LoggedMeal(
      id: 'snack',
      name: 'Ara Öğün',
      timeLabel: '16:15',
      occurredAt: today.add(const Duration(hours: 16, minutes: 15)),
      imageAsset: 'assets/images/banana-yogurt.png',
      items: const [
        MealItem(
          id: 'banana-yogurt',
          name: 'Muzlu yoğurt',
          sourceText: 'muzlu yoğurt',
          portionLabel: '1 kase · 250 g',
          grams: 250,
          nutritionPer100g: Nutrition(
            calories: 76,
            protein: 3,
            carbs: 12,
            fat: 2,
          ),
          matchState: MatchState.matched,
        ),
      ],
    ),
  ];
}
