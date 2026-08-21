@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';

import '../../tool/catalog/src/tuber_match.dart';

void main() {
  group('memberNames', () {
    test('splits comma, veya and hyphen lists', () {
      expect(
        memberNames('Nohut, fasulye, barbunya, iç bakla, börülce (haşlanmış)'),
        ['nohut', 'fasulye', 'barbunya', 'ic bakla', 'borulce'],
      );
      expect(memberNames('Galeta veya Grissini'), ['galeta', 'grissini']);
      expect(memberNames('Pide- Bazlama-Lavaş'), ['pide', 'bazlama', 'lavas']);
    });

    test('redistributes a head noun shared across a slash list', () {
      // "Buğday/pirinç gevreği" is wheat FLAKES and rice FLAKES. Splitting
      // naively yields a bare "buğday" member, which then matches raw durum
      // wheat and hands it a 30 g breakfast-cereal portion.
      expect(memberNames('Buğday/pirinç gevreği'), [
        'bugday gevregi',
        'pirinc gevregi',
      ]);
      expect(memberNames('Buğday/pirinç gevreği'), isNot(contains('bugday')));
    });

    test('leaves a slash list alone when the parts are already complete', () {
      expect(memberNames('Yulaf ezmesi/Müsli'), ['yulaf ezmesi', 'musli']);
    });
  });

  group('preparationState', () {
    test('reads a state recorded in a parenthetical', () {
      // TÜBER marks this row cooked only inside the parenthetical; reading the
      // normalized name would report it fresh and make raw dry beans eligible
      // for a cooked portion.
      expect(
        preparationState(
          'Nohut, fasulye, barbunya, iç bakla, '
          'börülce (haşlanmış)',
        ),
        PreparationState.cooked,
      );
      expect(preparationState('Barbunya (barbun)'), PreparationState.fresh);
    });

    test('does not read a dry-matter fat spec as a dried food', () {
      // "yağ, kuru maddede > % 45" is a cheese fat-content specification.
      // preparationState reads parentheticals (it must, for "(haşlanmış)"),
      // so this exclusion is what keeps cheese out of the dried bucket.
      expect(
        preparationState('Peynir, beyaz, tam yağlı (yağ, kuru maddede > % 45)'),
        PreparationState.fresh,
      );
    });

    test('distinguishes dried, cooked, canned and frozen forms', () {
      expect(preparationState('Elma'), PreparationState.fresh);
      expect(preparationState('Elma, kuru'), PreparationState.dried);
      expect(preparationState('Mısır, pişmiş'), PreparationState.cooked);
      expect(preparationState('Ceviz, iç, kuru'), PreparationState.dried);
      expect(
        preparationState('Domates, doğranmış, konserve'),
        PreparationState.canned,
      );
      expect(preparationState('Çilek, dondurulmuş'), PreparationState.frozen);
      expect(
        preparationState('Antep fıstığı, iç, kavrulmuş'),
        PreparationState.roasted,
      );
    });
  });

  group('normalizeFoodName / baseFoodName', () {
    test('folds Turkish characters and drops parentheticals', () {
      expect(
        normalizeFoodName('Yoğurt, homojenize, tam yağlı (süt yağı ≥ % 3.8)'),
        'yogurt homojenize tam yagli',
      );
    });

    test('base name is the head noun before the first comma', () {
      expect(baseFoodName('Elma, yazlık, Gala çeşidi'), 'elma');
      expect(baseFoodName('Domates suyu'), 'domates suyu');
      // Head-noun matching must not collapse juice into the whole vegetable.
      expect(baseFoodName('Domates suyu'), isNot(baseFoodName('Domates')));
    });
  });

  group('tokensCompatible (inverted TürKomp names)', () {
    test('matches a record whose word order TÜBER writes the other way', () {
      // TürKomp writes the genus first; TÜBER writes natural word order.
      // Head-noun comparison fails on every such name -- this is why no
      // cheese matched at all before the rule existed.
      expect(
        tokensCompatible(
          'Peynir, beyaz, tam yağlı (yağ, kuru maddede > % 45)',
          'Beyaz peynir, tam yağlı',
        ),
        isTrue,
      );
    });

    test('lets a general row serve the cultivars beneath it', () {
      expect(tokensCompatible('Elma, yazlık, Gala çeşidi', 'Elma'), isTrue);
    });

    test('does not let a whole vegetable swallow its juice', () {
      // The record's head clause is "domates suyu"; "suyu" is not a TÜBER
      // token, so the juice must not inherit the vegetable's portion.
      expect(tokensCompatible('Domates suyu', 'Domates'), isFalse);
      expect(tokensCompatible('Domates suyu', 'Domates suyu'), isTrue);
    });
  });

  group('food-group guard', () {
    test('reads the group from a TürKomp record code', () {
      expect(groupFromRecordCode('04.01.0002'), FoodGroup.fish);
      expect(groupFromRecordCode('07.02.0011'), FoodGroup.legumeSeed);
      expect(groupFromRecordCode('09.01.0002'), FoodGroup.fruit);
    });

    test('refuses a fish the legume row its head noun collides with', () {
      // "Barbunya (barbun)" is 04.01 — a red mullet — but its head noun
      // appears in "Nohut, fasulye, barbunya, iç bakla, börülce (haşlanmış)".
      final row = groupFromRowName(
        'Nohut, fasulye, barbunya, iç bakla, börülce (haşlanmış)',
      );
      expect(row, FoodGroup.legumeSeed);
      expect(groupsCompatible(FoodGroup.fish, row), isFalse);
      expect(groupsCompatible(FoodGroup.legumeSeed, row), isTrue);
    });

    test('stays permissive where rows carry no group keyword', () {
      // Fruit and vegetable rows are named after the food itself, so the
      // keyword table cannot classify them and must not block them.
      expect(groupFromRowName('Elma'), FoodGroup.other);
      expect(groupsCompatible(FoodGroup.fruit, FoodGroup.other), isTrue);
    });
  });

  group('hasDistinctSpecies', () {
    test('rejects a record the head noun would wrongly match', () {
      // TÜBER "Yumurta" is 100 g = 2 hen eggs.
      expect(hasDistinctSpecies('Yumurta, bıldırcın, tam'), isTrue);
      expect(hasDistinctSpecies('Yumurta, devekuşu, tam'), isTrue);
      expect(hasDistinctSpecies('Yumurta, beyaz, pastörize'), isFalse);
    });
  });
}
