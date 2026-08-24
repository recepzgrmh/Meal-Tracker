import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/analysis/data/analysis_remote_data_source.dart';
import 'package:meal_clarity/src/analysis/data/supabase_meal_analysis_repository.dart';
import 'package:meal_clarity/src/data/meal_repository.dart';
import 'package:meal_clarity/src/domain/meal_analysis_input.dart';
import 'package:meal_clarity/src/domain/models.dart';
import 'package:meal_clarity/src/media/meal_photo_storage.dart';

void main() {
  test(
    'maps the versioned function response without losing provenance',
    () async {
      final remote = _FakeRemote(_response());
      final repository = SupabaseMealAnalysisRepository(
        remote: remote,
        requestIdFactory: () => 'request-id',
        itemIdFactory: () => '018f6a5e-3528-7b52-a47d-2d5efc3b2f60',
        clock: () => DateTime(2026, 8, 17, 8),
      );

      final draft = await repository.analyze(_input('2 yumurta ve peynir'));

      expect(remote.clientRequestId, 'request-id');
      expect(draft.mealName, 'Kahvaltı');
      expect(draft.analysisRunId, 'analysis-run');
      expect(draft.traceId, 'trace-id');
      expect(draft.unmatchedText, ['maydanoz']);
      expect(draft.items, hasLength(2));
      expect(draft.items.first.foodId, 'food-egg');
      expect(draft.items.first.id, '018f6a5e-3528-7b52-a47d-2d5efc3b2f60');
      expect(draft.items.first.analysisItemKey, 'item-1');
      expect(draft.items.first.canonicalName, 'Tavuk Yumurtası, Haşlanmış');
      expect(draft.items.first.displayName, 'Haşlanmış yumurta');
      expect(draft.items.first.matchState, MatchState.matched);
      expect(draft.items.first.portionOptions, hasLength(3));
      expect(draft.items.first.portionOptions[1].sizeClass, 'regular');
      expect(
        draft.items.first.portionOptions[1].imageUrl,
        endsWith('food-portions/yumurta/yumurta--regular--100g.webp'),
      );
      expect(draft.items.first.portionOptions.first.imageUrl, isNull);
      expect(draft.items.last.matchState, MatchState.checkType);
      expect(draft.items.last.confidence, 0.72);
    },
  );

  test(
    'parses a server-side AI estimate item without a catalog food id',
    () async {
      final repository = SupabaseMealAnalysisRepository(
        remote: _FakeRemote(_estimateResponse()),
        itemIdFactory: () => '018f6a5e-3528-7b52-a47d-2d5efc3b2f61',
      );

      final draft = await repository.analyze(_input('ev yapımı kısır'));

      final estimate = draft.items.single;
      expect(estimate.foodId, isNull);
      expect(estimate.estimateId, '0190aaaa-bbbb-7ccc-8ddd-eeeeffff0001');
      expect(estimate.isAiEstimate, isTrue);
      expect(estimate.matchMethod, 'ai_estimate');
      // The portion question stays open — an estimate arrives unreviewed.
      expect(estimate.matchState, MatchState.checkAmount);
      // No catalog provenance to claim, so the source label stays silent.
      expect(estimate.sourceName, isEmpty);
      expect(estimate.grams, 150);
      expect(estimate.nutritionPer100g.calories, 190);
    },
  );

  test('prefers unmatchedItems texts over the legacy string list', () async {
    final repository = SupabaseMealAnalysisRepository(
      remote: _FakeRemote({
        ..._response(),
        'unmatchedText': ['stale-legacy-value'],
        'unmatchedItems': [
          {'itemKey': 'unmatched-1', 'text': 'maydanoz'},
          {'itemKey': 'unmatched-2', 'text': 'ev yapımı sos'},
        ],
      }),
    );

    final draft = await repository.analyze(_input('yumurta'));

    expect(draft.unmatchedText, ['maydanoz', 'ev yapımı sos']);
  });

  test('threads identity alternatives through to the domain item', () async {
    final repository = SupabaseMealAnalysisRepository(
      remote: _FakeRemote(_response()),
    );

    final draft = await repository.analyze(_input('2 yumurta ve peynir'));

    expect(draft.items.first.alternativeFoodIds, isEmpty);
    expect(draft.items.last.matchState, MatchState.checkType);
    expect(draft.items.last.alternativeFoodIds, [
      'food-cheese-light',
      'food-cheese-goat',
    ]);
  });

  test('rejects an item claiming both or neither nutrition authority', () {
    for (final overrides in [
      // Neither: an item with no source of nutrition cannot be committed.
      {'foodId': null},
      // Both: the commit contract is exactly-one, so parsing fails closed.
      {'estimateId': '0190aaaa-bbbb-7ccc-8ddd-eeeeffff0002'},
    ]) {
      final response = _response();
      final items = List<Object?>.from(response['items'] as List);
      items[0] = <String, dynamic>{
        ...(items[0] as Map).cast<String, dynamic>(),
        ...overrides,
      };
      response['items'] = items;
      final repository = SupabaseMealAnalysisRepository(
        remote: _FakeRemote(response),
      );

      expect(
        repository.analyze(_input('yumurta')),
        throwsA(
          isA<MealAnalysisException>().having(
            (error) => error.kind,
            'kind',
            MealAnalysisFailureKind.invalidResponse,
          ),
        ),
        reason: 'overrides: $overrides',
      );
    }
  });

  test('carries NO_MATCH unmatched item texts into the domain failure', () {
    final repository = SupabaseMealAnalysisRepository(
      remote: _ThrowingRemote(
        const AnalysisRemoteException(
          code: 'NO_MATCH',
          status: 422,
          retryable: false,
          unmatchedTexts: ['ev yapımı turşu suyu'],
        ),
      ),
    );

    expect(
      repository.analyze(_input('ev yapımı turşu suyu')),
      throwsA(
        isA<MealAnalysisException>().having(
          (error) => error.unmatchedTexts,
          'unmatchedTexts',
          ['ev yapımı turşu suyu'],
        ),
      ),
    );
  });

  test('rejects a drifted or empty function contract', () async {
    final repository = SupabaseMealAnalysisRepository(
      remote: _FakeRemote({..._response(), 'contractVersion': 'analysis.v2'}),
    );

    expect(
      repository.analyze(_input('yumurta')),
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
      repository.analyze(_input('avokado')),
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

  test('uploads a mixed input photo before invoking analysis', () async {
    final remote = _FakeRemote(_response());
    final storage = _FakePhotoStorage();
    final repository = SupabaseMealAnalysisRepository(
      remote: remote,
      photoStorage: storage,
      requestIdFactory: () => '018f6a5e-3528-7b52-a47d-2d5efc3b2f66',
    );
    final photo = MealPhotoAttachment(
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'meal.jpg',
      mimeType: 'image/jpeg',
    );

    final draft = await repository.analyze(
      MealAnalysisInput(text: 'some cheese', locale: 'en-US', photo: photo),
    );

    expect(storage.requestId, '018f6a5e-3528-7b52-a47d-2d5efc3b2f66');
    expect(remote.inputKind, 'mixed');
    expect(remote.locale, 'en-US');
    expect(remote.photo?.path, contains('/source.jpg'));
    expect(draft.imagePath, contains('/source.jpg'));
    expect(draft.imageUrl, 'https://signed.example/meal.jpg');
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
      'portionOptions': [
        {'label': '1 adet', 'grams': 50, 'sizeClass': 'small'},
        {
          'label': '2 adet',
          'grams': 100,
          'sizeClass': 'regular',
          'imageUrl':
              'https://example.supabase.co/storage/v1/object/public/food-portion-references/food-portions/yumurta/yumurta--regular--100g.webp',
        },
        {'label': '3 adet', 'grams': 150, 'sizeClass': 'large'},
      ],
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
      'alternativeFoodIds': ['food-cheese-light', 'food-cheese-goat'],
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

/// The shape `tryEstimateFallback` emits when the catalog held no match.
Map<String, dynamic> _estimateResponse() => {
  'contractVersion': 'analysis.v1',
  'analysisRunId': 'analysis-run-estimate',
  'traceId': 'trace-estimate',
  'status': 'needs_review',
  'normalizedInput': 'ev yapımı kısır',
  'unmatchedText': <String>[],
  'unmatchedItems': <Map<String, dynamic>>[],
  'replayed': false,
  'items': [
    {
      'itemKey': 'item-1',
      'sourceText': 'ev yapımı kısır',
      'foodId': null,
      'estimateId': '0190aaaa-bbbb-7ccc-8ddd-eeeeffff0001',
      'estimated': true,
      'canonicalName': 'Kısır',
      'portionLabel': '150 g',
      'grams': 150,
      'quantity': 1,
      'confidence': 0.55,
      'matchMethod': 'ai_estimate',
      'needsClarification': true,
      'clarificationReason': 'portion',
      'nutritionPer100g': {
        'calories': 190,
        'protein': 4.2,
        'carbs': 30.1,
        'fat': 6.4,
      },
    },
  ],
  'pipeline': {
    'extraction': 'deterministic-tr-v1',
    'retrieval': 'hybrid-rrf-v1',
    'model': 'gpt-5.4-nano',
  },
};

class _FakeRemote implements AnalysisRemoteDataSource {
  _FakeRemote(this.response);

  final Map<String, dynamic> response;
  String? clientRequestId;
  String? inputKind;
  String? locale;
  StoredMealPhoto? photo;

  @override
  Future<Map<String, dynamic>> analyze({
    required String clientRequestId,
    required String input,
    required String inputKind,
    required String locale,
    StoredMealPhoto? photo,
  }) async {
    this.clientRequestId = clientRequestId;
    this.inputKind = inputKind;
    this.locale = locale;
    this.photo = photo;
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
    required String inputKind,
    required String locale,
    StoredMealPhoto? photo,
  }) async {
    throw error;
  }
}

MealAnalysisInput _input(String text) =>
    MealAnalysisInput(text: text, locale: 'tr-TR');

class _FakePhotoStorage implements MealPhotoStorage {
  String? requestId;

  @override
  Future<StoredMealPhoto> upload({
    required String requestId,
    required MealPhotoAttachment photo,
  }) async {
    this.requestId = requestId;
    return StoredMealPhoto(
      bucket: 'meal-photos',
      path: 'user/$requestId/source.jpg',
      mimeType: photo.mimeType,
      signedUrl: 'https://signed.example/meal.jpg',
    );
  }
}
