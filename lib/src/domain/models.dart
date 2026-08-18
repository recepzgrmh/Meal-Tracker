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
    Nutrition? nutritionPer100g,
    String? foodId,
    String? canonicalName,
    String? displayName,
    String? sourceName,
    double? confidence,
    String? matchMethod,
  }) {
    final name = displayName ?? this.displayName;
    return MealItem(
      id: id ?? this.id,
      name: name,
      canonicalName: canonicalName ?? this.canonicalName,
      displayName: name,
      sourceText: sourceText,
      portionLabel: portionLabel ?? this.portionLabel,
      grams: grams ?? this.grams,
      nutritionPer100g: nutritionPer100g ?? this.nutritionPer100g,
      matchState: matchState ?? this.matchState,
      sourceName: sourceName ?? this.sourceName,
      foodId: foodId ?? this.foodId,
      confidence: confidence ?? this.confidence,
      matchMethod: matchMethod ?? this.matchMethod,
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
    this.eatenAt,
  });

  final String inputText;
  final String mealName;
  final List<MealItem> items;
  final String? analysisRunId;
  final String? traceId;
  final List<String> unmatchedText;

  /// When the meal was actually eaten. `null` means "now", so callers keep
  /// resolving the timestamp at log time instead of freezing it at analysis.
  final DateTime? eatenAt;

  Nutrition get nutrition =>
      items.fold(Nutrition.zero, (total, item) => total + item.nutrition);

  int get reviewCount =>
      items.where((item) => item.matchState != MatchState.matched).length;

  MealDraft updateItem(MealItem updated) => _withItems(
    items
        .map((item) => item.id == updated.id ? updated : item)
        .toList(growable: false),
  );

  MealDraft addItem(MealItem item) => _withItems([...items, item]);

  MealDraft removeItem(String itemId) =>
      _withItems(items.where((item) => item.id != itemId).toList(growable: false));

  /// Explicit setter rather than a `copyWith`, because clearing [eatenAt] back
  /// to "now" has to be expressible and a nullable named parameter cannot tell
  /// "omitted" from "set to null".
  MealDraft withEatenAt(DateTime? value) => MealDraft(
    inputText: inputText,
    mealName: mealName,
    items: items,
    analysisRunId: analysisRunId,
    traceId: traceId,
    unmatchedText: unmatchedText,
    eatenAt: value,
  );

  MealDraft _withItems(List<MealItem> next) => MealDraft(
    inputText: inputText,
    mealName: mealName,
    items: next,
    analysisRunId: analysisRunId,
    traceId: traceId,
    unmatchedText: unmatchedText,
    eatenAt: eatenAt,
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
