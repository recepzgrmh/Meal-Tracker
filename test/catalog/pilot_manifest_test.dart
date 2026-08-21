@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The manifest is the contract between the sourcing pipeline, the image
/// production batch and the Supabase catalog. These tests exist to make an
/// unverifiable or fabricated value fail the build rather than reach a user.
void main() {
  final manifest =
      jsonDecode(
            File(
              'tool/catalog/out/pilot_portion_manifest.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final portions = (manifest['portions'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final resolved = portions
      .where((row) => row['verification_status'] != 'blocked')
      .toList();
  final bySlug = <String, List<Map<String, dynamic>>>{};
  for (final row in portions) {
    bySlug.putIfAbsent(row['food_slug'] as String, () => []).add(row);
  }

  test('covers the pilot batch with three portions per food', () {
    expect(bySlug, hasLength(10));
    for (final entry in bySlug.entries) {
      expect(
        entry.value.map((row) => row['size_class']).toList(),
        ['small', 'regular', 'large'],
        reason:
            '${entry.key} must publish exactly small/regular/large, in that order',
      );
    }
    expect(portions, hasLength(30));
  });

  test('grams increase strictly from small to large', () {
    for (final entry in bySlug.entries) {
      final grams = entry.value.map((row) => row['grams'] as num?).toList();
      if (grams.any((value) => value == null)) {
        expect(
          grams.every((value) => value == null),
          isTrue,
          reason:
              '${entry.key} must be fully resolved or fully blocked, never half',
        );
        continue;
      }
      expect(
        grams[0]! < grams[1]!,
        isTrue,
        reason: '${entry.key}: small must be under regular',
      );
      expect(
        grams[1]! < grams[2]!,
        isTrue,
        reason: '${entry.key}: regular must be under large',
      );
      expect(grams.every((value) => value! > 0), isTrue);
    }
  });

  test('every unresolved row is explicitly blocked with a reason', () {
    for (final row in portions) {
      if (row['grams'] != null) continue;
      expect(
        row['verification_status'],
        'blocked',
        reason: 'slug=${row['food_slug']}',
      );
      expect(row['blocked_reason'], isA<String>());
      expect((row['blocked_reason'] as String).length, greaterThan(40));
      expect(row['searched_sources'], isNotEmpty);
      expect(row['image_prompt'], isNull);
      expect(row['visual_status'], 'missing');
    }
  });

  test('no row is marked verified without a named human reviewer', () {
    for (final row in portions) {
      if (row['verification_status'] != 'verified') continue;
      expect(
        row['reviewed_by'],
        isA<String>(),
        reason: 'slug=${row['food_slug']}',
      );
      expect(row['reviewed_at'], isA<String>());
    }
  });

  test('no image is marked approved or published without a reviewer', () {
    const reviewedStates = {'reviewed', 'published'};
    for (final row in portions) {
      if (!reviewedStates.contains(row['visual_status'])) continue;
      expect(
        row['reviewed_by'],
        isA<String>(),
        reason: 'slug=${row['food_slug']}',
      );
      expect(row['image_source'], isNotNull);
      expect(row['image_license'], isNotNull);
    }
  });

  test('resolved rows carry full source provenance', () {
    const required = [
      'source_name',
      'source_record_id',
      'source_url',
      'source_release',
      'source_page_or_table',
      'retrieved_at',
      'nutrition_source',
      'nutrition_source_id',
      'nutrition_source_url',
    ];
    for (final row in resolved) {
      for (final field in required) {
        expect(
          row[field],
          isNotNull,
          reason: '${row['food_slug']}/${row['size_class']} is missing $field',
        );
        expect((row[field] as String).trim(), isNotEmpty);
      }
      expect(row['verification_status'], anyOf('needs_review', 'verified'));
      // The portion authority and the composition authority are separate
      // publishers; conflating them is how an unsourced value gets a source.
      expect(row['source_name'], contains('TÜBER'));
      expect(
        row['nutrition_source'],
        anyOf(contains('TürKomp'), contains('TÜBER')),
      );
    }
  });

  test('derived portion weights say so in transformation_notes', () {
    for (final row in resolved) {
      final notes = (row['transformation_notes'] as List<dynamic>)
          .cast<String>();
      expect(
        notes,
        isNotEmpty,
        reason: '${row['food_slug']}/${row['size_class']}',
      );
      if (row['size_class'] == 'large') {
        expect(
          notes.any((note) => note.contains('large = APP-DERIVED')),
          isTrue,
          reason:
              '${row['food_slug']}: a derived large portion must not read as published',
        );
      }
    }
  });

  test('image paths are deterministic, slug-safe and unique', () {
    final seen = <String>{};
    final slugPattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
    for (final row in resolved) {
      final slug = row['food_slug'] as String;
      final grams = row['grams'] as num;
      expect(slugPattern.hasMatch(slug), isTrue, reason: 'slug=$slug');
      expect(
        row['image_path'],
        'food-portions/$slug/$slug--${row['size_class']}--${grams.round()}g.webp',
      );
      expect(
        seen.add(row['image_path'] as String),
        isTrue,
        reason: 'duplicate ${row['image_path']}',
      );
    }
    expect(bySlug.keys.toSet(), hasLength(bySlug.length));
  });

  test('prompts never ask the model for a weight, a calorie or a label', () {
    final banned = RegExp(
      r'\b(?:calorie|calories|kcal|macro|estimate|weigh|nutrition facts|label|gram text)\b',
      caseSensitive: false,
    );
    for (final row in resolved) {
      final prompt = row['image_prompt'] as String;
      expect(
        banned.hasMatch(prompt),
        isFalse,
        reason: '${row['image_path']}: $prompt',
      );
      expect(prompt, contains('no text'));
      expect(prompt, contains('no watermark'));
      expect(prompt, contains('no logo'));
      expect(prompt, contains('Fixed 85-degree overhead camera'));
      expect(prompt, contains('Only the amount of food should differ'));
      expect(prompt, contains('${(row['grams'] as num).round()} grams'));
    }
  });

  test(
    'the three variants of a food share one consistency note and one vessel',
    () {
      for (final entry in bySlug.entries) {
        final rows = entry.value
            .where((row) => row['image_prompt'] != null)
            .toList();
        if (rows.isEmpty) continue;
        expect(
          rows.map((row) => row['consistency_note']).toSet(),
          hasLength(1),
        );
        final vessels = rows
            .map(
              (row) =>
                  (row['image_prompt'] as String).contains('matte white bowl')
                  ? 'bowl'
                  : 'plate',
            )
            .toSet();
        expect(
          vessels,
          hasLength(1),
          reason: '${entry.key} must not change vessel between variants',
        );
      }
    },
  );

  test('a prompt file exists on disk for every resolved portion', () {
    for (final row in resolved) {
      final path = row['image_path'] as String;
      final promptPath =
          'tool/catalog/out/prompts/${row['food_slug']}/${path.split('/').last.replaceAll('.webp', '.txt')}';
      expect(File(promptPath).existsSync(), isTrue, reason: promptPath);
    }
    for (final slug in resolved.map((row) => row['food_slug']).toSet()) {
      expect(
        File(
          'tool/catalog/out/prompts/$slug/_consistency_note.txt',
        ).existsSync(),
        isTrue,
      );
    }
  });

  test('open gaps are reported instead of silently filled', () {
    final gaps = (manifest['openGaps'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final blockedSlugs = portions
        .where((row) => row['verification_status'] == 'blocked')
        .map((row) => row['food_slug'])
        .toSet();
    for (final slug in blockedSlugs) {
      expect(
        gaps.any((gap) => gap['foodSlug'] == slug),
        isTrue,
        reason: '$slug is blocked but missing from openGaps',
      );
    }
    expect(manifest['counts'], containsPair('portions', 30));
  });

  test('csv export mirrors the json manifest row for row', () {
    final csv = File(
      'tool/catalog/out/pilot_portion_manifest.csv',
    ).readAsStringSync();
    final header = csv.split('\n').first.split(',');
    expect(header, contains('verification_status'));
    expect(header, contains('transformation_notes'));
    expect(header, contains('source_page_or_table'));
    // One header line plus one line per portion plus the trailing newline.
    expect(_csvRecordCount(csv), portions.length);
  });
}

/// Counts CSV records without splitting inside a quoted field.
int _csvRecordCount(String csv) {
  var records = 0;
  var inQuotes = false;
  for (var index = 0; index < csv.length; index++) {
    final char = csv[index];
    if (char == '"') {
      final escaped = index + 1 < csv.length && csv[index + 1] == '"';
      if (escaped) {
        index++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char == '\n' && !inQuotes) {
      records++;
    }
  }
  return records - 1; // drop the header
}
