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
    AnalysisRequestIdFactory? itemIdFactory,
  }) : _remote = remote,
       _photoStorage = photoStorage,
       _requestIdFactory = requestIdFactory ?? const Uuid().v4,
       _clock = clock ?? DateTime.now,
       _itemIdFactory = itemIdFactory ?? const Uuid().v4;

  final AnalysisRemoteDataSource _remote;
  final MealPhotoStorage? _photoStorage;
  final AnalysisRequestIdFactory _requestIdFactory;
  final AnalysisClock _clock;
  final AnalysisRequestIdFactory _itemIdFactory;

  @override
  Future<MealDraft> analyze(MealAnalysisInput request) async {
    try {
      // Reuse the caller's id when it has one: a retry of the same meal must
      // reach the server's replay path rather than paying for the pipeline
      // again. Minting one here unconditionally is what made that path dead.
      final requestId = request.requestId ?? _requestIdFactory();
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
        imagePath: photo?.path,
        imageUrl: photo?.signedUrl,
        // `unmatchedItems` is the authoritative shape now; the legacy string
        // list keeps older recorded responses parsing.
        unmatchedText: response.unmatchedItems.isNotEmpty
            ? response.unmatchedItems
                  .map((item) => item.text)
                  .toList(growable: false)
            : response.unmatchedText,
        items: response.items
            .map(
              (item) => MealItem(
                id: _itemIdFactory(),
                analysisItemKey: item.itemKey,
                foodId: item.foodId,
                estimateId: item.estimateId,
                // The catalog name can be English for a Turkish meal, so the
                // server's localized title wins when it sent one.
                name: naturalFoodDisplayName(
                  item.displayName ?? item.canonicalName,
                ),
                canonicalName: item.canonicalName,
                displayName: naturalFoodDisplayName(
                  item.displayName ?? item.canonicalName,
                ),
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
                // An estimate has no catalog provenance to claim; the empty
                // string is what lets the UI skip the source label for it.
                //
                // Otherwise the provenance is the catalog row itself. It used
                // to be the retrieval pipeline's version string, which told the
                // user nothing and leaked an internal label; the row's name
                // answers "where did this number come from" — and it is also
                // where the English catalog name belongs now that the title
                // shows the user's own words.
                sourceName: item.estimated ? '' : item.canonicalName,
                confidence: item.confidence,
                matchMethod: item.matchMethod,
                alternativeFoodIds: item.alternativeFoodIds,
                portionOptions: item.portionOptions
                    .map(
                      (option) => FoodPortionOption(
                        label: option.label,
                        grams: option.grams,
                        sizeClass: option.sizeClass,
                        imageUrl: option.imageUrl,
                      ),
                    )
                    .toList(growable: false),
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
      // UNAUTHORIZED_NO_AUTH_HEADER came from the Supabase Edge gateway and can
      // no longer be emitted; FORBIDDEN is what the Node backend's auth layer
      // returns. Without it an expired session fell through to `unknown` and
      // the user was told to check their connection.
      'UNAUTHENTICATED' ||
      'FORBIDDEN' ||
      'UNAUTHORIZED_NO_AUTH_HEADER' => MealAnalysisFailureKind.unauthenticated,
      'INVALID_REQUEST' => MealAnalysisFailureKind.invalidRequest,
      'RATE_LIMITED' => MealAnalysisFailureKind.rateLimited,
      'NETWORK_UNAVAILABLE' ||
      'FUNCTION_UNAVAILABLE' ||
      'PROVIDER_UNAVAILABLE' => MealAnalysisFailureKind.unavailable,
      'INTERNAL_ERROR' => MealAnalysisFailureKind.serverError,
      'INVALID_RESPONSE' => MealAnalysisFailureKind.invalidResponse,
      _ => MealAnalysisFailureKind.unknown,
    };
    return MealAnalysisException(
      kind: kind,
      code: error.code,
      retryable: error.retryable,
      unmatchedTexts: error.unmatchedTexts,
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
