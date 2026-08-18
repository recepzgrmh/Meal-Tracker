enum MatchState { matched, checkAmount, checkType, notFound }

class Nutrition {
  const Nutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  static const zero = Nutrition(calories: 0, protein: 0, carbs: 0, fat: 0);

  Nutrition operator +(Nutrition other) => Nutrition(
    calories: calories + other.calories,
    protein: protein + other.protein,
    carbs: carbs + other.carbs,
    fat: fat + other.fat,
  );

  Nutrition scale(double factor) => Nutrition(
    calories: calories * factor,
    protein: protein * factor,
    carbs: carbs * factor,
    fat: fat * factor,
  );
}

class MealItem {
  const MealItem({
    required this.id,
    required String name,
    required this.sourceText,
    required this.portionLabel,
    required this.grams,
    required this.nutritionPer100g,
    required this.matchState,
    this.sourceName = 'Curated food catalog',
    this.foodId,
    this.confidence,
    this.matchMethod,
    this.portionOptions = const [],
    String? canonicalName,
    String? displayName,
  }) : canonicalName = canonicalName ?? name,
       displayName = displayName ?? name;

  final String id;
  final String canonicalName;
  final String displayName;
  String get name => displayName;
  final String sourceText;
  final String portionLabel;
  final double grams;
  final Nutrition nutritionPer100g;
  final MatchState matchState;
  final String sourceName;
  final String? foodId;
  final double? confidence;
  final String? matchMethod;
  final List<FoodPortionOption> portionOptions;

  Nutrition get nutrition => nutritionPer100g.scale(grams / 100);

  MealItem copyWith({
    String? id,
    String? portionLabel,
    double? grams,
    MatchState? matchState,
  }) {
    return MealItem(
      id: id ?? this.id,
      name: displayName,
      canonicalName: canonicalName,
      displayName: displayName,
      sourceText: sourceText,
      portionLabel: portionLabel ?? this.portionLabel,
      grams: grams ?? this.grams,
      nutritionPer100g: nutritionPer100g,
      matchState: matchState ?? this.matchState,
      sourceName: sourceName,
      foodId: foodId,
      confidence: confidence,
      matchMethod: matchMethod,
      portionOptions: portionOptions,
    );
  }
}

class FoodPortionOption {
  const FoodPortionOption({
    required this.label,
    required this.grams,
    this.sizeClass,
    this.imageUrl,
  });

  final String label;
  final double grams;
  final String? sizeClass;
  final String? imageUrl;
}

String naturalFoodDisplayName(String canonicalName) {
  final trimmed = canonicalName.trim();
  final normalized = trimmed.toLowerCase();
  const preferredNames = {
    'tavuk yumurtası, haşlanmış': 'Haşlanmış yumurta',
    'beyaz peynir, tam yağlı': 'Tam yağlı beyaz peynir',
  };
  final preferred = preferredNames[normalized];
  if (preferred != null) return preferred;

  final parts = trimmed
      .split(',')
      .map((part) => part.trim().toLowerCase())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  final natural = parts.length > 1
      ? '${parts.skip(1).join(' ')} ${parts.first}'
      : normalized;
  if (natural.isEmpty) return trimmed;
  return '${natural[0].toUpperCase()}${natural.substring(1)}';
}

class MealDraft {
  const MealDraft({
    required this.inputText,
    required this.mealName,
    required this.items,
    this.analysisRunId,
    this.traceId,
    this.unmatchedText = const [],
  });

  final String inputText;
  final String mealName;
  final List<MealItem> items;
  final String? analysisRunId;
  final String? traceId;
  final List<String> unmatchedText;

  Nutrition get nutrition =>
      items.fold(Nutrition.zero, (total, item) => total + item.nutrition);

  int get reviewCount =>
      items.where((item) => item.matchState != MatchState.matched).length;

  MealDraft updateItem(MealItem updated) => MealDraft(
    inputText: inputText,
    mealName: mealName,
    items: items
        .map((item) => item.id == updated.id ? updated : item)
        .toList(growable: false),
    analysisRunId: analysisRunId,
    traceId: traceId,
    unmatchedText: unmatchedText,
  );

  MealDraft addItem(MealItem item) => MealDraft(
    inputText: inputText,
    mealName: mealName,
    items: [...items, item],
    analysisRunId: analysisRunId,
    traceId: traceId,
    unmatchedText: unmatchedText,
  );

  MealDraft removeItem(String itemId) => MealDraft(
    inputText: inputText,
    mealName: mealName,
    items: items.where((item) => item.id != itemId).toList(growable: false),
    analysisRunId: analysisRunId,
    traceId: traceId,
    unmatchedText: unmatchedText,
  );
}

class LoggedMeal {
  const LoggedMeal({
    required this.id,
    required this.name,
    required this.timeLabel,
    required this.items,
    this.imageAsset,
    this.occurredAt,
  });

  final String id;
  final String name;
  final String timeLabel;
  final List<MealItem> items;
  final String? imageAsset;
  final DateTime? occurredAt;

  Nutrition get nutrition =>
      items.fold(Nutrition.zero, (total, item) => total + item.nutrition);

  LoggedMeal copyWith({List<MealItem>? items}) => LoggedMeal(
    id: id,
    name: name,
    timeLabel: timeLabel,
    items: items ?? this.items,
    imageAsset: imageAsset,
    occurredAt: occurredAt,
  );
}
