// Deterministic Turkish -> ASCII slug for catalog food identifiers.
//
// `foods.source_food_id` IS the slug, and `image_prompt.dart` guards every slug
// with `^[a-z0-9]+(-[a-z0-9]+)*$`, so this has to produce pure ASCII.
//
// An explicit map is required because Dart's `toLowerCase()` is
// locale-invariant: it lowercases 'Ç'->'ç' and 'I'->'i', but leaves 'ç', 'ğ',
// 'ı', 'ö', 'ş', 'ü' as themselves. Without the map those survive lowercasing
// and are then swallowed by the `[^a-z0-9]` pass, so "Antep fıstığı" would
// collapse to "antep-f-st" instead of "antep-fistigi".
//
// (Order is not load-bearing here -- Dart maps 'İ' U+0130 directly to ASCII
// 'i', not to 'i' + U+0307 combining dot. The map is applied first only so the
// transliteration is explicit rather than relying on that behaviour.)

const Map<String, String> turkishAsciiMap = <String, String>{
  'ç': 'c',
  'Ç': 'c',
  'ğ': 'g',
  'Ğ': 'g',
  'ı': 'i',
  'I': 'i',
  'İ': 'i',
  'i': 'i',
  'ö': 'o',
  'Ö': 'o',
  'ş': 's',
  'Ş': 's',
  'ü': 'u',
  'Ü': 'u',
  'â': 'a',
  'Â': 'a',
  'î': 'i',
  'Î': 'i',
  'û': 'u',
  'Û': 'u',
};

final RegExp _slugGuard = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

/// Transliterates Turkish characters to ASCII and returns a slug.
///
/// Throws [ArgumentError] when the name contains no slug-able character, so a
/// silently empty `source_food_id` can never reach the database.
String turkishSlug(String name) {
  final buffer = StringBuffer();
  for (final rune in name.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(turkishAsciiMap[char] ?? char);
  }

  final slug = buffer
      .toString()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  if (slug.isEmpty) {
    throw ArgumentError.value(name, 'name', 'Produces an empty slug');
  }
  if (!_slugGuard.hasMatch(slug)) {
    throw StateError('turkishSlug produced a non-conforming slug: "$slug"');
  }
  return slug;
}

/// True when [slug] satisfies the same guard `image_prompt.dart` applies.
bool isValidSlug(String slug) => _slugGuard.hasMatch(slug);
