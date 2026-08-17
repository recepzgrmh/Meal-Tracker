import 'package:uuid/uuid.dart';

import '../../data/meal_repository.dart';
import '../../domain/meal_analysis_input.dart';
import '../../domain/models.dart';
import '../../media/meal_photo_storage.dart';
import 'analysis_remote_data_source.dart';
import 'analysis_response_dto.dart';

typedef AnalysisRequestIdFactory = String Function();
typedef AnalysisClock = DateTime Function();

class SupabaseMealAnalysisRepository implements MealRepository {
  SupabaseMealAnalysisRepository({
    required AnalysisRemoteDataSource remote,
    MealPhotoStorage? photoStorage,
    AnalysisRequestIdFactory? requestIdFactory,
    AnalysisClock? clock,
  }) : _remote = remote,
       _photoStorage = photoStorage,
       _requestIdFactory = requestIdFactory ?? const Uuid().v4,
       _clock = clock ?? DateTime.now;

  final AnalysisRemoteDataSource _remote;
  final MealPhotoStorage? _photoStorage;
  final AnalysisRequestIdFactory _requestIdFactory;
  final AnalysisClock _clock;

  @override
  Future<MealDraft> analyze(MealAnalysisInput request) async {
    try {
      final requestId = _requestIdFactory();
      final photo = request.photo == null
          ? null
          : await _uploadPhoto(requestId, request.photo!);
      final json = await _remote.analyze(
        clientRequestId: requestId,
        input: request.text,
        inputKind: request.kind.name,
        locale: request.locale,
        photo: photo,
      );
      final response = AnalysisResponseDto.fromJson(json);
      return MealDraft(
        inputText: request.text,
        mealName: _mealName(_clock()),
        analysisRunId: response.analysisRunId,
        traceId: response.traceId,
        unmatchedText: response.unmatchedText,
        items: response.items
            .map(
              (item) => MealItem(
                id: item.itemKey,
                foodId: item.foodId,
                name: item.canonicalName,
                sourceText: item.sourceText,
                portionLabel: item.portionLabel,
                grams: item.grams,
                nutritionPer100g: Nutrition(
                  calories: item.nutritionPer100g.calories,
                  protein: item.nutritionPer100g.protein,
                  carbs: item.nutritionPer100g.carbs,
                  fat: item.nutritionPer100g.fat,
                ),
                matchState: _matchState(item),
                sourceName: 'Curated food catalog · exact-alias-v1',
                confidence: item.confidence,
                matchMethod: item.matchMethod,
              ),
            )
            .toList(growable: false),
      );
    } on AnalysisRemoteException catch (error) {
      throw _mapRemoteFailure(error);
    } on MealPhotoStorageException catch (error) {
      throw MealAnalysisException(
        kind: error.code == 'UNAUTHENTICATED'
            ? MealAnalysisFailureKind.unauthenticated
            : MealAnalysisFailureKind.unavailable,
        code: error.code,
        retryable: error.code == 'PHOTO_UPLOAD_FAILED',
      );
    } on FormatException {
      throw const MealAnalysisException(
        kind: MealAnalysisFailureKind.invalidResponse,
        code: 'INVALID_RESPONSE',
        retryable: true,
      );
    }
  }

  Future<StoredMealPhoto> _uploadPhoto(
    String requestId,
    MealPhotoAttachment photo,
  ) {
    final storage = _photoStorage;
    if (storage == null) {
      throw const MealPhotoStorageException('PHOTO_STORAGE_UNAVAILABLE');
    }
    return storage.upload(requestId: requestId, photo: photo);
  }

  MatchState _matchState(AnalysisItemDto item) {
    if (!item.needsClarification) return MatchState.matched;
    return item.clarificationReason == 'identity'
        ? MatchState.checkType
        : MatchState.checkAmount;
  }

  MealAnalysisException _mapRemoteFailure(AnalysisRemoteException error) {
    final kind = switch (error.code) {
      'NO_MATCH' => MealAnalysisFailureKind.noMatch,
      'UNAUTHENTICATED' ||
      'UNAUTHORIZED_NO_AUTH_HEADER' => MealAnalysisFailureKind.unauthenticated,
      'INVALID_REQUEST' => MealAnalysisFailureKind.invalidRequest,
      'RATE_LIMITED' => MealAnalysisFailureKind.rateLimited,
      'NETWORK_UNAVAILABLE' ||
      'FUNCTION_UNAVAILABLE' ||
      'INTERNAL_ERROR' => MealAnalysisFailureKind.unavailable,
      'INVALID_RESPONSE' => MealAnalysisFailureKind.invalidResponse,
      _ => MealAnalysisFailureKind.unknown,
    };
    return MealAnalysisException(
      kind: kind,
      code: error.code,
      retryable: error.retryable,
    );
  }

  String _mealName(DateTime time) {
    return switch (time.hour) {
      >= 5 && < 11 => 'Kahvaltı',
      >= 11 && < 16 => 'Öğle yemeği',
      >= 16 && < 22 => 'Akşam yemeği',
      _ => 'Atıştırma',
    };
  }
}
