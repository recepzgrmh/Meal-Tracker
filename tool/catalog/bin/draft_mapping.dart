// Drafts the Tier A food mapping from the committed selection.
//
//   dart run tool/catalog/bin/draft_mapping.dart \
//       --out tool/catalog/data/catalog_tier_a_mapping.draft.json
//
// This produces a DRAFT, never a shippable mapping. Every entry lands with
// `"status": "draft"`, and build_pilot_manifest.dart refuses to build a mapping
// that still contains one, so a half-curated tier cannot reach the database.
//
// The mapping contract is preserved: this script writes no gram value and no
// nutrient value. It only proposes WHICH published row a food should use, and
// records under `autoAssigned`/`autoRules` exactly which fields a machine chose
// so a reviewer can see what still needs a human.
import 'dart:convert';
import 'dart:io';

import '../src/portion_policy.dart';
import '../src/tuber_match.dart';

const _root = 'tool/catalog';
const _selectionPath = '$_root/data/catalog_selection.json';
const _policyPath = '$_root/data/portion_policy.json';
const _defaultOut = '$_root/data/catalog_tier_a_mapping.draft.json';
const _batchId = 'catalog-tier-a-2026-08';

void main(List<String> args) {
  final outPath = _stringArg(args, '--out') ?? _defaultOut;

  final selection =
      jsonDecode(File(_selectionPath).readAsStringSync())
          as Map<String, dynamic>;
  final policy = PortionPolicy.parse(File(_policyPath).readAsStringSync());
  final records = (selection['foods'] as List).cast<Map<String, dynamic>>();

  final foods = <Map<String, dynamic>>[];
  final categoryCounts = <String, int>{};

  for (final record in records) {
    final name = record['listName'] as String;
    final code = record['sourceRecordId'] as String;
    final anchor = record['portionAnchor'] as Map<String, dynamic>?;

    final category = _categoryFor(name, code);
    categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;

    final autoAssigned = <String>[
      'foodSlug',
      'canonicalNameTr',
      'portionCategory',
      'container',
      'aliases.tr-TR',
    ];
    final autoRules = <String, String>{
      'foodSlug': 'turkishSlug(listName)',
      'canonicalNameTr': 'TürKomp record name, verbatim (naming contract §2)',
      'portionCategory': 'group ${code.substring(0, 5)} + name keywords',
      'container': 'portion-policy category default',
      'aliases.tr-TR': 'head noun @100, full record name @95',
    };

    Map<String, dynamic>? portion;
    final reviewerNotes = <String>[];

    if (anchor == null) {
      reviewerNotes.add(
        'No published TÜBER portion row was found. The food still ships: its '
        'composition is published, and the app asks the user for the amount. '
        'Set a portion here only if you can cite a published row.',
      );
    } else {
      final stateMatches = anchor['stateMatches'] == true;
      final isFoodRow = anchor['mode'] == 'tuberFoodRow';
      portion = <String, dynamic>{
        'mode': anchor['mode'],
        // Key names match what build_pilot_manifest.dart reads: a food-row
        // anchor resolves against Ek 2.3.1, the other two against Ek 2.1.
        if (isFoodRow) ...<String, dynamic>{
          'nutrientTableArtifactId': 'tuber-ek-2-3-1',
          'nutrientTableRow': anchor['rowName'],
        } else ...<String, dynamic>{
          'householdMeasureArtifactId': 'tuber-ek-2-1',
          'householdMeasureRow': anchor['rowName'],
        },
        if (anchor['mode'] == 'tuberGroupMemberGrams')
          'memberName': baseFoodName(name),
        'regularMultiplier': 1,
      };
      autoAssigned.add('portion.mode');
      autoRules['portion.mode'] =
          'strongest published anchor found by findTuberAnchor';

      if (!stateMatches) {
        portion['status'] = 'needs_state_decision';
        reviewerNotes.add(
          'STATE MISMATCH — ${anchor['stateNote']} A portion is only '
          'transferable within one preparation state. Either confirm the two '
          'describe the same food (TÜBER "Ceviz" plausibly means the dried '
          'kernel), or clear `portion` so the app asks the user instead.',
        );
      }
    }

    foods.add(<String, dynamic>{
      'pilotName': name,
      'foodSlug': record['foodSlug'],
      'status': 'draft',
      'canonicalNameTr': record['recordName'],
      'canonicalNameEn': null,
      'portionCategory': category,
      'container': policy.container(category) ?? 'plate',
      'nutrition': <String, dynamic>{
        'artifactId': 'turkomp-$code',
        'basis': 'per_100g_published',
        'sourceRecordId': code,
      },
      'portion': portion,
      'sourceConflicts': <String>[],
      'reviewerNotes': reviewerNotes.join(' '),
      'aliases': <String, dynamic>{
        'tr-TR': _aliases(name),
        'en-US': <Map<String, dynamic>>[],
      },
      'autoAssigned': autoAssigned,
      'autoRules': autoRules,
      'curatedBy': null,
      'curatedAt': null,
    });
  }

  final payload = <String, dynamic>{
    'schemaVersion': 1,
    'batchId': _batchId,
    'locale': 'tr-TR',
    'status': 'draft',
    'curatedBy': null,
    'curatedAt': null,
    'note':
        'DRAFT — generated by tool/catalog/bin/draft_mapping.dart from '
        '$_selectionPath. Human-curated mapping ONLY: no nutrition or gram '
        'value is written here; every number is pulled from the hashed '
        'snapshots at build time. Every food is "status": "draft" until a '
        'reviewer sets it to "mapped" and fills curatedBy/curatedAt. The '
        'manifest builder refuses to build while any draft remains.',
    'selectionRulesVersion': selection['rulesVersion'],
    'portionPolicyVersion': policy.version,
    'sourcePriority': const <String>[
      '100 g composition: TürKomp (T.C. Tarım ve Orman Bakanlığı)',
      'standard portion + household measure: TÜBER 2022 (T.C. Sağlık Bakanlığı)',
      'USDA FoodData Central: generic foods only, never as an analogue for a Turkish dish',
    ],
    'counts': <String, dynamic>{
      'foods': foods.length,
      'withPortionAnchor': foods.where((f) => f['portion'] != null).length,
      'needingStateDecision': foods
          .where(
            (f) =>
                (f['portion'] as Map<String, dynamic>?)?['status'] ==
                'needs_state_decision',
          )
          .length,
      'withoutPortion': foods.where((f) => f['portion'] == null).length,
      'byCategory': Map.fromEntries(
        categoryCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      ),
    },
    'foods': foods,
  };

  File(outPath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
  );

  final counts = payload['counts'] as Map<String, dynamic>;
  stdout.writeln(
    'foods=${counts['foods']} anchored=${counts['withPortionAnchor']} '
    'state-decision=${counts['needingStateDecision']} '
    'no-portion=${counts['withoutPortion']}',
  );
  stdout.writeln('categories: ${counts['byCategory']}');
  stdout.writeln('-> $outPath');
}

/// Maps a TürKomp record onto a portion-policy category.
///
/// Group prefix first (it is authoritative), then keywords within the group,
/// because TürKomp puts cheese and yogurt in the same 01.02 subgroup and nuts
/// and pulses in the same 07.
String _categoryFor(String name, String code) {
  final n = normalizeFoodName(name);
  final state = preparationState(name);
  final group = code.substring(0, 2);
  final sub = code.substring(0, 5);

  bool has(String pattern) => RegExp(pattern).hasMatch(n);

  return switch (group) {
    // yogurt is tested first: "Yoğurt, kaymaklı" contains "kaymak" and would
    // otherwise be filed as a cheese.
    '01' =>
      has('yogurt')
          ? 'dairy_yogurt'
          : has('peynir|kaymak')
          ? 'dairy_cheese'
          : 'beverage_dairy',
    '02' => 'egg_unit',
    '03' => 'meat_cooked',
    '04' => 'fish_cooked',
    '05' => 'fat_oil',
    '06' =>
      sub == '06.02' || has('ekmek|simit|yufka|bazlama|pide|lavas|galeta')
          ? 'bread'
          : 'grain_cooked',
    '07' =>
      has('findik|badem|ceviz|fistik|tohum|cekirdek|susam|yer fistigi')
          ? 'nuts_seeds'
          : 'legume_cooked',
    '08' =>
      state == PreparationState.cooked || state == PreparationState.canned
          ? 'vegetable_cooked'
          : 'vegetable_raw',
    '09' =>
      state == PreparationState.dried
          ? 'dried_fruit'
          : has('suyu')
          ? 'beverage_dairy'
          : 'fruit_whole',
    // 12 (traditional/prepared) and 13 (special dietary) mix everything, so
    // the shape has to come from the name. TürKomp files dried figs and
    // sun-dried apricots here rather than under fruit, which is why the
    // dried-fruit test has to run before the generic fallback.
    _ =>
      has('yogurt|kefir|ayran')
          ? 'dairy_yogurt'
          : has('peynir|kaymak')
          ? 'dairy_cheese'
          : state == PreparationState.dried &&
                has('incir|kayisi|uzum|erik|hurma|dut|elma|armut')
          ? 'dried_fruit'
          : has('findik|badem|ceviz|fistik|cekirdek|susam')
          ? 'nuts_seeds'
          : has(
              'ekmek|simit|borek|makarna|musli|gevrek|galeta|bazlama|lavas|pide|yufka',
            )
          ? 'bread'
          : has('suyu|serbet|boza|salgam')
          ? 'beverage_dairy'
          : 'vegetable_cooked',
  };
}

/// Derives search aliases from the record name.
///
/// Colloquial dish aliases are deliberately NOT invented: the naming contract
/// says a record is named after its source row, and attaching "pilav" to raw
/// rice would make search confidently wrong.
List<Map<String, dynamic>> _aliases(String name) {
  final head = baseFoodName(name);
  final full = normalizeFoodName(name);
  final aliases = <Map<String, dynamic>>[
    {'alias': head, 'priority': 100},
  ];
  if (full != head) aliases.add({'alias': full, 'priority': 95});
  return aliases;
}

String? _stringArg(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i == -1 || i + 1 >= args.length) return null;
  return args[i + 1];
}
