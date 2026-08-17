# Meal Clarity — Onboarding Asset Brief & Generation Prompts

Status: ready for asset production  
Date: 17 August 2026

## 1. Asset decision

Only one custom raster asset is recommended for onboarding. The interactive
accuracy demo must be built with real Flutter components, not a baked screenshot
or animation file. This keeps text accessible, supports localization, and makes
the product differentiator demonstrably interactive.

Required:

- `onboarding_hero_breakfast.webp`

Optional later:

- three calibrated portion-reference photographs for white cheese
- empty-history food still life

Do not generate logos, icons, text, UI screenshots, fake charts, or permission
illustrations. Use code-native typography and Material/Cupertino-compatible
icons.

## 2. Visual system

- style: premium editorial food photography, believable and appetizing
- background: warm white / very pale neutral stone
- light: soft natural window light from upper left
- palette: egg yellow, toasted brown, clean white, restrained fresh green
- composition: generous negative space, one clear focal plate
- camera: 45-degree top-down, 50 mm editorial food lens feeling
- shadows: soft and physically plausible
- prohibited: text, logo, hands, cutlery crossing safe zones, purple gradients,
  glassmorphism, sparkles, floating AI particles, excessive garnish

## 3. Required hero prompt

Target output:

- portrait 4:5 master, minimum 2048×2560
- export WebP at approximately 1600×2000, quality 82–88
- compose for a mobile crop; keep the top 22% and bottom 18% visually quiet
- no transparency required

Prompt:

```text
Premium editorial breakfast food photography for a modern nutrition tracking
mobile app onboarding screen. A simple Turkish breakfast plate with two soft-
boiled egg halves, half of a sesame simit, and a modest serving of realistic
full-fat white cheese cubes. Warm white ceramic plate on a very pale limestone
surface, soft natural window light from the upper left, subtle physically
accurate shadows, restrained fresh parsley garnish, highly realistic food
texture, calm minimal composition, sophisticated Scandinavian editorial
styling, 45-degree top-down camera angle, 50mm lens feeling, generous clean
negative space around the plate, especially quiet space in the top 22 percent
and bottom 18 percent for mobile UI overlay. Natural colors, appetizing but not
over-saturated, premium commercial food photography, no people, no hands, no
utensils crossing the composition, no packaging, no text, no letters, no logo,
no interface elements, no charts, no sparkles, no purple, no glassmorphism.
Portrait 4:5.
```

Negative prompt, if supported:

```text
illustration, 3D render, plastic food, duplicate eggs, malformed food, impossible
shadows, excessive garnish, restaurant table clutter, hands, people, fork,
knife, text, logo, watermark, UI, neon, purple gradient, AI particles, bokeh
overload, harsh studio flash, oversaturated colors
```

## 4. Optional white-cheese portion prototype prompts

Important: these images are prototypes, not validated measurement references.
Before the UI labels them `15 g`, `30 g`, or `50 g`, reproduce or photograph the
portions with a real scale. Generated cube size and density are not measurement
evidence.

Generate all three from the same seed/reference image, camera, plate, surface,
lighting, crop, and cheese type. Only the amount changes.

Base prompt:

```text
Scientific-looking but natural editorial food reference photograph of Turkish
full-fat white cheese on a small matte warm-white ceramic side plate. The cheese
has realistic moist crumbly texture and consistent 1.8 cm cubes. Pale limestone
background, soft natural window light from upper left, fixed 45-degree top-down
camera, fixed crop, fixed 50mm lens perspective, subtle accurate shadow, no
garnish except one tiny parsley leaf placed in the exact same position across
the series. Minimal neutral composition designed for a food portion selection
interface. No text, no numbers, no logo, no hands, no utensils, no extra food,
no perspective change, no lighting change, no plate change. Square 1:1.
```

Variant suffixes:

```text
SMALL PROTOTYPE: show exactly 2 consistent cheese cubes with generous empty
plate area. Preserve every other visual property.
```

```text
REGULAR PROTOTYPE: show exactly 4 consistent cheese cubes arranged naturally.
Preserve every other visual property.
```

```text
LARGE PROTOTYPE: show exactly 7 consistent cheese cubes arranged naturally.
Preserve every other visual property.
```

## 5. Delivery checklist

For every delivered asset record:

- generator and model/version
- prompt and negative prompt
- seed/reference image ID
- generation date
- original master
- exported WebP dimensions and byte size
- visual QA owner
- for portion assets: actual measured grams, scale model, validation date, and
  whether the asset is allowed to display a gram claim

Naming:

```text
assets/images/onboarding/onboarding_hero_breakfast_v1.webp
assets/images/portions/white_cheese_small_v1.webp
assets/images/portions/white_cheese_regular_v1.webp
assets/images/portions/white_cheese_large_v1.webp
```

## 6. Acceptance criteria

- hero remains legible behind both black and white fallback overlays
- crop works at iPhone SE and tall Android aspect ratios
- compressed hero is under 350 KB where visual quality allows
- no embedded text or brand mark
- image is labeled as generated in `docs/ASSET_PROVENANCE.md`
- portion prototype is never presented as calibrated until measurement QA is
  complete

