import '../network/node_backend_client.dart';

class CatalogFoodCandidate {
  const CatalogFoodCandidate({
    required this.foodId,
    required this.name,
    required this.matchedAlias,
    required this.score,
    required this.defaultGrams,
    required this.defaultPortionLabel,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.nutritionSource,
  });

  final String foodId;
  final String name;
  final String matchedAlias;
  final double score;

  /// Null when the catalog holds no `tr-TR` portion row for this food.
  ///
  /// That is a normal state, not an error: Tier A deliberately ships foods
  /// whose portion could not be resolved from a published TÜBER row. Callers
  /// must fall back to the per-100 g basis and ask the user for the amount.
  final double? defaultGrams;
  final String? defaultPortionLabel;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final String nutritionSource;
}

abstract interface class FoodCatalogRepository {
  Future<List<CatalogFoodCandidate>> search({
    required String query,
    required String locale,
  });
}

class NodeFoodCatalogRepository implements FoodCatalogRepository {
  const NodeFoodCatalogRepository(this._backend);

  final NodeBackendClient _backend;

  @override
  Future<List<CatalogFoodCandidate>> search({
    required String query,
    required String locale,
  }) async {
    final response = await _backend.invoke(
      'search-food-catalog',
      body: {'query': query.trim(), 'locale': locale, 'limit': 10},
    );
    final payload = response.data;
    if (payload is! Map || payload['contractVersion'] != 'catalog-search.v2') {
      throw const FormatException('Unsupported catalog search response');
    }
    final rows = payload['candidates'];
    if (rows is! List) throw const FormatException('Candidates must be a list');
    return rows
        .map((value) {
          final row = Map<String, dynamic>.from(value as Map);
          final nutrition = Map<String, dynamic>.from(
            row['nutritionPer100g'] as Map,
          );
          return CatalogFoodCandidate(
            foodId: row['foodId'] as String,
            name: row['canonicalName'] as String,
            matchedAlias: row['matchedAlias'] as String,
            score: (row['score'] as num).toDouble(),
            defaultGrams: (row['defaultGrams'] as num?)?.toDouble(),
            defaultPortionLabel: row['defaultPortionLabel'] as String?,
            caloriesPer100g: (nutrition['calories'] as num).toDouble(),
            proteinPer100g: (nutrition['protein'] as num).toDouble(),
            carbsPer100g: (nutrition['carbs'] as num).toDouble(),
            fatPer100g: (nutrition['fat'] as num).toDouble(),
            nutritionSource: row['nutritionSource'] as String,
          );
        })
        .toList(growable: false);
  }
}
