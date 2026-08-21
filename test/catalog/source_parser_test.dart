@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/catalog/src/portion_policy.dart';
import '../../tool/catalog/src/tuber_parser.dart';
import '../../tool/catalog/src/turkomp_parser.dart';

/// Fixtures are the real `pdftotext -layout` / TürKomp layouts, trimmed. They
/// pin the two things that silently break a sourcing pipeline: a wrapped table
/// row losing half its name, and a footnote marker being read as a number.
const _tuberNutrientFixture = '''
                      Beyaz peynir, tam yağlı              60 165 12.1 0 0 13 32 240 0.2 1.8 90 178 0
                      Yoğurt, tam yağlı                   240 158 7.9 10 0 9 34 312 0.1 1.1 384 79 2
                      Tavuk göğüs eti, pişmiş              80 88 20.4 0 0 1 57 12 0.4 0.6 286 14 0
                      Beyaz pirinç, pişmiş                 90 84 1.8 18 0 0 0 2 0.2 0.1 17 0 0
''';

const _tuberMeasureFixture = '''
                 Yoğurt                             1 küçük kase veya 200 mL
                 Yoğurt (ev yapımı)                 1 kupa veya 1 küçük kase veya 240 mL
                 Beyaz peynir                       3 parmak veya 2 kibrit kutusu veya 60 g

     Nohut, fasulye, barbunya, iç bakla1 ,
                                                       ¾ kupa veya 2 küçük kepçe4 veya 8-10 yemek kaşığı veya 130 g
     börülce (haşlanmış)
     Bulgur, pişmiş3-6                                 ½ kupa veya 1 silme orta kepçe7 veya 4-5 yemek kaşığı veya 90g6
     Çorba çeşitleri10, tahıl, kuru baklagil, sebze
                                                       ¾ kupa veya 1.5 orta kepçe 7 veya 180 mL veya 1 küçük kase8-10
     vb.
''';

const _turkompFixture = '''
<html><head><title>Türkomp - Peynir, beyaz, tam yağlı</title></head><body>
<table>
<tr><th>Bileşen</th><th>Birim</th><th>Ort.</th><th>Min.</th><th>Maks.</th></tr>
<tr><td><a href="#">Enerji</a></td><td>kcal</td><td>309</td><td>309</td><td>309</td></tr>
<tr><td>Enerji</td><td>kJ</td><td>1292</td><td>1292</td><td>1292</td></tr>
<tr><td>Protein</td><td>g</td><td>16,01</td><td>16,01</td><td>16,01</td></tr>
<tr><td>Yağ, toplam</td><td>g</td><td>23,55</td><td>23,55</td><td>23,55</td></tr>
<tr><td>Karbonhidrat</td><td>g</td><td>8,21</td><td>8,21</td><td>8,21</td></tr>
</table></body></html>
''';

void main() {
  group('TÜBER Ek 2.3.1 nutrient table', () {
    final rows = parseTuberPortionNutrients(_tuberNutrientFixture);

    test('reads the published portion weight and macros verbatim', () {
      final chicken = findExact(
        rows,
        'Tavuk göğüs eti, pişmiş',
        (row) => row.foodName,
      )!;
      expect(chicken.portionGrams, 80);
      expect(chicken.energyKcal, 88);
      expect(chicken.proteinG, 20.4);
      expect(chicken.carbsG, 0);
      expect(chicken.fiberG, 0);
      expect(chicken.fatG, 1);
    });

    test('does not confuse the portion column with the energy column', () {
      final yogurt = findExact(
        rows,
        'Yoğurt, tam yağlı',
        (row) => row.foodName,
      )!;
      expect(yogurt.portionGrams, 240);
      expect(yogurt.energyKcal, 158);
    });

    test('returns null rather than a near match for an unknown food', () {
      expect(findExact(rows, 'Menemen', (row) => row.foodName), isNull);
      expect(findExact(rows, 'Beyaz pirinç', (row) => row.foodName), isNull);
    });
  });

  group('TÜBER Ek 2.1.x household measures', () {
    final rows = parseTuberHouseholdMeasures(_tuberMeasureFixture);
    String? measureOf(String name) =>
        findExact(rows, name, (row) => row.foodName)?.measure;

    test('keeps the full published measure text', () {
      expect(
        measureOf('Beyaz peynir'),
        '3 parmak veya 2 kibrit kutusu veya 60 g',
      );
    });

    test('rejoins a food name that wrapped below its measure', () {
      expect(
        measureOf('Nohut, fasulye, barbunya, iç bakla, börülce (haşlanmış)'),
        '¾ kupa veya 2 küçük kepçe4 veya 8-10 yemek kaşığı veya 130 g',
      );
    });

    test('strips footnote markers from the food name', () {
      expect(measureOf('Bulgur, pişmiş'), isNotNull);
      expect(
        measureOf('Çorba çeşitleri, tahıl, kuru baklagil, sebze vb.'),
        isNotNull,
      );
    });

    test('keeps the two yogurt rows distinct instead of collapsing them', () {
      expect(measureOf('Yoğurt'), '1 küçük kase veya 200 mL');
      expect(
        measureOf('Yoğurt (ev yapımı)'),
        '1 kupa veya 1 küçük kase veya 240 mL',
      );
    });

    test('reports grams only when the table prints grams', () {
      final soup = findExact(
        rows,
        'Çorba çeşitleri, tahıl, kuru baklagil, sebze vb.',
        (row) => row.foodName,
      )!;
      expect(
        soup.statedGrams,
        isNull,
        reason: 'a mL measure must not become a gram value',
      );
      expect(soup.statedMillilitres, 180);
      expect(
        findExact(rows, 'Beyaz peynir', (row) => row.foodName)!.statedGrams,
        60,
      );
    });
  });

  group('TürKomp detail page', () {
    test('reads the per-100 g average column and keeps kcal over kJ', () {
      final composition = parseTurkompFoodPage(
        _turkompFixture,
        sourceRecordId: '01.02.0004',
      );
      expect(composition.sourceRecordId, '01.02.0004');
      expect(composition.caloriesPer100g, 309);
      expect(composition.proteinPer100g, 16.01);
      expect(composition.carbsPer100g, 8.21);
      expect(composition.fatPer100g, 23.55);
    });

    test('refuses a page it cannot attribute to a food code', () {
      expect(
        () => parseTurkompFoodPage(_turkompFixture),
        throwsA(isA<FormatException>()),
      );
    });

    test('every committed snapshot parses and is attributable', () {
      // Runs over all artifacts but asserts only what must hold for every one:
      // it parses, and it carries a record id. Macro completeness is asserted
      // separately, because TürKomp genuinely omits some values.
      for (final raw in _turkompArtifacts()) {
        final composition = parseTurkompFoodPage(
          _gunzip(raw['path'] as String),
          sourceRecordId: raw['sourceRecordId'] as String?,
        );
        expect(
          composition.sourceRecordId,
          isNotEmpty,
          reason: raw['id'] as String,
        );
        expect(composition.componentsPer100g, isNotEmpty);
      }
    });

    test('a record missing a macro is named, not silently zero-filled', () {
      // foods.calories/protein/carbs/fat are NOT NULL, so the builder blocks
      // these rather than inventing a zero. This test exists so the set stays
      // visible: if it grows, someone chose to import an incomplete record.
      final incomplete = <String>[];
      for (final raw in _turkompArtifacts()) {
        final c = parseTurkompFoodPage(
          _gunzip(raw['path'] as String),
          sourceRecordId: raw['sourceRecordId'] as String?,
        );
        if (c.caloriesPer100g == null ||
            c.proteinPer100g == null ||
            c.carbsPer100g == null ||
            c.fatPer100g == null) {
          incomplete.add(raw['sourceRecordId'] as String);
        }
      }
      expect(
        incomplete..sort(),
        <String>['08.02.0038', '08.02.0042'],
        reason:
            'TürKomp publishes no fat value for ground red pepper or pepper '
            'flakes. Both are blocked by the manifest builder.',
      );
    });
  });

  group('portion policy', () {
    final policy = PortionPolicy.parse(
      File('tool/catalog/data/portion_policy.json').readAsStringSync(),
    );

    test('derives small and large inside the documented band', () {
      expect(policy.derive('dairy_cheese', 'small', 60), 40);
      expect(policy.derive('dairy_cheese', 'large', 60), 90);
      expect(policy.derive('legume_cooked', 'small', 130), 85);
    });

    test('treats the cooked-grain small portion as published, not derived', () {
      expect(policy.smallIsPublished('grain_cooked'), isTrue);
      expect(
        () => policy.derive('grain_cooked', 'small', 180),
        throwsStateError,
      );
    });

    test('rejects a factor edited outside the band without an exemption', () {
      final loosened = PortionPolicy.parse(
        jsonEncode({
          'policyVersion': 'test',
          'derivedFactorBands': {
            'small': {'min': 0.60, 'max': 0.70},
            'large': {'min': 1.40, 'max': 1.60},
          },
          'categories': {
            'x': {'largeFactor': 2.5, 'roundToGrams': 5},
          },
        }),
      );
      expect(() => loosened.derive('x', 'large', 100), throwsStateError);
    });

    test('derives discrete foods as unit multiples, not factors', () {
      // 0.65 of an egg or of a slice of bread is not a portion anyone eats.
      expect(policy.usesUnitMultiple('egg_unit', 'small'), isTrue);
      expect(policy.usesUnitMultiple('egg_unit', 'large'), isTrue);
      expect(policy.usesUnitMultiple('dairy_cheese', 'small'), isFalse);

      // TÜBER publishes 100 g = 2 medium eggs, so the unit is 50 g.
      expect(policy.deriveFromUnit('egg_unit', 'small', 50), 25);
      expect(policy.deriveFromUnit('egg_unit', 'large', 50), 75);
      expect(policy.deriveFromUnit('fruit_whole', 'large', 120), 240);
    });

    test('refuses to mix the two derivation models', () {
      expect(
        () => policy.derive('egg_unit', 'small', 100),
        throwsA(isA<StateError>()),
      );
      expect(
        () => policy.deriveFromUnit('dairy_cheese', 'small', 60),
        throwsA(isA<StateError>()),
      );
    });

    test('declares an absolute plausibility band for dense categories', () {
      // Guards weights that are arithmetically valid but not servings.
      final oil = policy.plausibleGramsBand('fat_oil')!;
      expect(oil.min, 5);
      expect(oil.max, 40);
      final nuts = policy.plausibleGramsBand('nuts_seeds')!;
      expect(nuts.max, lessThan(policy.plausibleGramsBand('bread')!.max));
    });

    test('rounds to kitchen steps rather than implying scale precision', () {
      expect(roundGrams(84.5, 5), 85);
      expect(roundGrams(152.5, 10), 150);
    });
  });
}

/// The TürKomp artifacts recorded in the committed snapshot index.
List<Map<String, dynamic>> _turkompArtifacts() =>
    ((jsonDecode(
                  File(
                    'tool/catalog/snapshots/snapshot_index.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>)['artifacts']
            as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((a) => (a['id'] as String).startsWith('turkomp-'))
        .toList();

String _gunzip(String path) => utf8.decode(
  gzip.decode(File(path).readAsBytesSync()),
  allowMalformed: true,
);
