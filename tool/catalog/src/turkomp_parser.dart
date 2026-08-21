/// Pure parser for TürKomp (https://turkomp.tarimorman.gov.tr) food detail pages.
///
/// TürKomp publishes composition per 100 g of edible portion. The parser only
/// reads what the page states; it never converts, scales, or infers a value.
library;

class TurkompComposition {
  const TurkompComposition({
    required this.sourceRecordId,
    required this.recordName,
    required this.componentsPer100g,
  });

  /// TürKomp food code, e.g. `01.02.0004`.
  final String sourceRecordId;
  final String recordName;

  /// Component name (as published, Turkish) -> `(amount, unit)` per 100 g.
  final Map<String, ({double amount, String unit})> componentsPer100g;

  double? amount(String component) => componentsPer100g[component]?.amount;

  double? get caloriesPer100g => amount('Enerji');
  double? get proteinPer100g => amount('Protein');
  double? get carbsPer100g => amount('Karbonhidrat');
  double? get fatPer100g => amount('Yağ, toplam');
}

final _tagPattern = RegExp(r'<[^>]+>');
final _rowPattern = RegExp(r'<tr[^>]*>(.*?)</tr>', dotAll: true);
final _cellPattern = RegExp(r'<t[dh][^>]*>(.*?)</t[dh]>', dotAll: true);
final _titlePattern = RegExp(r'<title>(.*?)</title>', dotAll: true);
final _codePattern = RegExp(r'\b(\d{2}\.\d{2}\.\d{4})\b');

/// Parses a TürKomp detail page.
///
/// [sourceRecordId] must be supplied by the caller when the page does not carry
/// the food code, so the record can never be attributed to a guessed code.
TurkompComposition parseTurkompFoodPage(String html, {String? sourceRecordId}) {
  final components = <String, ({double amount, String unit})>{};

  for (final row in _rowPattern.allMatches(html)) {
    final cells = _cellPattern
        .allMatches(row.group(1)!)
        .map((cell) => _plainText(cell.group(1)!))
        .toList(growable: false);
    if (cells.length < 4) continue;

    final name = cells[0];
    final unit = cells[1];
    if (name.isEmpty || unit.isEmpty) continue;
    // The average column repeats; the first numeric cell after the unit is it.
    final value = _firstNumber(cells.skip(2));
    if (value == null) continue;
    // `Enerji` is published twice (kcal and kJ). Keep kcal, the app's unit.
    if (name == 'Enerji' && unit != 'kcal') continue;
    components.putIfAbsent(name, () => (amount: value, unit: unit));
  }

  if (components.isEmpty) {
    throw const FormatException('No TürKomp component rows found in page');
  }

  final title = _titlePattern.firstMatch(html);
  final recordName = title == null ? '' : _recordNameFromTitle(title.group(1)!);
  final code = sourceRecordId ?? _codePattern.firstMatch(html)?.group(1);
  if (code == null || code.isEmpty) {
    throw const FormatException('TürKomp food code (source_record_id) missing');
  }

  return TurkompComposition(
    sourceRecordId: code,
    recordName: recordName,
    componentsPer100g: Map.unmodifiable(components),
  );
}

String _plainText(String html) => html
    .replaceAll(_tagPattern, ' ')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

double? _firstNumber(Iterable<String> cells) {
  for (final cell in cells) {
    final match = RegExp(r'^-?\d+(?:[.,]\d+)?$').firstMatch(cell);
    if (match != null) return double.parse(cell.replaceAll(',', '.'));
  }
  return null;
}

/// Extracts the food name from a TürKomp page title.
///
/// Titles are `Veri Bankası - NAME - Türkomp | Ulusal Gıda Kompozisyon Veri
/// Tabanı`, so both the site-section prefix and the site-name suffix have to
/// come off. Producing the bare `NAME` matches the convention already used
/// by the hand-written `recordName` entries in snapshot_index.json.
String _recordNameFromTitle(String rawTitle) => _plainText(rawTitle)
    .replaceFirst(RegExp(r'^(Veri Bankası|Türkomp)\s*[-|]\s*'), '')
    .replaceFirst(RegExp(r'\s*[-|]\s*Türkomp\s*\|.*$'), '')
    .trim();
