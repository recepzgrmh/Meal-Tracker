/// Production prompts for the controlled portion-reference photo set.
///
/// The prompt describes only the scene. It never asks the image model to
/// estimate, imply, or render a weight — the gram figure comes from the
/// catalog portion record and is rendered by the app UI, never by the image.
library;

const productionStandardVersion = 'portion-reference-standard-v1';

const _sizeWord = {'small': 'SMALL', 'regular': 'REGULAR', 'large': 'LARGE'};

/// Builds the image-generation prompt for one portion of one food.
///
/// [foodEn] is the English canonical name, [container] is one of `plate`,
/// `bowl`, `glass` or `small_plate`,
/// and [grams] is the catalog portion weight — quoted only so the operator and
/// the reviewer can tie the render back to its record.
String buildPortionPrompt({
  required String foodEn,
  required String sizeClass,
  required num grams,
  required String container,
  String? canonicalGarnish,
}) {
  final size = _sizeWord[sizeClass];
  if (size == null) {
    throw ArgumentError.value(
      sizeClass,
      'sizeClass',
      'Expected small/regular/large',
    );
  }
  final vessel = switch (container) {
    'plate' => 'plate',
    'bowl' => 'bowl',
    // A glass of ayran and a spoon of oil cannot be staged on a dinner plate
    // at a fixed camera height and still read as a portion.
    'glass' => 'glass',
    'small_plate' => 'small side plate',
    _ => throw ArgumentError.value(
      container,
      'container',
      'Expected plate/bowl/glass/small_plate',
    ),
  };
  final garnish = canonicalGarnish == null
      ? 'no decorative garnish unless part of the canonical recipe'
      : 'no decorative garnish beyond $canonicalGarnish, which is part of the canonical recipe';

  return 'Photorealistic overhead food reference photograph of $foodEn, '
      'representing the $size controlled portion of ${_grams(grams)} grams. '
      'Served on the exact same matte white $vessel used across the three '
      'portion variants. Fixed 85-degree overhead camera, fixed camera '
      'distance, neutral light stone tabletop, soft diffused daylight, natural '
      'appetizing food color, realistic household serving, entire $vessel '
      'visible, centered composition, no utensils, no hands, no napkin, no '
      'packaging, no logo, no text, no watermark, $garnish, no dramatic '
      'restaurant styling, no hard shadows. Only the amount of food should '
      'differ between portion variants. Square 1:1 composition, sRGB, '
      'production-quality mobile nutrition tracking reference image.';
}

/// The shared scene contract for one food's three variants.
String buildConsistencyNote({
  required String foodEn,
  required String container,
  required num smallGrams,
  required num regularGrams,
  required num largeGrams,
}) {
  final vessel = switch (container) {
    'bowl' => 'bowl',
    'glass' => 'glass',
    'small_plate' => 'small side plate',
    _ => 'plate',
  };
  // Vessels that hold a depth of food vary by fill level; flat vessels vary by
  // the area and height the food occupies.
  final fillClause = container == 'bowl' || container == 'glass'
      ? 'The $vessel diameter and depth are identical in all three renders; only '
            'the fill level changes.'
      : 'The $vessel diameter is identical in all three renders; only the area, '
            'height and realistic volume of the food change.';

  return 'All three variants of $foodEn are the same scene, re-shot with a '
      'different amount of food. Identical across small/regular/large: the '
      'matte white $vessel and its diameter, the 85-degree overhead camera '
      'angle, the camera distance, the neutral light stone tabletop, the soft '
      'diffused daylight, the white balance, and the framing. $fillClause '
      'The food keeps the same color, cut and cooking state. Nothing is added '
      'or removed between variants — no sauce, oil, herb or side item appears '
      'in one variant and not another. Portion weights are '
      '${_grams(smallGrams)} g / ${_grams(regularGrams)} g / '
      '${_grams(largeGrams)} g and must read as visibly increasing at a '
      '120-160 px thumbnail size. No weight, number or label may appear in '
      'the image itself.';
}

/// `food-portions/{slug}/{slug}--{size}--{grams}g.webp`
String buildImagePath({
  required String foodSlug,
  required String sizeClass,
  required num grams,
}) {
  if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(foodSlug)) {
    throw ArgumentError.value(
      foodSlug,
      'foodSlug',
      'Slug must be lowercase ASCII, digits and hyphens',
    );
  }
  return 'food-portions/$foodSlug/$foodSlug--$sizeClass--${_grams(grams)}g.webp';
}

String _grams(num grams) => grams == grams.roundToDouble()
    ? grams.round().toString()
    : grams.toString();
