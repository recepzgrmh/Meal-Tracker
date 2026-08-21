import 'dart:convert';

/// Central, documented policy for deriving `small` and `large` reference
/// portions from an officially published `regular` portion.
///
/// Derived weights are a product decision, not a published measurement. Every
/// derived row must say so in `transformation_notes`.
class PortionPolicy {
  PortionPolicy._(this._json);

  factory PortionPolicy.parse(String jsonSource) =>
      PortionPolicy._(jsonDecode(jsonSource) as Map<String, dynamic>);

  final Map<String, dynamic> _json;

  String get version => _json['policyVersion'] as String;

  ({double min, double max}) band(String sizeClass) {
    final bands = _json['derivedFactorBands'] as Map<String, dynamic>;
    final band = bands[sizeClass] as Map<String, dynamic>;
    return (
      min: (band['min'] as num).toDouble(),
      max: (band['max'] as num).toDouble(),
    );
  }

  Map<String, dynamic> category(String name) {
    final categories = _json['categories'] as Map<String, dynamic>;
    final category = categories[name];
    if (category == null) {
      throw ArgumentError.value(name, 'category', 'Unknown portion category');
    }
    return category as Map<String, dynamic>;
  }

  /// Whether `small` comes from a published source for this category rather
  /// than from a derivation factor.
  bool smallIsPublished(String categoryName) =>
      category(categoryName)['smallSource'] == 'published';

  double roundToGrams(String categoryName) =>
      (category(categoryName)['roundToGrams'] as num).toDouble();

  /// Whether [sizeClass] is derived as a multiple of the published unit rather
  /// than by a factor.
  ///
  /// Discrete foods break the factor model: 0.65 of an egg or of a slice of
  /// bread is not a portion anyone eats, it is an artefact of the arithmetic.
  bool usesUnitMultiple(String categoryName, String sizeClass) =>
      category(categoryName)['${sizeClass}Source'] == 'unit_multiple';

  /// The whole- or half-unit multiple configured for [sizeClass].
  double unitMultiple(String categoryName, String sizeClass) {
    final key = '${sizeClass}UnitMultiple';
    final raw = category(categoryName)[key];
    if (raw == null) {
      throw StateError('Category $categoryName publishes no $key');
    }
    final multiple = (raw as num).toDouble();
    if (multiple <= 0) {
      throw StateError('Category $categoryName $key=$multiple must be > 0');
    }
    return multiple;
  }

  /// Absolute sanity band for any weight in this category, when declared.
  ///
  /// Guards against a derived or anchored weight that is arithmetically valid
  /// but obviously not a serving — 833 g of cucumber, 17 g of olive oil.
  ({double min, double max})? plausibleGramsBand(String categoryName) {
    final raw = category(categoryName)['plausibleGramsBand'];
    if (raw == null) return null;
    final band = (raw as List).cast<num>();
    return (min: band.first.toDouble(), max: band.last.toDouble());
  }

  /// Container the category is served in, for the reference-image prompt.
  String? container(String categoryName) =>
      category(categoryName)['container'] as String?;

  /// Applies the category factor for [sizeClass] to [regularGrams].
  ///
  /// Throws when the configured factor falls outside the policy band, so a
  /// silent edit to the policy file cannot quietly widen portion spread.
  double derive(String categoryName, String sizeClass, double regularGrams) {
    if (usesUnitMultiple(categoryName, sizeClass)) {
      throw StateError(
        'Category $categoryName derives $sizeClass as a unit multiple; call '
        'deriveFromUnit instead of applying a factor',
      );
    }
    final key = '${sizeClass}Factor';
    final raw = category(categoryName)[key];
    if (raw == null) {
      throw StateError('Category $categoryName publishes no $key');
    }
    final factor = (raw as num).toDouble();
    final limits = band(sizeClass);
    final exempt = category(categoryName)['bandExemption'] != null;
    if (!exempt && (factor < limits.min || factor > limits.max)) {
      throw StateError(
        'Category $categoryName $key=$factor is outside the documented '
        '${limits.min}-${limits.max} band and carries no bandExemption',
      );
    }
    return roundGrams(regularGrams * factor, roundToGrams(categoryName));
  }
}

/// Rounds to a kitchen-plausible step so a derived weight never implies
/// scale-level precision.
double roundGrams(double grams, double step) => (grams / step).round() * step;

extension UnitMultipleDerivation on PortionPolicy {
  /// Derives [sizeClass] as a multiple of the published [unitGrams].
  double deriveFromUnit(
    String categoryName,
    String sizeClass,
    double unitGrams,
  ) {
    if (!usesUnitMultiple(categoryName, sizeClass)) {
      throw StateError(
        'Category $categoryName does not derive $sizeClass from a unit '
        'multiple; call derive instead',
      );
    }
    return roundGrams(
      unitGrams * unitMultiple(categoryName, sizeClass),
      roundToGrams(categoryName),
    );
  }
}
