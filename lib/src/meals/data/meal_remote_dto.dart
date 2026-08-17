class MealRemoteDto {
  const MealRemoteDto({
    required this.id,
    required this.userId,
    required this.clientRequestId,
    required this.name,
    required this.occurredAt,
    required this.updatedAt,
    required this.rowVersion,
    required this.items,
    this.rawInput,
    this.imagePath,
  });

  factory MealRemoteDto.fromJson(Map<String, dynamic> json) {
    return MealRemoteDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      clientRequestId: json['client_request_id'] as String,
      name: json['name'] as String,
      rawInput: json['raw_input'] as String?,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      imagePath: json['image_path'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      rowVersion: json['row_version'] as int,
      items: (json['meal_items'] as List<dynamic>? ?? const [])
          .map(
            (item) => MealItemRemoteDto.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  final String id;
  final String userId;
  final String clientRequestId;
  final String name;
  final String? rawInput;
  final DateTime occurredAt;
  final String? imagePath;
  final DateTime updatedAt;
  final int rowVersion;
  final List<MealItemRemoteDto> items;
}

class MealItemRemoteDto {
  const MealItemRemoteDto({
    required this.id,
    required this.position,
    required this.sourceText,
    required this.canonicalName,
    required this.portionLabel,
    required this.grams,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.reviewStatus,
    required this.nutritionSource,
    this.foodId,
  });

  factory MealItemRemoteDto.fromJson(Map<String, dynamic> json) {
    double number(String key) => (json[key] as num).toDouble();
    return MealItemRemoteDto(
      id: json['id'] as String,
      foodId: json['food_id'] as String?,
      position: json['position'] as int,
      sourceText: json['source_text'] as String,
      canonicalName: json['canonical_name'] as String,
      portionLabel: json['portion_label'] as String,
      grams: number('grams'),
      caloriesPer100g: number('calories_per_100g'),
      proteinPer100g: number('protein_per_100g'),
      carbsPer100g: number('carbs_per_100g'),
      fatPer100g: number('fat_per_100g'),
      reviewStatus: json['review_status'] as String,
      nutritionSource: json['nutrition_source'] as String,
    );
  }

  final String id;
  final String? foodId;
  final int position;
  final String sourceText;
  final String canonicalName;
  final String portionLabel;
  final double grams;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final String reviewStatus;
  final String nutritionSource;
}
