// Applies a reviewer's decisions to a draft mapping.
//
//   dart run tool/catalog/bin/curate_mapping.dart \
//     --draft tool/catalog/data/catalog_tier_a_mapping.draft.json \
//     --out   tool/catalog/data/catalog_tier_a_mapping.json \
//     --curated-by "Name <email>" \
//     --state-mismatch drop
//
// Records WHO decided which published row each food uses. It does not mark
// anything verified: verification_status stays needs_review and reviewed_by
// stays null, because curating the MAPPING is not the same as reviewing the
// OUTPUT. This script writes no gram and no nutrient value.
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final draftPath = _arg(args, '--draft');
  final outPath = _arg(args, '--out');
  final curatedBy = _arg(args, '--curated-by');
  final curatedAt = _arg(args, '--curated-at');
  final stateMismatch = _arg(args, '--state-mismatch') ?? 'drop';

  if (draftPath == null || outPath == null || curatedBy == null) {
    stderr.writeln(
      'Usage: curate_mapping.dart --draft <path> --out <path> '
      '--curated-by "Name <email>" [--curated-at <iso>] '
      '[--state-mismatch drop|keep]',
    );
    exit(64);
  }
  if (stateMismatch != 'drop' && stateMismatch != 'keep') {
    stderr.writeln('--state-mismatch must be "drop" or "keep"');
    exit(64);
  }

  final stamp =
      curatedAt ??
      '${DateTime.now().toUtc().toIso8601String().split('.').first}Z';

  final draft =
      jsonDecode(File(draftPath).readAsStringSync()) as Map<String, dynamic>;
  final foods = (draft['foods'] as List).cast<Map<String, dynamic>>();

  var kept = 0;
  var dropped = 0;
  var never = 0;

  for (final food in foods) {
    final portion = food['portion'] as Map<String, dynamic>?;

    if (portion == null) {
      never++;
    } else if (portion['status'] == 'needs_state_decision') {
      if (stateMismatch == 'drop') {
        // The published row describes the food in a different preparation
        // state, so its weight is not transferable -- 100 g of raw spinach is
        // roughly 35 g cooked. Drop the portion rather than transfer it; the
        // food still ships with verified composition and the app asks the
        // user for the amount.
        food['portion'] = null;
        food['reviewerNotes'] =
            'Portion dropped by curation: ${portion['rowName']} describes a '
            'different preparation state, so its published weight is not '
            'transferable. Composition is unaffected and remains published. '
            '${food['reviewerNotes']}';
        dropped++;
      } else {
        portion.remove('status');
        kept++;
      }
    } else {
      kept++;
    }

    food['status'] = 'mapped';
    food['curatedBy'] = curatedBy;
    food['curatedAt'] = stamp;
  }

  draft
    ..['status'] = 'curated'
    ..['curatedBy'] = curatedBy
    ..['curatedAt'] = stamp
    ..['curationDecisions'] = <String, dynamic>{
      'stateMismatchPolicy': stateMismatch,
      'portionsKept': kept,
      'portionsDroppedOnStateMismatch': dropped,
      'foodsWithNoPublishedRow': never,
      'note':
          'A food without a portion is not excluded from the catalog. Its '
          'composition is published and verified; only food_portions rows are '
          'absent, and the app asks the user for the amount.',
    };
  (draft['counts'] as Map<String, dynamic>)['withPortionAfterCuration'] = kept;

  File(
    outPath,
  ).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(draft)}\n');

  stdout
    ..writeln('curatedBy=$curatedBy  at=$stamp')
    ..writeln('  portions kept                   $kept')
    ..writeln('  portions dropped (state)        $dropped')
    ..writeln('  no published row to begin with  $never')
    ..writeln('-> $outPath');
}

String? _arg(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i == -1 || i + 1 >= args.length) return null;
  return args[i + 1];
}
