// Matches a TürKomp record name against the TÜBER rows that publish a portion.
//
// Shared by build_selection.dart (scoring), draft_mapping.dart (proposing a
// portion anchor) and the manifest builder (resolving one). It decides only
// WHICH published row is a candidate for a food; it never reads or produces a
// gram value — build_pilot_manifest.dart does that, out of a hashed snapshot.
//
// The hard rule here is that a food may only inherit a TÜBER row's portion when
// the two describe the same thing in the same state. TÜBER publishes "Elma"
// (fresh apple) and TürKomp publishes "Elma, kuru" (dried apple); a name-only
// match would silently give dried apple a fresh apple's portion. The same trap
// applies to "Mısır, pişmiş" vs dry corn and to "Yumurta" (2 hen eggs) vs
// "Yumurta, devekuşu" (ostrich).
import 'tuber_parser.dart';

/// How a food reached its published portion row.
enum TuberMatchMode {
  /// Exact or base-name hit in Ek 2.3.1, which publishes a portion weight.
  tuberFoodRow,

  /// Whole-row hit in Ek 2.1 where the measure text states grams.
  tuberMeasureGrams,

  /// Hit on one named member of a grouped Ek 2.1 row that states grams,
  /// e.g. "Nohut, fasulye, barbunya, iç bakla, börülce (haşlanmış)" -> 130 g.
  tuberGroupMemberGrams,
}

/// Preparation state, because a portion is only transferable within one state.
enum PreparationState { fresh, dried, cooked, roasted, canned, frozen, raw }

const Map<String, String> _asciiMap = <String, String>{
  'ç': 'c',
  'Ç': 'c',
  'ğ': 'g',
  'Ğ': 'g',
  'ı': 'i',
  'I': 'i',
  'İ': 'i',
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

/// Lowercased ASCII form, keeping parentheticals and punctuation.
String _asciiLower(String name) {
  final buffer = StringBuffer();
  for (final rune in name.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_asciiMap[char] ?? char);
  }
  return buffer.toString().toLowerCase();
}

/// Lowercased ASCII form with parentheticals and punctuation removed.
String normalizeFoodName(String name) {
  return _asciiLower(name)
      .replaceAll(RegExp(r'\(.*?\)'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// The head noun: everything before the first comma, normalized.
///
/// TÜBER names a food group representative ("Elma"); TürKomp names cultivars
/// ("Elma, yazlık, Gala çeşidi"). Comparing head nouns is what lets one
/// published row serve the varieties beneath it.
String baseFoodName(String name) => normalizeFoodName(name.split(',').first);

const List<(PreparationState, String)> _statePatterns =
    <(PreparationState, String)>[
      (PreparationState.roasted, r'kavrulmus|kavlatilmis'),
      (
        PreparationState.cooked,
        r'\bpismis\b|haslanmis|kozlenmis|kizartilmis|pisirilmis|kavurma',
      ),
      (PreparationState.canned, r'konserve|salamura|\bturs'),
      (PreparationState.frozen, r'dondurulmus'),
      // "kuru madde" is dry MATTER -- the fat-content spec in cheese names like
      // "yag, kuru maddede > % 45" -- not a dried food. The exclusion matters
      // because preparationState reads parentheticals, where that spec lives.
      (
        PreparationState.dried,
        r'\bkuru(?!\s+madde)\b|\bkurusu\b|kurutulmus|gunkurusu',
      ),
      (PreparationState.raw, r'\bcig\b'),
    ];

/// Best-effort preparation state, defaulting to [PreparationState.fresh].
///
/// Deliberately does NOT use [normalizeFoodName]: TÜBER records the state in a
/// parenthetical -- "Nohut, fasulye, barbunya, iç bakla, börülce (haşlanmış)"
/// -- and normalizeFoodName strips parentheticals, which would report that
/// cooked row as fresh and hand a cooked portion to raw dry beans.
PreparationState preparationState(String name) {
  final normalized = _asciiLower(name);
  for (final (state, pattern) in _statePatterns) {
    if (RegExp(pattern).hasMatch(normalized)) return state;
  }
  return PreparationState.fresh;
}

/// Species/varietal qualifiers that make a record a different food from the
/// TÜBER row its head noun matches (quail vs hen eggs, goat vs cow milk).
final RegExp _distinctSpecies = RegExp(
  r'bildircin|devekusu|hindi\b|\bkaz\b|ordek|keci\b|manda\b|koyun\b|saraplik',
);

bool hasDistinctSpecies(String name) =>
    _distinctSpecies.hasMatch(normalizeFoodName(name));

/// Splits a grouped TÜBER row into its named members.
///
/// Real separators in Ek 2.1 are commas ("Nohut, fasulye, barbunya"), "veya"
/// ("Galeta veya Grissini"), slashes ("Buğday/pirinç gevreği") and hyphens
/// ("Pide- Bazlama-Lavaş"). "vb." marks an open class and is dropped.
List<String> memberNames(String rowName) {
  final withoutParens = rowName.replaceAll(RegExp(r'\(.*?\)'), ' ');
  final parts = withoutParens
      .split(RegExp(r',|\s+veya\s+|/|\bvb\.?\b|(?<=[a-zçğıöşü])-(?=\s*\S)'))
      .map(normalizeFoodName)
      .where((part) => part.length > 2)
      .toList();
  if (parts.isEmpty) return const [];

  // A slash list can share a trailing head noun: "Buğday/pirinç gevreği" means
  // wheat FLAKES and rice FLAKES, not raw wheat. Without redistributing
  // "gevreği" the bare member "buğday" would match raw durum wheat and hand it
  // a 30 g breakfast-cereal portion.
  final last = parts.last.split(' ');
  if (rowName.contains('/') && last.length > 1) {
    final headNoun = last.last;
    return <String>[
      for (final part in parts.take(parts.length - 1))
        part.split(' ').length == 1 ? '$part $headNoun' : part,
      parts.last,
    ];
  }
  return parts;
}

/// A published TÜBER row proposed as a food's portion anchor.
class TuberAnchor {
  const TuberAnchor({
    required this.rowName,
    required this.mode,
    required this.turkompState,
    required this.tuberState,
    this.statedGrams,
  });

  final String rowName;
  final TuberMatchMode mode;
  final PreparationState turkompState;
  final PreparationState tuberState;

  /// Present for the Ek 2.1 modes; Ek 2.3.1 weights are read by the builder.
  final double? statedGrams;

  /// False when the two names describe different preparation states.
  ///
  /// A mismatch is surfaced, never silently dropped and never silently used:
  /// the draft marks it for review so a human decides whether e.g. TÜBER's
  /// "Ceviz" means the dried kernel TürKomp lists as "Ceviz, iç, kuru".
  bool get stateMatches => turkompState == tuberState;

  String get stateNote =>
      'TürKomp record is ${turkompState.name}; TÜBER row "$rowName" is '
      '${tuberState.name}.';
}

/// Finds the strongest published portion anchor for [turkompName], or null.
///
/// Order matches source strength: a food-specific Ek 2.3.1 row beats a whole
/// Ek 2.1 measure row, which beats membership of a grouped Ek 2.1 row.
TuberAnchor? findTuberAnchor(
  String turkompName, {
  required List<TuberPortionNutrients> nutrientRows,
  required List<TuberHouseholdMeasure> measureRows,
  String? sourceRecordId,
}) {
  if (hasDistinctSpecies(turkompName)) return null;

  final recordGroup = sourceRecordId == null
      ? FoodGroup.other
      : groupFromRecordCode(sourceRecordId);

  final normalized = normalizeFoodName(turkompName);
  final base = baseFoodName(turkompName);
  final state = preparationState(turkompName);

  // A cross-group hit is a name collision, not a match: drop it rather than
  // surface it, because no curation decision can make a fish a legume.
  TuberAnchor? anchorFor(String rowName, TuberMatchMode mode, {double? grams}) {
    if (!groupsCompatible(recordGroup, groupFromRowName(rowName))) return null;
    return TuberAnchor(
      rowName: rowName,
      mode: mode,
      turkompState: state,
      tuberState: preparationState(rowName),
      statedGrams: grams,
    );
  }

  // 1. Ek 2.3.1, preferring a row whose state already agrees.
  var nutrientHits = nutrientRows
      .where(
        (row) =>
            normalizeFoodName(row.foodName) == normalized ||
            baseFoodName(row.foodName) == base,
      )
      .toList();
  if (nutrientHits.isEmpty) {
    // Fall back to token matching, which handles TürKomp's inverted names.
    nutrientHits = nutrientRows
        .where((row) => tokensCompatible(turkompName, row.foodName))
        .toList();
  }
  if (nutrientHits.isNotEmpty) {
    final agreeing = nutrientHits.firstWhere(
      (row) => preparationState(row.foodName) == state,
      orElse: () => nutrientHits.first,
    );
    return anchorFor(agreeing.foodName, TuberMatchMode.tuberFoodRow);
  }

  // 2. Ek 2.1 whole-row, grams only.
  final gramRows = measureRows.where((row) => row.statedGrams != null).toList();
  for (final row in gramRows) {
    if (normalizeFoodName(row.foodName) == normalized ||
        normalizeFoodName(row.foodName) == base ||
        tokensCompatible(turkompName, row.foodName)) {
      final anchor = anchorFor(
        row.foodName,
        TuberMatchMode.tuberMeasureGrams,
        grams: row.statedGrams,
      );
      if (anchor != null) return anchor;
    }
  }

  // 3. Ek 2.1 grouped member.
  for (final row in gramRows) {
    final members = memberNames(row.foodName);
    if (members.contains(normalized) || members.contains(base)) {
      final anchor = anchorFor(
        row.foodName,
        TuberMatchMode.tuberGroupMemberGrams,
        grams: row.statedGrams,
      );
      if (anchor != null) return anchor;
    }
  }

  return null;
}

/// Coarse food group, used to stop a head-noun collision across groups.
///
/// TürKomp record codes are `GG.SS.NNNN` where the first pair is the food
/// group. The trap this exists for: "Barbunya (barbun)" is 04.01 — a red
/// mullet — but its head noun collides with the bean named in the TÜBER row
/// "Nohut, fasulye, barbunya, iç bakla, börülce (haşlanmış)". Matching on name
/// alone would serve a fish a legume's portion.
enum FoodGroup {
  dairy,
  egg,
  meat,
  fish,
  fat,
  grain,
  legumeSeed,
  vegetable,
  fruit,
  prepared,
  other,
}

/// Group implied by a TürKomp record code (`GG.SS.NNNN`).
FoodGroup groupFromRecordCode(String sourceRecordId) =>
    switch (sourceRecordId.split('.').first) {
      '01' => FoodGroup.dairy,
      '02' => FoodGroup.egg,
      '03' => FoodGroup.meat,
      '04' => FoodGroup.fish,
      '05' => FoodGroup.fat,
      '06' => FoodGroup.grain,
      '07' => FoodGroup.legumeSeed,
      '08' => FoodGroup.vegetable,
      '09' => FoodGroup.fruit,
      '12' => FoodGroup.prepared,
      _ => FoodGroup.other,
    };

const List<(FoodGroup, String)> _rowGroupPatterns = <(FoodGroup, String)>[
  (FoodGroup.dairy, r'sut|yogurt|peynir|kefir|ayran|kaymak'),
  (FoodGroup.egg, r'yumurta'),
  (FoodGroup.fish, r'balik|hamsi|alabalik|somon|palamut|ton\b'),
  (FoodGroup.meat, r'\bet\b|tavuk|kirmizi et|sakatat|sucuk|jambon|pastirma'),
  (
    FoodGroup.legumeSeed,
    r'nohut|fasulye|barbunya|bakla|borulce|mercimek|findik|badem|ceviz|fistik|tohum|cekirdek',
  ),
  (
    FoodGroup.grain,
    r'ekmek|bulgur|pirinc|makarna|yufka|simit|bazlama|lavas|pide|galeta|grissini|gevrek|musli|yulaf|misir gevregi|patlamis',
  ),
  (FoodGroup.fat, r'\byag\b|margarin|tereyag|zeytinyag'),
];

/// Group implied by a TÜBER row name.
FoodGroup groupFromRowName(String rowName) {
  final normalized = normalizeFoodName(rowName);
  for (final (group, pattern) in _rowGroupPatterns) {
    if (RegExp(pattern).hasMatch(normalized)) return group;
  }
  return FoodGroup.other;
}

/// True when a record's group can legitimately take a row's portion.
///
/// [FoodGroup.other] on either side is permissive: the row-name patterns above
/// do not cover fruit and vegetable rows, which are named after the food
/// itself and therefore carry no group keyword.
bool groupsCompatible(FoodGroup record, FoodGroup row) =>
    record == row ||
    row == FoodGroup.other ||
    record == FoodGroup.other ||
    record == FoodGroup.prepared;

/// True when a TÜBER row names the same food as a TürKomp record whose word
/// order is inverted.
///
/// TürKomp writes the genus first with qualifiers appended
/// ("Peynir, beyaz, tam yağlı"); TÜBER writes natural Turkish word order
/// ("Beyaz peynir, tam yağlı"). Head-noun comparison fails on every such name,
/// which is why no cheese matched before this rule existed.
///
/// Two conditions, and the second is what stops it over-matching:
///   1. every TÜBER token appears in the record's tokens, and
///   2. the record's own head clause is fully contained in the TÜBER tokens.
///
/// Condition 2 is what keeps TÜBER "Domates" off "Domates suyu": the record's
/// head clause is "domates suyu", and "suyu" is not a TÜBER token, so the
/// juice does not inherit the whole vegetable's portion.
bool tokensCompatible(String turkompName, String rowName) {
  Set<String> tokens(String value) =>
      normalizeFoodName(value).split(' ').where((t) => t.length > 1).toSet();

  final recordTokens = tokens(turkompName);
  final rowTokens = tokens(rowName);
  if (rowTokens.isEmpty || recordTokens.isEmpty) return false;
  if (!rowTokens.every(recordTokens.contains)) return false;

  final headClause = tokens(turkompName.split(',').first);
  return headClause.every(rowTokens.contains);
}
