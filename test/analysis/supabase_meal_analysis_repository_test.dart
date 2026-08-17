import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/analysis/data/analysis_remote_data_source.dart';
import 'package:meal_clarity/src/analysis/data/supabase_meal_analysis_repository.dart';
import 'package:meal_clarity/src/data/meal_repository.dart';
import 'package:meal_clarity/src/domain/models.dart';

void main() {
  test(
    'maps the versioned function response without losing provenance',
    () async {
      final remote = _FakeRemote(_response());
      final repository = SupabaseMealAnalysisRepository(
        remote: remote,
        requestIdFactory: () => 'request-id',
        clock: () => DateTime(2026, 8, 17, 8),
      );

      final draft = await repository.analyze('2 yumurta ve peynir');

      expect(remote.clientRequestId, 'request-id');
      expect(draft.mealName, 'Kahvaltı');
      expect(draft.analysisRunId, 'analysis-run');
      expect(draft.traceId, 'trace-id');
      expect(draft.unmatchedText, ['maydanoz']);
      expect(draft.items, hasLength(2));
      expect(draft.items.first.foodId, 'food-egg');
      expect(draft.items.first.matchState, MatchState.matched);
      expect(draft.items.last.matchState, MatchState.checkType);
      expect(draft.items.last.confidence, 0.72);
    },
  );

  test('rejects a drifted or empty function contract', () async {
    final repository = SupabaseMealAnalysisRepository(
      remote: _FakeRemote({..._response(), 'contractVersion': 'analysis.v2'}),
    );

    expect(
      repository.analyze('yumurta'),
      throwsA(
        isA<MealAnalysisException>().having(
          (error) => error.kind,
          'kind',
          MealAnalysisFailureKind.invalidResponse,
        ),
      ),
    );
  });

  test('maps NO_MATCH into a stable non-retryable domain failure', () async {
    final repository = SupabaseMealAnalysisRepository(
      remote: _ThrowingRemote(
        const AnalysisRemoteException(
          code: 'NO_MATCH',
          status: 422,
          retryable: false,
        ),
      ),
    );

    expect(
      repository.analyze('avokado'),
      throwsA(
        isA<MealAnalysisException>()
            .having(
              (error) => error.kind,
              'kind',
              MealAnalysisFailureKind.noMatch,
            )
            .having((error) => error.retryable, 'retryable', false),
      ),
    );
  });
}

Map<String, dynamic> _response() => {
  'contractVersion': 'analysis.v1',
  'analysisRunId': 'analysis-run',
  'traceId': 'trace-id',
  'status': 'needs_review',
  'normalizedInput': '2 yumurta ve peynir',
  'unmatchedText': ['maydanoz'],
  'replayed': false,
  'items': [
    {
      'itemKey': 'item-1',
      'sourceText': 'yumurta',
      'foodId': 'food-egg',
      'canonicalName': 'Tavuk Yumurtası, Haşlanmış',
      'portionLabel': '2 adet',
      'grams': 100,
      'quantity': 2,
      'confidence': 0.98,
      'matchMethod': 'exact',
      'needsClarification': false,
      'nutritionPer100g': {
        'calories': 155,
        'protein': 12.6,
        'carbs': 1.1,
        'fat': 10.6,
      },
    },
    {
      'itemKey': 'item-2',
      'sourceText': 'peynir',
      'foodId': 'food-cheese',
      'canonicalName': 'Beyaz Peynir',
      'portionLabel': '30 g',
      'grams': 30,
      'quantity': 1,
      'confidence': 0.72,
      'matchMethod': 'alias',
      'needsClarification': true,
      'clarificationReason': 'identity',
      'nutritionPer100g': {
        'calories': 289,
        'protein': 16,
        'carbs': 2.5,
        'fat': 24,
      },
    },
  ],
  'pipeline': {
    'extraction': 'deterministic-tr-v1',
    'retrieval': 'exact-alias-v1',
    'model': null,
  },
};

class _FakeRemote implements AnalysisRemoteDataSource {
  _FakeRemote(this.response);

  final Map<String, dynamic> response;
  String? clientRequestId;

  @override
  Future<Map<String, dynamic>> analyze({
    required String clientRequestId,
    required String input,
  }) async {
    this.clientRequestId = clientRequestId;
    return response;
  }
}

class _ThrowingRemote implements AnalysisRemoteDataSource {
  const _ThrowingRemote(this.error);

  final AnalysisRemoteException error;

  @override
  Future<Map<String, dynamic>> analyze({
    required String clientRequestId,
    required String input,
  }) async {
    throw error;
  }
}
