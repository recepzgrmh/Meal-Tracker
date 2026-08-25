import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/data/meal_repository.dart';
import 'package:meal_clarity/src/domain/meal_analysis_input.dart';
import 'package:meal_clarity/src/domain/models.dart';
import 'package:meal_clarity/src/view_models/meal_flow_view_model.dart';

/// The server stores analysis runs under `(user_id, client_request_id)` and
/// replays a completed one instead of re-running the pipeline. That machinery —
/// the replay branch, the unique constraint — was unreachable because the client
/// minted a fresh id on every call, so every retry paid for the full set of
/// provider calls again.
void main() {
  test('retrying the same meal reuses the request id', () async {
    final repository = _RecordingRepository();
    var next = 0;
    final viewModel = MealFlowViewModel(
      repository: repository,
      requestIdFactory: () => 'req-${next++}',
    );

    const input = MealAnalysisInput(text: '2 yumurta', locale: 'tr-TR');
    await viewModel.analyze(input);
    // The first attempt failed, so the user taps analyze again on the same text.
    await viewModel.analyze(input);

    expect(repository.requestIds, ['req-0', 'req-0']);
  });

  test('composing a different meal gets a new request id', () async {
    // A different meal is a different intent: replaying the previous answer for
    // it would be worse than paying for the call.
    final repository = _RecordingRepository();
    var next = 0;
    final viewModel = MealFlowViewModel(
      repository: repository,
      requestIdFactory: () => 'req-${next++}',
    );

    await viewModel.analyze(
      const MealAnalysisInput(text: '2 yumurta', locale: 'tr-TR'),
    );
    await viewModel.analyze(
      const MealAnalysisInput(text: 'bir simit', locale: 'tr-TR'),
    );

    expect(repository.requestIds, ['req-0', 'req-1']);
  });

  test('whitespace-only edits are the same meal', () async {
    // The text is trimmed before it is compared, so a stray trailing space is
    // not a new intent.
    final repository = _RecordingRepository();
    var next = 0;
    final viewModel = MealFlowViewModel(
      repository: repository,
      requestIdFactory: () => 'req-${next++}',
    );

    await viewModel.analyze(
      const MealAnalysisInput(text: '2 yumurta', locale: 'tr-TR'),
    );
    await viewModel.analyze(
      const MealAnalysisInput(text: '  2 yumurta  ', locale: 'tr-TR'),
    );

    expect(repository.requestIds, ['req-0', 'req-0']);
  });
}

class _RecordingRepository implements MealRepository {
  final requestIds = <String?>[];

  @override
  Future<MealDraft> analyze(MealAnalysisInput input) async {
    requestIds.add(input.requestId);
    // Fails so the flow returns to the composer and a retry is possible.
    throw const MealAnalysisException(
      kind: MealAnalysisFailureKind.unavailable,
      code: 'PROVIDER_UNAVAILABLE',
      retryable: true,
    );
  }
}
