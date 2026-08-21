@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/catalog/src/slug.dart';

void main() {
  group('turkishSlug', () {
    test('transliterates every Turkish character to ASCII', () {
      expect(turkishSlug('Yoğurt, tam yağlı'), 'yogurt-tam-yagli');
      expect(
        turkishSlug('Antep fıstığı, iç, kavrulmuş'),
        'antep-fistigi-ic-kavrulmus',
      );
      expect(turkishSlug('Çarliston biber'), 'carliston-biber');
      expect(turkishSlug('İncir'), 'incir');
      expect(turkishSlug('ÜZÜM'), 'uzum');
      expect(turkishSlug('Şeftali'), 'seftali');
      expect(turkishSlug('Kurusoğan'), 'kurusogan');
    });

    test('does not swallow dotless i, which a naive lowercase would drop', () {
      // Guards the regression the transliteration map exists to prevent:
      // without it "Antep fıstığı" collapses to "antep-f-st".
      expect(turkishSlug('Antep fıstığı'), 'antep-fistigi');
      expect(turkishSlug('fıstık'), 'fistik');
    });

    test('collapses punctuation and parentheticals into single hyphens', () {
      expect(
        turkishSlug('Peynir, beyaz, tam yağlı (yağ, kuru maddede > % 45)'),
        'peynir-beyaz-tam-yagli-yag-kuru-maddede-45',
      );
      expect(turkishSlug('  Süt   --  tam   yağlı  '), 'sut-tam-yagli');
    });

    test('rejects a name that produces no slug-able character', () {
      expect(() => turkishSlug('---'), throwsArgumentError);
      expect(() => turkishSlug(''), throwsArgumentError);
    });

    test('every output satisfies the guard image_prompt.dart applies', () {
      for (final name in <String>[
        'Yoğurt, tam yağlı',
        'İç bakla, haşlanmış',
        'Ton balığı konserve',
        'Şalgam suyu',
      ]) {
        expect(isValidSlug(turkishSlug(name)), isTrue, reason: name);
      }
    });

    test('round-trips every canonical name already in the pilot mapping', () {
      final mapping =
          jsonDecode(
                File(
                  'tool/catalog/data/pilot_food_mapping.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      for (final food
          in (mapping['foods'] as List).cast<Map<String, dynamic>>()) {
        final name = food['canonicalNameTr'] as String?;
        if (name == null) continue;
        expect(isValidSlug(turkishSlug(name)), isTrue, reason: name);
      }
    });
  });
}
