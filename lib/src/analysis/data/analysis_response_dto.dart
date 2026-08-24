class AnalysisResponseDto {
  const AnalysisResponseDto({
    required this.analysisRunId,
    required this.traceId,
    required this.normalizedInput,
    required this.items,
    required this.unmatchedText,
    required this.unmatchedItems,
    required this.replayed,
  });

  factory AnalysisResponseDto.fromJson(Map<String, dynamic> json) {
    if (json['contractVersion'] != 'analysis.v1' ||
        json['status'] != 'needs_review') {
      throw const FormatException('Unsupported analysis contract');
    }
    final rawItems = _list(json, 'items');
    if (rawItems.isEmpty) {
      throw const FormatException('Analysis response contains no items');
    }
    return AnalysisResponseDto(
      analysisRunId: _string(json, 'analysisRunId'),
      traceId: _string(json, 'traceId'),
      normalizedInput: _string(json, 'normalizedInput'),
      items: rawItems
          .map((value) => AnalysisItemDto.fromJson(_map(value, 'items[]')))
          .toList(growable: false),
      unmatchedText: _list(
        json,
        'unmatchedText',
      ).map((value) => value as String).toList(growable: false),
      // Absent on responses recorded before the estimate contract shipped, so
      // the field is optional while `unmatchedText` stays required.
      unmatchedItems: json['unmatchedItems'] is List
          ? (json['unmatchedItems'] as List)
                .map(
                  (value) => AnalysisUnmatchedItemDto.fromJson(
                    _map(value, 'unmatchedItems[]'),
                  ),
                )
                .toList(growable: false)
          : const [],
      replayed: json['replayed'] == true,
    );
  }

  final String analysisRunId;
  final String traceId;
  final String normalizedInput;
  final List<AnalysisItemDto> items;
  final List<String> unmatchedText;

  /// Inputs the server could neither ground in the catalog nor estimate.
  final List<AnalysisUnmatchedItemDto> unmatchedItems;
  final bool replayed;
}

class AnalysisUnmatchedItemDto {
  const AnalysisUnmatchedItemDto({required this.itemKey, required this.text});

  factory AnalysisUnmatchedItemDto.fromJson(Map<String, dynamic> json) {
    return AnalysisUnmatchedItemDto(
      itemKey: _string(json, 'itemKey'),
      text: _string(json, 'text'),
    );
  }

  final String itemKey;
  final String text;
}

class AnalysisItemDto {
  const AnalysisItemDto({
    required this.itemKey,
    required this.sourceText,
    required this.foodId,
    required this.estimateId,
    required this.estimated,
    required this.canonicalName,
    required this.portionLabel,
    required this.grams,
    required this.confidence,
    required this.matchMethod,
    required this.needsClarification,
    required this.nutritionPer100g,
    this.portionOptions = const [],
    this.clarificationReason,
    this.alternativeFoodIds = const [],
  });

  factory AnalysisItemDto.fromJson(Map<String, dynamic> json) {
    final clarificationReason = json['clarificationReason'];
    if (clarificationReason != null &&
        clarificationReason != 'identity' &&
        clarificationReason != 'portion') {
      throw const FormatException('Invalid clarification reason');
    }
    // An item is either catalog-grounded or a server-recorded AI estimate,
    // never both and never neither — the commit contract depends on it.
    final foodId = _optionalString(json, 'foodId');
    final estimateId = _optionalString(json, 'estimateId');
    if ((foodId == null) == (estimateId == null)) {
      throw const FormatException(
        'Exactly one of foodId and estimateId is required',
      );
    }
    return AnalysisItemDto(
      itemKey: _string(json, 'itemKey'),
      sourceText: _string(json, 'sourceText'),
      foodId: foodId,
      estimateId: estimateId,
      estimated: json['estimated'] == true || estimateId != null,
      canonicalName: _string(json, 'canonicalName'),
      portionLabel: _string(json, 'portionLabel'),
      grams: _number(json, 'grams'),
      confidence: _number(json, 'confidence'),
      matchMethod: _string(json, 'matchMethod'),
      needsClarification: json['needsClarification'] == true,
      clarificationReason: clarificationReason as String?,
      alternativeFoodIds: json['alternativeFoodIds'] is List
          ? (json['alternativeFoodIds'] as List)
                .map((value) => value as String)
                .toList(growable: false)
          : const [],
      nutritionPer100g: AnalysisNutritionDto.fromJson(
        _map(json['nutritionPer100g'], 'nutritionPer100g'),
      ),
      portionOptions: json['portionOptions'] is List
          ? (json['portionOptions'] as List)
                .map(
                  (value) => AnalysisPortionOptionDto.fromJson(
                    _map(value, 'portionOptions[]'),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }

  final String itemKey;
  final String sourceText;

  /// Null for AI-estimate items — those carry [estimateId] instead.
  final String? foodId;
  final String? estimateId;

  /// True when the nutrition is a server-side AI estimate, not a catalog row.
  final bool estimated;
  final String canonicalName;
  final String portionLabel;
  final double grams;
  final double confidence;
  final String matchMethod;
  final bool needsClarification;
  final String? clarificationReason;
  final List<String> alternativeFoodIds;
  final AnalysisNutritionDto nutritionPer100g;
  final List<AnalysisPortionOptionDto> portionOptions;
}

class AnalysisPortionOptionDto {
  const AnalysisPortionOptionDto({
    required this.label,
    required this.grams,
    this.sizeClass,
    this.imageUrl,
  });

  factory AnalysisPortionOptionDto.fromJson(Map<String, dynamic> json) {
    return AnalysisPortionOptionDto(
      label: _string(json, 'label'),
      grams: _number(json, 'grams'),
      sizeClass: json['sizeClass'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  final String label;
  final double grams;
  final String? sizeClass;
  final String? imageUrl;
}

class AnalysisNutritionDto {
  const AnalysisNutritionDto({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory AnalysisNutritionDto.fromJson(Map<String, dynamic> json) {
    return AnalysisNutritionDto(
      calories: _number(json, 'calories'),
      protein: _number(json, 'protein'),
      carbs: _number(json, 'carbs'),
      fat: _number(json, 'fat'),
    );
  }

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string');
  }
  return value;
}

/// Accepts an absent or explicit-null value; a present value must still be a
/// non-empty string. `foodId: null` on estimate items is the motivating case.
String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string when present');
  }
  return value;
}

double _number(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num || !value.isFinite) {
    throw FormatException('$key must be a finite number');
  }
  return value.toDouble();
}

List<dynamic> _list(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List<dynamic>) throw FormatException('$key must be a list');
  return value;
}

Map<String, dynamic> _map(Object? value, String key) {
  if (value is! Map) throw FormatException('$key must be an object');
  return value.map((key, value) => MapEntry(key.toString(), value));
}
