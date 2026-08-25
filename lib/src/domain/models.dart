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
    this.estimateId,
    this.confidence,
    this.matchMethod,
    this.analysisItemKey,
    this.alternativeFoodIds = const [],
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

  /// Server-recorded AI-estimate row this item commits against when the
  /// catalog held no match. Exactly one of [foodId] and [estimateId] is set on
  /// an analyzed item.
  final String? estimateId;
  final double? confidence;
  final String? matchMethod;

  /// True when the nutrition was estimated by the model rather than grounded
  /// in the curated catalog. Derived from the server's `matchMethod` so the
  /// flag survives every copy and persistence round-trip that keeps it.
  bool get isAiEstimate => matchMethod == 'ai_estimate';

  /// Runner-up catalog foods the server offered for an identity question
  /// (`clarificationReason == 'identity'`), best match first.
  final List<String> alternativeFoodIds;

  /// Stable key emitted by analyze-meal and used only for grounded commit
  /// validation. The local/server row id remains the UUID in [id].
  final String? analysisItemKey;
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
    String? analysisItemKey,
    // Swapping the food identity invalidates the previous food's portions, so
    // this has to be overridable rather than always carried through.
    List<FoodPortionOption>? portionOptions,
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
      estimateId: estimateId,
      confidence: confidence ?? this.confidence,
      matchMethod: matchMethod ?? this.matchMethod,
      analysisItemKey: analysisItemKey ?? this.analysisItemKey,
      alternativeFoodIds: alternativeFoodIds,
      portionOptions: portionOptions ?? this.portionOptions,
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
    this.imagePath,
    this.imageUrl,
  });

  final String inputText;
  final String mealName;
  final List<MealItem> items;
  final String? analysisRunId;
  final String? traceId;
  final List<String> unmatchedText;
  final String? imagePath;
  final String? imageUrl;

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

  MealDraft removeItem(String itemId) => _withItems(
    items.where((item) => item.id != itemId).toList(growable: false),
  );

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
    imagePath: imagePath,
    imageUrl: imageUrl,
  );

  MealDraft _withItems(List<MealItem> next) => MealDraft(
    inputText: inputText,
    mealName: mealName,
    items: next,
    analysisRunId: analysisRunId,
    traceId: traceId,
    unmatchedText: unmatchedText,
    eatenAt: eatenAt,
    imagePath: imagePath,
    imageUrl: imageUrl,
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
    this.isPending = false,
  });

  final String id;
  final String name;
  final String timeLabel;
  final List<MealItem> items;
  final String? imageAsset;
  final DateTime? occurredAt;

  /// True while this meal exists only on the device and still has to reach the
  /// server. Carried on the domain object rather than looked up per row so the
  /// list can say so without every tile querying the sync tables.
  final bool isPending;

  Nutrition get nutrition =>
      items.fold(Nutrition.zero, (total, item) => total + item.nutrition);

  /// Minutes past local midnight, used to place the meal in a part of the day.
  ///
  /// [occurredAt] is authoritative; [timeLabel] is the fallback for meals that
  /// only ever carried the rendered `HH:mm`. Meals with neither sort last
  /// rather than silently landing at midnight.
  int? get minutesOfDay {
    final date = occurredAt;
    if (date != null) return date.hour * 60 + date.minute;
    final parts = timeLabel.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  LoggedMeal copyWith({List<MealItem>? items, bool? isPending}) => LoggedMeal(
    id: id,
    name: name,
    timeLabel: timeLabel,
    items: items ?? this.items,
    imageAsset: imageAsset,
    occurredAt: occurredAt,
    isPending: isPending ?? this.isPending,
  );
}
