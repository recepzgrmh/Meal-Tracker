// Chooses which TürKomp records enter the catalog, by rule rather than by hand.
//
//   dart run tool/catalog/bin/build_selection.dart [--tier-a 200]
//
// Reads data/catalog_selection_rules.json, data/turkomp_index.json, the two
// TÜBER snapshots and the fetched .cache metadata; writes
// data/catalog_selection.json. Pure over its inputs: re-running reproduces the
// file byte for byte, which is asserted in CI with `git diff --exit-code`.
//
// This script writes no gram and no nutrient value. It records which published
// row is a candidate anchor for a food and why the food was ranked where it is.
import 'dart:convert';
import 'dart:io';

import '../src/slug.dart';
import '../src/tuber_match.dart';
import '../src/tuber_parser.dart';

const _root = 'tool/catalog';
const _rulesPath = '$_root/data/catalog_selection_rules.json';
const _indexPath = '$_root/data/turkomp_index.json';
const _overridesPath = '$_root/data/catalog_selection_overrides.json';
const _outPath = '$_root/data/catalog_selection.json';
const _cacheDir = '$_root/.cache/turkomp';

final RegExp _industrial = RegExp(r'karisim|konsantre|hammadde|harci|\btoz\b');

void main(List<String> args) {
  final tierATarget = _intArg(args, '--tier-a') ?? 200;

  final rules =
      jsonDecode(File(_rulesPath).readAsStringSync()) as Map<String, dynamic>;
  final points = <String, int>{
    for (final s in (rules['signals'] as List).cast<Map<String, dynamic>>())
      s['id'] as String: s['points'] as int,
    for (final p in (rules['penalties'] as List).cast<Map<String, dynamic>>())
      p['id'] as String: p['points'] as int,
  };

  final index =
      jsonDecode(File(_indexPath).readAsStringSync()) as Map<String, dynamic>;
  final entries = (index['entries'] as List).cast<Map<String, dynamic>>();

  final nutrientRows = parseTuberPortionNutrients(
    File(
      '$_root/snapshots/tuber/ek_2_3_1_portion_nutrients.txt',
    ).readAsStringSync(),
  );
  final measureRows = parseTuberHouseholdMeasures(
    File(
      '$_root/snapshots/tuber/ek_2_1_portion_measures.txt',
    ).readAsStringSync(),
  );

  final scored = <Map<String, dynamic>>[];
  var uncached = 0;

  for (final entry in entries) {
    final href = entry['href'] as String;
    final name = entry['listName'] as String;

    if (hasDistinctSpecies(name)) continue;

    final meta = _cacheMeta(href);
    if (meta == null) {
      uncached++;
      continue;
    }

    final anchor = findTuberAnchor(
      name,
      nutrientRows: nutrientRows,
      measureRows: measureRows,
    );

    var score = 0;
    final reasons = <String>[];

    if (anchor != null) {
      final id = switch (anchor.mode) {
        TuberMatchMode.tuberFoodRow => 'tuber_food_row',
        TuberMatchMode.tuberMeasureGrams => 'tuber_measure_row',
        TuberMatchMode.tuberGroupMemberGrams => 'tuber_member_row',
      };
      score += points[id]!;
      reasons.add('$id (+${points[id]}): "${anchor.rowName}"');
      if (!anchor.stateMatches) {
        score += points['state_mismatch']!;
        reasons.add(
          'state_mismatch (${points['state_mismatch']}): ${anchor.stateNote}',
        );
      }
    }

    if (preparationState(name) == PreparationState.cooked ||
        preparationState(name) == PreparationState.roasted) {
      score += points['prepared_state']!;
      reasons.add('prepared_state (+${points['prepared_state']})');
    }
    if (name.split(',').length <= 2) {
      score += points['single_ingredient']!;
      reasons.add('single_ingredient (+${points['single_ingredient']})');
    }
    if (_industrial.hasMatch(normalizeFoodName(name))) {
      score += points['industrial']!;
      reasons.add('industrial (${points['industrial']})');
    }

    scored.add(<String, dynamic>{
      'href': href,
      'foodSlug': turkishSlug(name),
      'listName': name,
      'sourceRecordId': meta['sourceRecordId'],
      'recordName': meta['recordName'],
      'groupPrefix': (meta['sourceRecordId'] as String).split('.').first,
      'score': score,
      'reasons': reasons,
      'portionAnchor': anchor == null
          ? null
          : <String, dynamic>{
              'mode': anchor.mode.name,
              'rowName': anchor.rowName,
              'statedGrams': anchor.statedGrams,
              'stateMatches': anchor.stateMatches,
              'stateNote': anchor.stateMatches ? null : anchor.stateNote,
            },
    });
  }

  if (uncached > 0) {
    stderr.writeln(
      '$uncached indexed records are not in $_cacheDir and were skipped. '
      'Run `fetch_sources.dart fetch --resume` for a complete selection.',
    );
  }

  scored.sort((a, b) {
    final byScore = (b['score'] as int).compareTo(a['score'] as int);
    if (byScore != 0) return byScore;
    return (a['sourceRecordId'] as String).compareTo(
      b['sourceRecordId'] as String,
    );
  });

  final overrides = _applyOverrides(scored);
  final tierA = scored.take(tierATarget).toList();

  var published = 0;
  var mismatched = 0;
  var noAnchor = 0;
  for (final food in tierA) {
    final anchor = food['portionAnchor'] as Map<String, dynamic>?;
    if (anchor == null) {
      noAnchor++;
    } else if (anchor['stateMatches'] == true) {
      published++;
    } else {
      mismatched++;
    }
  }

  final payload = <String, dynamic>{
    'schemaVersion': 1,
    'rulesVersion': rules['rulesVersion'],
    'generatedFrom': <String>[_rulesPath, _indexPath, _overridesPath],
    'note':
        'Generated by tool/catalog/bin/build_selection.dart. Do not hand-edit; '
        'add entries to catalog_selection_overrides.json instead.',
    'scoredRecords': scored.length,
    'tierATarget': tierATarget,
    'counts': <String, dynamic>{
      'tierAFoods': tierA.length,
      'anchorStateMatches': published,
      'anchorStateMismatch': mismatched,
      'noAnchor': noAnchor,
    },
    'overridesApplied': overrides,
    'foods': tierA,
  };

  File(_outPath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
  );

  stdout.writeln(
    'scored=${scored.length} tierA=${tierA.length} '
    'anchor-ok=$published anchor-state-mismatch=$mismatched no-anchor=$noAnchor',
  );
  stdout.writeln('-> $_outPath');
}

Map<String, dynamic>? _cacheMeta(String href) {
  final file = File('$_cacheDir/$href.meta.json');
  if (!file.existsSync()) return null;
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

List<String> _applyOverrides(List<Map<String, dynamic>> scored) {
  final file = File(_overridesPath);
  if (!file.existsSync()) return const [];
  final overrides = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final applied = <String>[];

  for (final drop
      in (overrides['drop'] as List? ?? const [])
          .cast<Map<String, dynamic>>()) {
    final id = drop['sourceRecordId'] as String;
    scored.removeWhere((food) => food['sourceRecordId'] == id);
    applied.add('drop $id: ${drop['justification']}');
  }
  for (final add
      in (overrides['add'] as List? ?? const []).cast<Map<String, dynamic>>()) {
    final id = add['sourceRecordId'] as String;
    final match = scored.where((food) => food['sourceRecordId'] == id);
    if (match.isEmpty) {
      stderr.writeln('override add $id: not present in the scored set');
      continue;
    }
    final food = match.first
      ..['overridden'] = true
      ..['overrideJustification'] = add['justification'];
    scored
      ..remove(food)
      ..insert(0, food);
    applied.add('add $id: ${add['justification']}');
  }
  return applied;
}

int? _intArg(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i == -1 || i + 1 >= args.length) return null;
  return int.tryParse(args[i + 1]);
}
