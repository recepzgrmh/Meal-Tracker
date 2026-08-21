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

  /// Applies the category factor for [sizeClass] to [regularGrams].
  ///
  /// Throws when the configured factor falls outside the policy band, so a
  /// silent edit to the policy file cannot quietly widen portion spread.
  double derive(String categoryName, String sizeClass, double regularGrams) {
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
