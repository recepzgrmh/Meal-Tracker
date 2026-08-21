// Builds the pilot portion-reference manifest and the image-generation prompt
// files from hashed source snapshots.
//
//   dart run tool/catalog/bin/build_pilot_manifest.dart
//
// Every number in the output is read out of a snapshot whose sha256 is checked
// first. Nothing in this script invents a gram weight or a nutrient value: a
// food that cannot be resolved from a published row is emitted as `blocked`.
import 'dart:convert';
import 'dart:io';

import '../src/catalog_error.dart';
import '../src/hashing.dart';
import '../src/image_prompt.dart';
import '../src/portion_policy.dart';
import '../src/tuber_parser.dart';
import '../src/turkomp_parser.dart';

const _root = 'tool/catalog';
const _generationDate = null; // Set by the operator when images are rendered.

void main(List<String> args) {
  final snapshots = _Snapshots.load();
  final policy = PortionPolicy.parse(
    File('$_root/data/portion_policy.json').readAsStringSync(),
  );
  final mapping =
      jsonDecode(
            File(
              _stringArg(args, '--mapping') ??
                  '$_root/data/pilot_food_mapping.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  final rows = <Map<String, dynamic>>[];
  final gaps = <Map<String, dynamic>>[];

  final foods = (mapping['foods'] as List<dynamic>)
      .cast<Map<String, dynamic>>();

  // A mapping is not shippable while any entry is still a machine draft.
  final drafts = foods
      .where((food) => food['status'] == 'draft')
      .map((food) => food['foodSlug'] as String)
      .toList();
  if (drafts.isNotEmpty) {
    stderr.writeln(
      '${drafts.length} food(s) are still "status": "draft" and have not been '
      'reviewed by a human. Set status to "mapped" and fill '
      'curatedBy/curatedAt, or "blocked" with a reason.\n'
      '  ${drafts.take(10).join(', ')}${drafts.length > 10 ? ', ...' : ''}',
    );
    exit(1);
  }

  // A duplicate slug would silently overwrite a food: foods.source_food_id IS
  // the slug, and the seed upserts on (source, source_food_id).
  final seenSlugs = <String, String>{};
  for (final food in foods) {
    final slug = food['foodSlug'] as String;
    final previous = seenSlugs[slug];
    if (previous != null) {
      stderr.writeln(
        'Duplicate foodSlug "$slug" used by both "$previous" and '
        '"${food['pilotName']}". One would silently overwrite the other.',
      );
      exit(1);
    }
    seenSlugs[slug] = food['pilotName'] as String;
  }

  var failures = 0;
  for (final food in foods) {
    if (food['status'] == 'blocked') {
      rows.addAll(_blockedRows(food));
      gaps.add({
        'foodSlug': food['foodSlug'],
        'pilotName': food['pilotName'],
        'reason': food['blockedReason'],
        'searchedSources': food['searchedSources'],
        'resolutionPath': food['resolutionPath'],
      });
      continue;
    }
    try {
      rows.addAll(_mappedRows(food, policy, snapshots, gaps));
    } on Object catch (error) {
      // Isolate the failure to this food. Producing no output for 200 foods
      // because one TÜBER row is ambiguous is worse than producing 199 and
      // naming the one that failed.
      failures++;
      final reason = error is CatalogBuildException
          ? error.message
          : 'Build failed for this food: $error';
      final searched = error is CatalogBuildException
          ? error.searchedSources
          : const <String>['TÜBER 2022 Ek 2.1', 'TÜBER 2022 Ek 2.3.1'];
      final resolution = error is CatalogBuildException
          ? error.resolutionPath
          : 'Fix the mapping entry, or mark the food blocked with a reason.';
      rows.addAll(
        _blockedRows(<String, dynamic>{...food, 'blockedReason': reason}),
      );
      gaps.add({
        'foodSlug': food['foodSlug'],
        'pilotName': food['pilotName'],
        'reason': reason,
        'searchedSources': searched,
        'resolutionPath': resolution,
      });
      stderr.writeln('BLOCKED ${food['foodSlug']}: $reason');
    }
  }
  if (failures > 0) {
    stderr.writeln('$failures food(s) blocked by a build failure.');
  }

  final manifest = {
    'schemaVersion': 1,
    'batchId': mapping['batchId'],
    'locale': mapping['locale'],
    'productionStandard': productionStandardVersion,
    'portionPolicyVersion': policy.version,
    'generatedFrom': 'tool/catalog/bin/build_pilot_manifest.dart',
    'sourceSnapshotIndex': '$_root/snapshots/snapshot_index.json',
    'sourcePriority': mapping['sourcePriority'],
    'counts': {
      'foods': (mapping['foods'] as List<dynamic>).length,
      'portions': rows.length,
      // Reported as three separate numbers on purpose. A published portion and
      // a derived energy-equivalent reference are not the same quality of
      // claim, so they are never summed into a single coverage figure.
      'publishedPortionFoods': _countFoods(
        rows,
        (r) =>
            r['portion_basis'] != null &&
            (r['portion_basis'] as String).startsWith('published_'),
      ),
      'derivedEnergyEquivalentFoods': _countFoods(
        rows,
        (r) => r['portion_basis'] == 'derived_energy_equivalent',
      ),
      'blockedFoods': _countFoods(
        rows,
        (r) => r['verification_status'] == 'blocked',
      ),
      'blocked': rows
          .where((r) => r['verification_status'] == 'blocked')
          .length,
      'needsReview': rows
          .where((r) => r['verification_status'] == 'needs_review')
          .length,
      'verified': rows
          .where((r) => r['verification_status'] == 'verified')
          .length,
    },
    'openGaps': gaps,
    'portions': rows,
  };

  final outBase =
      _stringArg(args, '--out') ?? '$_root/out/pilot_portion_manifest';
  Directory(File(outBase).parent.path).createSync(recursive: true);
  File('$outBase.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  File('$outBase.csv').writeAsStringSync(_csv(rows));
  // The pilot keeps its committed location; any other batch gets a directory
  // beside its own manifest, so one build cannot delete another's prompts.
  _writePrompts(
    rows,
    _stringArg(args, '--out') == null
        ? '$_root/out/prompts'
        : '${outBase}_prompts',
  );

  final counts = manifest['counts'] as Map<String, dynamic>;
  final foodCount = counts['foods'] as int;
  String pct(Object? n) =>
      '${((n as int) / foodCount * 100).toStringAsFixed(1)}%';
  stdout
    ..writeln('foods=$foodCount portions=${rows.length} gaps=${gaps.length}')
    ..writeln(
      '  published portion          '
      '${counts['publishedPortionFoods']}  ${pct(counts['publishedPortionFoods'])}',
    )
    ..writeln(
      '  derived energy equivalent  '
      '${counts['derivedEnergyEquivalentFoods']}  '
      '${pct(counts['derivedEnergyEquivalentFoods'])}',
    )
    ..writeln(
      '  blocked                    '
      '${counts['blockedFoods']}  ${pct(counts['blockedFoods'])}',
    );
  if (args.contains('--check')) {
    final expected = (mapping['foods'] as List<dynamic>).length * 3;
    if (rows.length != expected) {
      stderr.writeln('Expected $expected portion rows, got ${rows.length}');
      exit(1);
    }
  }
}

List<Map<String, dynamic>> _mappedRows(
  Map<String, dynamic> food,
  PortionPolicy policy,
  _Snapshots snapshots,
  List<Map<String, dynamic>> gaps,
) {
  final slug = food['foodSlug'] as String;
  final category = food['portionCategory'] as String;
  final container = food['container'] as String;
  final portion = food['portion'] as Map<String, dynamic>?;
  if (portion == null) {
    // Curated, but no published TÜBER row describes this food in the state
    // TürKomp records it. The food is NOT excluded from the catalog: its
    // composition is published and verified, and only the portion is absent.
    // The app asks the user for the amount rather than showing a weight no
    // source published.
    throw const CatalogBuildException(
      'No published TÜBER portion row applies to this food in its recorded '
      'preparation state. Composition is unaffected and still published; the '
      'app asks the user for the amount.',
      searchedSources: <String>[
        'TÜBER 2022 Ek 2.1 (standart porsiyon ölçüleri)',
        'TÜBER 2022 Ek 2.3.1 (standart porsiyon besin ögeleri)',
      ],
      resolutionPath:
          'Cite a published TÜBER row for this food in this preparation '
          'state, or leave the portion absent.',
    );
  }
  final nutrition = food['nutrition'] as Map<String, dynamic>;
  // Reference-image prompts are written in English. A generated mapping leaves
  // canonicalNameEn null for human translation, so fall back to the Turkish
  // source name rather than failing the food over a prompt string.
  final foodEn =
      food['canonicalNameEn'] as String? ?? food['canonicalNameTr'] as String;

  final mode = portion['mode'] as String? ?? 'tuberFoodRow';

  // Ek 2.3.1 is only consulted when the mapping points at one of its rows.
  // The Ek 2.1 modes take their weight from the measure text instead, and
  // must therefore source composition from TürKomp rather than falling back
  // to a portion row that does not exist for them.
  TuberPortionNutrients? nutrientRow;
  if (mode == 'tuberFoodRow') {
    final rowName = portion['nutrientTableRow'] as String?;
    if (rowName == null) {
      throw const CatalogBuildException(
        'portion.mode is tuberFoodRow but no nutrientTableRow is named',
      );
    }
    nutrientRow = findExact<TuberPortionNutrients>(
      snapshots.tuberNutrients,
      rowName,
      (row) => row.foodName,
    );
    if (nutrientRow == null) {
      throw CatalogBuildException(
        'TÜBER Ek 2.3.1 row "$rowName" not found or ambiguous',
        searchedSources: const <String>['TÜBER 2022 Ek 2.3.1'],
      );
    }
  }

  final measureRow = portion['householdMeasureRow'] == null
      ? null
      : findExact<TuberHouseholdMeasure>(
          snapshots.tuberMeasures,
          portion['householdMeasureRow'] as String,
          (row) => row.foodName,
        );

  final multiplier = (portion['regularMultiplier'] as num).toDouble();

  final double publishedPortion;
  if (nutrientRow != null) {
    publishedPortion = nutrientRow.portionGrams;
  } else {
    if (measureRow?.statedGrams == null) {
      throw CatalogBuildException(
        'portion.mode is $mode but TÜBER Ek 2.1 row '
        '"${portion['householdMeasureRow']}" states no gram weight',
        searchedSources: const <String>['TÜBER 2022 Ek 2.1'],
      );
    }
    publishedPortion = measureRow!.statedGrams!;
  }

  final regular = roundGrams(
    publishedPortion * multiplier,
    policy.roundToGrams(category),
  );

  // An absolute sanity bound, where the category declares one. Catches a
  // weight that is arithmetically valid but obviously not a serving.
  final band = policy.plausibleGramsBand(category);
  if (band != null && (regular < band.min || regular > band.max)) {
    throw CatalogBuildException(
      'regular ${_g(regular)} g is outside the plausible '
      '${_g(band.min)}-${_g(band.max)} g band for category $category',
    );
  }

  final transformations = <String>[];

  // Discrete foods derive as unit multiples: 0.65 of an egg is not a portion.
  double sizeFor(String sizeClass) =>
      policy.usesUnitMultiple(category, sizeClass)
      ? policy.deriveFromUnit(category, sizeClass, publishedPortion)
      : policy.derive(category, sizeClass, regular);

  final small = policy.smallIsPublished(category)
      ? publishedPortion
      : sizeFor('small');
  final large = sizeFor('large');

  transformations.add(switch (mode) {
    'tuberFoodRow' =>
      'regular = the published TÜBER Ek 2.3.1 standard portion for '
          '"${portion['nutrientTableRow']}" (${_g(publishedPortion)} g).',
    'tuberMeasureGrams' =>
      'regular = the gram weight TÜBER Ek 2.1 prints for '
          '"${portion['householdMeasureRow']}" (${_g(publishedPortion)} g).',
    'tuberGroupMemberGrams' =>
      'regular = the ${_g(publishedPortion)} g TÜBER Ek 2.1 prints for the '
          'grouped row "${portion['householdMeasureRow']}". This food is one '
          'named member of that row and is not measured separately.',
    _ => 'regular = published TÜBER weight ${_g(publishedPortion)} g.',
  });

  if (multiplier != 1) {
    final rationale = portion['multiplierRationale'] as String?;
    if (rationale == null) {
      throw const CatalogBuildException(
        'regularMultiplier != 1 requires a published multiplierRationale; '
        'a multiplier with no cited source is an invented portion',
      );
    }
    transformations.add(
      'regular = published TÜBER standard portion (${_g(publishedPortion)} g) '
      'x $multiplier. $rationale',
    );
  }
  if (policy.smallIsPublished(category)) {
    transformations.add(
      'small = the published 1-standard-portion garnish weight (${_g(publishedPortion)} g), '
      'not a derived value.',
    );
  } else {
    transformations.add(_derivationNote(policy, category, 'small'));
  }
  transformations.add(_derivationNote(policy, category, 'large'));

  final per100g = _nutritionPer100g(
    nutrition,
    nutrientRow,
    snapshots,
    transformations,
  );

  final consistencyNote = buildConsistencyNote(
    foodEn:
        food['canonicalNameEn'] as String? ?? food['canonicalNameTr'] as String,
    container: container,
    smallGrams: small,
    regularGrams: regular,
    largeGrams: large,
  );

  final sizes = <String, double>{
    'small': small,
    'regular': regular,
    'large': large,
  };
  // Which TÜBER artifact is the portion authority depends on the mode: a
  // food-row anchor cites Ek 2.3.1, the Ek 2.1 modes cite the measure table.
  final portionArtifactId =
      (portion['householdMeasureArtifactId'] ??
              portion['nutrientTableArtifactId'])
          as String?;
  if (portionArtifactId == null) {
    throw const CatalogBuildException(
      'portion names neither householdMeasureArtifactId nor '
      'nutrientTableArtifactId, so the weight has no citable source',
    );
  }
  final measureArtifact = snapshots.artifact(portionArtifactId);
  final nutritionArtifact = snapshots.artifact(
    nutrition['artifactId'] as String,
  );
  final pdfArtifact = snapshots.artifact('tuber-2022-pdf');

  if (measureRow == null) {
    gaps.add({
      'foodSlug': slug,
      'pilotName': food['pilotName'],
      'reason':
          'Household measure row "${portion['householdMeasureRow']}" could not be '
          'resolved unambiguously in the TÜBER Ek 2.1.x snapshot; household_measure is null.',
      'resolutionPath':
          'Re-check the Ek 2.1.x table layout for this food and update '
          'householdMeasureRow in tool/catalog/data/pilot_food_mapping.json.',
    });
  }

  return [
    for (final entry in sizes.entries)
      {
        'food_id': null,
        'canonical_name_tr': food['canonicalNameTr'],
        'canonical_name_en': food['canonicalNameEn'],
        'food_slug': slug,
        'portion_id': null,
        'size_class': entry.key,
        'grams': entry.value,
        // How this food's `regular` weight was sourced. Kept on every row so
        // the coverage split can be counted from the manifest alone, and so a
        // derived reference can never be mistaken for a published portion.
        'portion_basis': _portionBasis(portion),
        'household_measure': entry.key == 'regular'
            ? measureRow?.measure
            : null,
        'image_path': buildImagePath(
          foodSlug: slug,
          sizeClass: entry.key,
          grams: entry.value,
        ),
        'image_prompt': buildPortionPrompt(
          foodEn: foodEn,
          sizeClass: entry.key,
          grams: entry.value,
          container: container,
        ),
        'consistency_note': consistencyNote,
        'nutrition_source': nutritionArtifact['sourceName'],
        'nutrition_source_id':
            nutrition['sourceRecordId'] ?? nutrition['rowName'],
        'nutrition_per_100g': per100g,
        'image_source': null,
        'image_license': null,
        'attribution': null,
        'generation_model': null,
        'generation_seed': null,
        'generation_date': _generationDate,
        'visual_status': 'missing',
        'reviewer_notes': food['reviewerNotes'],
        // source_* identifies the PORTION authority (TÜBER). Composition
        // provenance is carried separately by nutrition_source*, because the
        // two can come from different publishers for the same food.
        'source_name': measureArtifact['sourceName'],
        'source_record_id':
            portion['nutrientTableRow'] ?? portion['householdMeasureRow'],
        'source_url': pdfArtifact['sourceUrl'],
        'source_release': pdfArtifact['sourceRelease'],
        // Cite every TÜBER table the weight depends on. A food-row anchor
        // cites only Ek 2.3.1; an Ek 2.1 anchor cites only the measure table.
        'source_page_or_table': <String>{
          for (final id in <String?>[
            portionArtifactId,
            portion['nutrientTableArtifactId'] as String?,
            portion['householdMeasureArtifactId'] as String?,
          ])
            if (id != null &&
                snapshots.artifact(id)['sourcePageOrTable'] != null)
              snapshots.artifact(id)['sourcePageOrTable'] as String,
        }.join('; '),
        'nutrition_source_url':
            nutritionArtifact['sourceUrl'] ?? pdfArtifact['sourceUrl'],
        'retrieved_at': pdfArtifact['retrievedAt'],
        'reviewed_by': null,
        'reviewed_at': null,
        'verification_status': 'needs_review',
        'transformation_notes': transformations,
        'source_conflicts': food['sourceConflicts'] ?? const <String>[],
      },
  ];
}

Map<String, dynamic> _nutritionPer100g(
  Map<String, dynamic> nutrition,
  TuberPortionNutrients? nutrientRow,
  _Snapshots snapshots,
  List<String> transformations,
) {
  if (nutrition['basis'] == 'per_100g_published') {
    final composition = snapshots.turkomp[nutrition['artifactId']];
    if (composition == null) {
      throw CatalogBuildException(
        'No TürKomp snapshot is indexed for artifact '
        '"${nutrition['artifactId']}"',
        searchedSources: const <String>[
          'tool/catalog/snapshots/snapshot_index.json',
        ],
        resolutionPath:
            'Promote the record with `fetch_sources.dart promote` before '
            'building.',
      );
    }
    // foods.calories/protein/carbs/fat are all NOT NULL. Where TürKomp omits a
    // value -- it publishes no fat for ground red pepper, for instance -- the
    // only honest options are to block the food or to invent a zero. Block it.
    final missing = <String>[
      if (composition.caloriesPer100g == null) 'calories',
      if (composition.proteinPer100g == null) 'protein',
      if (composition.carbsPer100g == null) 'carbs',
      if (composition.fatPer100g == null) 'fat',
    ];
    if (missing.isNotEmpty) {
      throw CatalogBuildException(
        'TürKomp record ${composition.sourceRecordId} publishes no '
        '${missing.join('/')} value, and the catalog stores all four macros '
        'as NOT NULL. Writing a zero would invent a number no source '
        'published.',
        searchedSources: <String>['TürKomp ${composition.sourceRecordId}'],
        resolutionPath:
            'Drop this food from the selection, or cite another published '
            'composition record that carries all four macros.',
      );
    }
    transformations.add(
      'Composition is the published TürKomp per-100 g record '
      '${composition.sourceRecordId}; no scaling applied.',
    );
    return {
      'calories': composition.caloriesPer100g,
      'protein': composition.proteinPer100g,
      'carbs': composition.carbsPer100g,
      'fat': composition.fatPer100g,
      'basis': 'per_100g_published',
    };
  }

  // The TÜBER fallback divides a published per-portion row by its weight.
  // The Ek 2.1 modes have no such row, so a food using one must carry
  // published TürKomp composition -- there is nothing to derive from.
  if (nutrientRow == null) {
    throw const CatalogBuildException(
      'Composition basis is derived_from_published_portion, but this food '
      'takes its portion from TÜBER Ek 2.1 and has no Ek 2.3.1 nutrient row '
      'to derive from. Use published TürKomp composition instead.',
    );
  }

  final factor = 100 / nutrientRow.portionGrams;
  transformations.add(
    'Composition is TÜBER Ek 2.3.1 per-portion values for '
    '"${nutrientRow.foodName}" (${_g(nutrientRow.portionGrams)} g) divided by '
    'the portion weight to reach per 100 g. TÜBER prints carbohydrate and fat '
    'as whole grams, so the per-100 g values inherit that precision limit.',
  );
  return {
    'calories': _round2(nutrientRow.energyKcal * factor),
    'protein': _round2(nutrientRow.proteinG * factor),
    'carbs': _round2(nutrientRow.carbsG * factor),
    'fat': _round2(nutrientRow.fatG * factor),
    'basis': 'derived_from_published_portion',
  };
}

List<Map<String, dynamic>> _blockedRows(Map<String, dynamic> food) {
  final slug = food['foodSlug'] as String;
  return [
    for (final size in const ['small', 'regular', 'large'])
      {
        'food_id': null,
        'canonical_name_tr': null,
        'canonical_name_en': null,
        'food_slug': slug,
        'portion_id': null,
        'size_class': size,
        'grams': null,
        'portion_basis': null,
        'household_measure': null,
        'image_path': null,
        'image_prompt': null,
        'consistency_note': null,
        'nutrition_source': null,
        'nutrition_source_id': null,
        'nutrition_per_100g': null,
        'image_source': null,
        'image_license': null,
        'attribution': null,
        'generation_model': null,
        'generation_seed': null,
        'generation_date': null,
        'visual_status': 'missing',
        'reviewer_notes': food['resolutionPath'],
        'source_name': null,
        'source_record_id': null,
        'source_url': null,
        'source_release': null,
        'source_page_or_table': null,
        'nutrition_source_url': null,
        'retrieved_at': null,
        'reviewed_by': null,
        'reviewed_at': null,
        'verification_status': 'blocked',
        'transformation_notes': <String>[],
        'blocked_reason': food['blockedReason'],
        'searched_sources': food['searchedSources'],
      },
  ];
}

void _writePrompts(List<Map<String, dynamic>> rows, String promptsDir) {
  final dir = Directory(promptsDir);
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);

  final byFood = <String, List<Map<String, dynamic>>>{};
  for (final row in rows) {
    if (row['image_prompt'] == null) continue;
    byFood.putIfAbsent(row['food_slug'] as String, () => []).add(row);
  }

  for (final entry in byFood.entries) {
    final foodDir = Directory('${dir.path}/${entry.key}')..createSync();
    File(
      '${foodDir.path}/_consistency_note.txt',
    ).writeAsStringSync('${entry.value.first['consistency_note']}\n');
    for (final row in entry.value) {
      final name = (row['image_path'] as String)
          .split('/')
          .last
          .replaceAll('.webp', '.txt');
      File('${foodDir.path}/$name').writeAsStringSync(
        '# ${row['canonical_name_tr']} — ${row['size_class']} — ${_g(row['grams'] as num)} g\n'
        '# target file: ${row['image_path']}\n'
        '# gram value source: ${row['source_name']} (${row['source_page_or_table']})\n'
        '# The image must not contain the gram value. The app renders it.\n\n'
        '${row['image_prompt']}\n',
      );
    }
  }
}

const _csvColumns = [
  'food_id',
  'canonical_name_tr',
  'canonical_name_en',
  'food_slug',
  'portion_id',
  'size_class',
  'grams',
  'household_measure',
  'image_path',
  'image_prompt',
  'consistency_note',
  'nutrition_source',
  'nutrition_source_id',
  'image_source',
  'image_license',
  'attribution',
  'generation_model',
  'generation_seed',
  'generation_date',
  'visual_status',
  'reviewer_notes',
  'source_name',
  'source_record_id',
  'source_url',
  'source_release',
  'source_page_or_table',
  'nutrition_source_url',
  'retrieved_at',
  'reviewed_by',
  'reviewed_at',
  'verification_status',
  'transformation_notes',
];

String _csv(List<Map<String, dynamic>> rows) {
  final buffer = StringBuffer(_csvColumns.join(','))..write('\n');
  for (final row in rows) {
    buffer
      ..write(_csvColumns.map((column) => _cell(row[column])).join(','))
      ..write('\n');
  }
  return buffer.toString();
}

String _cell(Object? value) {
  if (value == null) return '';
  final text = value is List ? value.join(' | ') : value.toString();
  return '"${text.replaceAll('"', '""')}"';
}

String _g(num grams) => grams == grams.roundToDouble()
    ? grams.round().toString()
    : grams.toString();

double _round2(double value) => (value * 100).roundToDouble() / 100;

class _Snapshots {
  _Snapshots(
    this._index,
    this.tuberNutrients,
    this.tuberMeasures,
    this.turkomp,
  );

  final List<Map<String, dynamic>> _index;
  final List<TuberPortionNutrients> tuberNutrients;
  final List<TuberHouseholdMeasure> tuberMeasures;
  final Map<String, TurkompComposition> turkomp;

  Map<String, dynamic> artifact(String id) =>
      _index.firstWhere((entry) => entry['id'] == id);

  static _Snapshots load() {
    final index =
        (jsonDecode(
                  File(
                    '$_root/snapshots/snapshot_index.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>)['artifacts']
            as List<dynamic>;
    final artifacts = index.cast<Map<String, dynamic>>();

    for (final artifact in artifacts) {
      final path = artifact['path'] as String?;
      if (path == null) continue;
      final actual = sha256OfFile(path);
      if (actual != artifact['sha256']) {
        throw StateError(
          'Snapshot $path has changed (sha256 $actual != ${artifact['sha256']}). '
          'Re-fetch the source and update snapshot_index.json before rebuilding.',
        );
      }
    }

    final turkomp = <String, TurkompComposition>{};
    for (final artifact in artifacts) {
      if (!(artifact['id'] as String).startsWith('turkomp-')) continue;
      final bytes = File(artifact['path'] as String).readAsBytesSync();
      final html = utf8.decode(gzip.decode(bytes), allowMalformed: true);
      turkomp[artifact['id'] as String] = parseTurkompFoodPage(
        html,
        sourceRecordId: artifact['sourceRecordId'] as String?,
      );
    }

    return _Snapshots(
      artifacts,
      parseTuberPortionNutrients(
        File(
          '$_root/snapshots/tuber/ek_2_3_1_portion_nutrients.txt',
        ).readAsStringSync(),
      ),
      parseTuberHouseholdMeasures(
        File(
          '$_root/snapshots/tuber/ek_2_1_portion_measures.txt',
        ).readAsStringSync(),
      ),
      turkomp,
    );
  }
}

/// Counts distinct foods whose rows satisfy [test].
int _countFoods(
  List<Map<String, dynamic>> rows,
  bool Function(Map<String, dynamic>) test,
) => rows.where(test).map((r) => r['food_slug'] as String).toSet().length;

String? _stringArg(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i == -1 || i + 1 >= args.length) return null;
  return args[i + 1];
}

/// Maps a mapping entry's portion mode onto the manifest's `portion_basis`.
///
/// The `published_` prefix is load-bearing: the coverage count treats exactly
/// those rows as published, so a new mode cannot quietly inflate the figure.
String _portionBasis(Map<String, dynamic> portion) =>
    switch (portion['mode'] as String? ?? 'tuberFoodRow') {
      'tuberFoodRow' => 'published_food_row',
      'tuberMeasureGrams' => 'published_measure_row',
      'tuberGroupMemberGrams' => 'published_group_member',
      'energyEquivalentReference' => 'derived_energy_equivalent',
      final unknown => throw CatalogBuildException(
        'Unknown portion mode "$unknown"',
      ),
    };

/// Describes how a non-published size was derived.
String _derivationNote(PortionPolicy policy, String category, String size) =>
    policy.usesUnitMultiple(category, size)
    ? '$size = APP-DERIVED as ${policy.unitMultiple(category, size)}x the '
          'published unit weight (portion policy ${policy.version}, category '
          '$category). Discrete foods are counted in units, not scaled by a '
          'factor. This is a product reference size, NOT published by TÜBER.'
    : '$size = APP-DERIVED from regular using portion policy '
          '${policy.version} (category $category), rounded to '
          '${_g(policy.roundToGrams(category))} g steps. This is a product '
          'reference size, NOT a value published by TÜBER.';
