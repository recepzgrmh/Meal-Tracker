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
      (
        PreparationState.dried,
        r'\bkuru\b|\bkurusu\b|kurutulmus|gunkurusu|\bkuru,',
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
}) {
  if (hasDistinctSpecies(turkompName)) return null;

  final normalized = normalizeFoodName(turkompName);
  final base = baseFoodName(turkompName);
  final state = preparationState(turkompName);

  TuberAnchor anchorFor(String rowName, TuberMatchMode mode, {double? grams}) =>
      TuberAnchor(
        rowName: rowName,
        mode: mode,
        turkompState: state,
        tuberState: preparationState(rowName),
        statedGrams: grams,
      );

  // 1. Ek 2.3.1, preferring a row whose state already agrees.
  final nutrientHits = nutrientRows
      .where(
        (row) =>
            normalizeFoodName(row.foodName) == normalized ||
            baseFoodName(row.foodName) == base,
      )
      .toList();
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
        normalizeFoodName(row.foodName) == base) {
      return anchorFor(
        row.foodName,
        TuberMatchMode.tuberMeasureGrams,
        grams: row.statedGrams,
      );
    }
  }

  // 3. Ek 2.1 grouped member.
  for (final row in gramRows) {
    final members = memberNames(row.foodName);
    if (members.contains(normalized) || members.contains(base)) {
      return anchorFor(
        row.foodName,
        TuberMatchMode.tuberGroupMemberGrams,
        grams: row.statedGrams,
      );
    }
  }

  return null;
}
