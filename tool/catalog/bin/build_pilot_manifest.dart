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
      jsonDecode(File('$_root/data/pilot_food_mapping.json').readAsStringSync())
          as Map<String, dynamic>;

  final rows = <Map<String, dynamic>>[];
  final gaps = <Map<String, dynamic>>[];

  for (final raw in mapping['foods'] as List<dynamic>) {
    final food = raw as Map<String, dynamic>;
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
    rows.addAll(_mappedRows(food, policy, snapshots, gaps));
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

  Directory('$_root/out').createSync(recursive: true);
  File('$_root/out/pilot_portion_manifest.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  File('$_root/out/pilot_portion_manifest.csv').writeAsStringSync(_csv(rows));
  _writePrompts(rows);

  stdout.writeln(
    'portions=${rows.length} '
    'blocked=${manifest['counts']} '
    'gaps=${gaps.length}',
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
  final portion = food['portion'] as Map<String, dynamic>;
  final nutrition = food['nutrition'] as Map<String, dynamic>;

  final nutrientRow = findExact<TuberPortionNutrients>(
    snapshots.tuberNutrients,
    portion['nutrientTableRow'] as String,
    (row) => row.foodName,
  );
  if (nutrientRow == null) {
    throw StateError(
      'TÜBER Ek 2.3.1 row "${portion['nutrientTableRow']}" not found or ambiguous',
    );
  }

  final measureRow = findExact<TuberHouseholdMeasure>(
    snapshots.tuberMeasures,
    portion['householdMeasureRow'] as String,
    (row) => row.foodName,
  );

  final multiplier = (portion['regularMultiplier'] as num).toDouble();
  final publishedPortion = nutrientRow.portionGrams;
  final regular = roundGrams(
    publishedPortion * multiplier,
    policy.roundToGrams(category),
  );

  final transformations = <String>[];
  final small = policy.smallIsPublished(category)
      ? publishedPortion
      : policy.derive(category, 'small', regular);
  final large = policy.derive(category, 'large', regular);

  if (multiplier != 1) {
    transformations.add(
      'regular = published TÜBER standard portion (${_g(publishedPortion)} g) x $multiplier. '
      'The multiplier is published by TÜBER Ek 2.1.5 footnote 4, which states that a '
      'home second-course serving of rice/bulgur/pasta equals 2 standard portions.',
    );
  }
  if (policy.smallIsPublished(category)) {
    transformations.add(
      'small = the published 1-standard-portion garnish weight (${_g(publishedPortion)} g), '
      'not a derived value.',
    );
  } else {
    transformations.add(
      'small = APP-DERIVED from regular using portion policy ${policy.version} '
      '(category $category), rounded to ${_g(policy.roundToGrams(category))} g steps. '
      'This is a product reference size, NOT a value published by TÜBER.',
    );
  }
  transformations.add(
    'large = APP-DERIVED from regular using portion policy ${policy.version} '
    '(category $category), rounded to ${_g(policy.roundToGrams(category))} g steps. '
    'This is a product reference size, NOT a value published by TÜBER.',
  );

  final per100g = _nutritionPer100g(
    nutrition,
    nutrientRow,
    snapshots,
    transformations,
  );

  final consistencyNote = buildConsistencyNote(
    foodEn: food['canonicalNameEn'] as String,
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
  final measureArtifact = snapshots.artifact(
    portion['householdMeasureArtifactId'] as String,
  );
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
        'household_measure': entry.key == 'regular'
            ? measureRow?.measure
            : null,
        'image_path': buildImagePath(
          foodSlug: slug,
          sizeClass: entry.key,
          grams: entry.value,
        ),
        'image_prompt': buildPortionPrompt(
          foodEn: food['canonicalNameEn'] as String,
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
        'source_record_id': portion['nutrientTableRow'],
        'source_url': pdfArtifact['sourceUrl'],
        'source_release': pdfArtifact['sourceRelease'],
        'source_page_or_table': [
          if (measureArtifact['sourcePageOrTable'] != null)
            measureArtifact['sourcePageOrTable'],
          if (snapshots.artifact(
                portion['nutrientTableArtifactId'] as String,
              )['sourcePageOrTable'] !=
              null)
            snapshots.artifact(
              portion['nutrientTableArtifactId'] as String,
            )['sourcePageOrTable'],
        ].join('; '),
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
  TuberPortionNutrients nutrientRow,
  _Snapshots snapshots,
  List<String> transformations,
) {
  if (nutrition['basis'] == 'per_100g_published') {
    final composition = snapshots.turkomp[nutrition['artifactId']]!;
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

void _writePrompts(List<Map<String, dynamic>> rows) {
  final dir = Directory('$_root/out/prompts');
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

