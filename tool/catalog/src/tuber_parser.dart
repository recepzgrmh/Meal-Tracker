/// Pure parsers for TÜBER 2022 (Türkiye Beslenme Rehberi) appendix tables,
/// operating on `pdftotext -layout` output of the official PDF.
///
/// TÜBER publishes one *standard portion* per food, with the household measure
/// and the energy/nutrient content of that portion. The parsers read only what
/// the tables print. Deriving anything else (small/large portions, per-100 g
/// values) is the job of [PortionPolicy] and is always recorded in
/// `transformation_notes`.
library;

/// One row of `Ek 2.3.1 — Besinlerin standart porsiyonlarının enerji ve besin
/// ögesi içerikleri`.
class TuberPortionNutrients {
  const TuberPortionNutrients({
    required this.foodName,
    required this.portionGrams,
    required this.energyKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fiberG,
    required this.fatG,
  });

  final String foodName;
  final double portionGrams;
  final double energyKcal;
  final double proteinG;
  final double carbsG;
  final double fiberG;
  final double fatG;
}

/// One row of the `Ek 2.1.x` household measure tables.
class TuberHouseholdMeasure {
  const TuberHouseholdMeasure({required this.foodName, required this.measure});

  final String foodName;

  /// Verbatim `ÖLÇÜ/MİKTAR` text, e.g. `3 parmak veya 2 kibrit kutusu veya 60 g`.
  final String measure;

  /// The gram figure printed inside [measure], when the table prints one.
  /// Returns `null` for volume-only rows (e.g. `180 mL`) so the caller must
  /// decide — and document — any volume-to-mass conversion.
  double? get statedGrams {
    final match = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:g|gram)\b',
    ).firstMatch(measure);
    return match == null
        ? null
        : double.parse(match.group(1)!.replaceAll(',', '.'));
  }

  /// The millilitre figure printed inside [measure], when present.
  double? get statedMillilitres {
    final match = RegExp(r'(\d+(?:[.,]\d+)?)\s*mL\b').firstMatch(measure);
    return match == null
        ? null
        : double.parse(match.group(1)!.replaceAll(',', '.'));
  }
}

final _whitespace = RegExp(r'\s+');

/// Parses `Ek 2.3.1`. Column order printed by the table is:
/// `Miktarı (g) | Enerji (kkal) | Protein (g) | Karbonhidrat (g) | Lif (g) | Yağ (g) | ...`
List<TuberPortionNutrients> parseTuberPortionNutrients(String layoutText) {
  final rows = <TuberPortionNutrients>[];
  final pattern = RegExp(
    r'^(?<name>[A-Za-zÇĞİIÖŞÜçğıiöşü][^\d]*?[A-Za-zÇĞİIÖŞÜçğıiöşü.)])\s+'
    r'(?<grams>\d+(?:[.,]\d+)?)\s+'
    r'(?<kcal>\d+(?:[.,]\d+)?)\s+'
    r'(?<protein>\d+(?:[.,]\d+)?)\s+'
    r'(?<carbs>\d+(?:[.,]\d+)?)\s+'
    r'(?<fiber>\d+(?:[.,]\d+)?)\s+'
    r'(?<fat>\d+(?:[.,]\d+)?)\s+'
    r'(?<rest>\d.*)$',
  );

  for (final rawLine in layoutText.split('\n')) {
    final line = rawLine.replaceAll(_whitespace, ' ').trim();
    if (line.isEmpty) continue;
    final match = pattern.firstMatch(line);
    if (match == null) continue;

    final name = match.namedGroup('name')!.trim();
    // Table headers and page furniture never name a food.
    if (name.length < 3 || name.contains('|')) continue;

    rows.add(
      TuberPortionNutrients(
        foodName: name,
        portionGrams: _num(match.namedGroup('grams')!),
        energyKcal: _num(match.namedGroup('kcal')!),
        proteinG: _num(match.namedGroup('protein')!),
        carbsG: _num(match.namedGroup('carbs')!),
        fiberG: _num(match.namedGroup('fiber')!),
        fatG: _num(match.namedGroup('fat')!),
      ),
    );
  }
  return rows;
}

/// Parses the `ÖLÇÜ/MİKTAR` rows of the `Ek 2.1.x` tables.
///
/// `pdftotext -layout` renders these two-column tables as `name` + run of
/// spaces + `measure`, but a long food name wraps onto its own line with the
/// measure printed beside the *first* fragment. Wrapped fragments are joined so
/// a row like `Nohut, fasulye, barbunya, iç bakla, / börülce (haşlanmış)` keeps
/// its full published name instead of being silently truncated.
List<TuberHouseholdMeasure> parseTuberHouseholdMeasures(String layoutText) {
  final rows = <TuberHouseholdMeasure>[];
  final splitPattern = RegExp(r'^(?<name>\S.*?)\s{2,}(?<measure>\S.*)$');
  var pendingName = <String>[];
  var pendingMeasure = <String>[];
  // True only when the measure was printed on its own line, which is the one
  // layout in which a following text line really is a wrapped name fragment.
  var wrapped = false;

  void flush() {
    if (pendingName.isEmpty || pendingMeasure.isEmpty) {
      pendingName = [];
      pendingMeasure = [];
      wrapped = false;
      return;
    }
    final name = _cleanFoodName(pendingName.join(' '));
    final measure = pendingMeasure
        .join(' ')
        .replaceAll(_whitespace, ' ')
        .trim();
    pendingName = [];
    pendingMeasure = [];
    wrapped = false;
    if (name.length < 3 || !_looksLikeMeasure(measure)) return;
    rows.add(TuberHouseholdMeasure(foodName: name, measure: measure));
  }

  for (final rawLine in layoutText.split('\n')) {
    final line = rawLine.replaceAll('\t', '  ');
    if (line.trim().isEmpty) {
      flush();
      continue;
    }

    final split = splitPattern.firstMatch(line.trimLeft());
    if (split != null) {
      final measure = split.namedGroup('measure')!;
      if (_looksLikeMeasure(measure)) {
        flush();
        pendingName = [split.namedGroup('name')!];
        pendingMeasure = [measure];
        continue;
      }
      flush();
      continue;
    }

    final text = line.trim();
    if (_looksLikeMeasure(text) &&
        pendingName.isNotEmpty &&
        pendingMeasure.isEmpty) {
      pendingMeasure = [text];
      wrapped = true;
      continue;
    }
    if (wrapped &&
        pendingMeasure.isNotEmpty &&
        !_looksLikeMeasure(text) &&
        _looksLikeNameFragment(text)) {
      // Continuation of a wrapped food name printed below its measure.
      pendingName.add(text);
      continue;
    }
    if (pendingMeasure.isEmpty && _looksLikeNameFragment(text)) {
      pendingName.add(text);
      continue;
    }
    flush();
    // A name that fills the whole line starts the next row rather than ending it.
    if (_looksLikeNameFragment(text)) pendingName.add(text);
  }
  flush();
  return rows;
}

const _measureUnits = [
  ' g',
  'gram',
  'mL',
  'adet',
  'kupa',
  'kase',
  'dilim',
  'parmak',
  'avuç',
  'kepçe',
  'kaşık',
  'porsiyon',
  'boy',
  'yumruk',
  'kibrit',
  'el ayası',
];

bool _looksLikeMeasure(String text) {
  if (!RegExp(r'^(?:\d|½|¾|¼|⅓|⅔|Suyu)').hasMatch(text)) return false;
  return _measureUnits.any(text.contains);
}

bool _looksLikeNameFragment(String text) =>
    RegExp(r'^[A-Za-zÇĞİIÖŞÜçğıiöşü]').hasMatch(text) &&
    !text.contains('  ') &&
    text.length < 60;

/// Strips the superscript footnote markers TÜBER prints after a food name
/// (`Bulgur, pişmiş3-6`, `Ekmek1`, `Nohut, fasulye, barbunya, iç bakla1 ,`).
String _cleanFoodName(String raw) => raw
    .replaceAll(_whitespace, ' ')
    .trim()
    .replaceAll(RegExp(r'(?<=[A-Za-zÇĞİIÖŞÜçğıiöşü)])\d+(?:[-,]\d+)*'), '')
    .replaceAllMapped(RegExp(r'\s+([,.])'), (match) => match.group(1)!)
    .replaceAll(RegExp(r'[\d,\-\s]+$'), '')
    .trim();

/// Finds the single row whose food name equals [foodName] exactly.
///
/// Deliberately exact: fuzzy matching a guide row to a catalog food is how
/// unverifiable values get in.
T? findExact<T>(List<T> rows, String foodName, String Function(T) nameOf) {
  final matches = rows.where((row) => nameOf(row) == foodName).toList();
  return matches.length == 1 ? matches.single : null;
}

double _num(String raw) => double.parse(raw.replaceAll(',', '.'));
