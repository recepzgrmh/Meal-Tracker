import '../domain/models.dart';

abstract interface class MealRepository {
  Future<MealDraft> analyze(String input);
}

enum MealAnalysisFailureKind {
  noMatch,
  unauthenticated,
  invalidRequest,
  rateLimited,
  unavailable,
  invalidResponse,
  unknown,
}

class MealAnalysisException implements Exception {
  const MealAnalysisException({
    required this.kind,
    required this.code,
    required this.retryable,
  });

  final MealAnalysisFailureKind kind;
  final String code;
  final bool retryable;
}

class MockMealRepository implements MealRepository {
  @override
  Future<MealDraft> analyze(String input) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final normalized = input.toLowerCase();
    final items = <MealItem>[];

    if (normalized.contains('yumurta') || normalized.contains('egg')) {
      final count = normalized.contains('2') || normalized.contains('iki')
          ? 2
          : 1;
      items.add(
        MealItem(
          id: 'egg',
          name: count == 1 ? 'Yumurta' : '$count Yumurta',
          sourceText: count == 1 ? 'yumurta' : '$count yumurta',
          portionLabel: '$count adet · ${count * 50} g',
          grams: count * 50,
          nutritionPer100g: const Nutrition(
            calories: 140,
            protein: 12.6,
            carbs: 0.7,
            fat: 9.5,
          ),
          matchState: MatchState.matched,
        ),
      );
    }

    if (normalized.contains('simit')) {
      final isHalf = normalized.contains('yarım') || normalized.contains('0.5');
      final grams = isHalf ? 50.0 : 100.0;
      items.add(
        MealItem(
          id: 'simit',
          name: 'Simit',
          sourceText: isHalf ? 'yarım simit' : 'simit',
          portionLabel: isHalf ? '½ adet · 50 g' : '1 adet · 100 g',
          grams: grams,
          nutritionPer100g: const Nutrition(
            calories: 340,
            protein: 10,
            carbs: 57,
            fat: 8,
          ),
          matchState: MatchState.matched,
        ),
      );
    }

    if (normalized.contains('peynir') || normalized.contains('cheese')) {
      final amountPattern = RegExp(r'\b(15|30|50)\s*(?:g|gr|gram)\b');
      final exact = amountPattern.firstMatch(normalized);
      final grams = exact == null ? 30.0 : double.parse(exact.group(1)!);
      items.add(
        MealItem(
          id: 'white-cheese',
          name: 'Tam Yağlı Beyaz Peynir',
          sourceText: normalized.contains('beyaz peynir')
              ? 'beyaz peynir'
              : 'peynir',
          portionLabel: '${grams.round()} g',
          grams: grams,
          nutritionPer100g: const Nutrition(
            calories: 290,
            protein: 16,
            carbs: 2.5,
            fat: 24,
          ),
          matchState: exact == null
              ? MatchState.checkAmount
              : MatchState.matched,
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        const MealItem(
          id: 'yogurt',
          name: 'Yoğurt',
          sourceText: 'öğün',
          portionLabel: '1 kase · 200 g',
          grams: 200,
          nutritionPer100g: Nutrition(
            calories: 61,
            protein: 3.5,
            carbs: 4.7,
            fat: 3.3,
          ),
          matchState: MatchState.checkType,
        ),
      );
    }

    return MealDraft(inputText: input, mealName: 'Kahvaltı', items: items);
  }
}
