import 'package:flutter/foundation.dart';

import '../data/meal_repository.dart';
import '../domain/meal_analysis_input.dart';
import '../domain/models.dart';

enum MealFlowStep { compose, analyzing, review }

class MealFlowViewModel extends ChangeNotifier {
  MealFlowViewModel({required MealRepository repository})
    : _repository = repository;

  final MealRepository _repository;

  MealFlowStep _step = MealFlowStep.compose;
  MealDraft? _draft;
  String? _error;

  MealFlowStep get step => _step;
  MealDraft? get draft => _draft;
  String? get error => _error;

  Future<void> analyze(MealAnalysisInput input) async {
    if (input.isEmpty || _step == MealFlowStep.analyzing) return;
    final normalized = MealAnalysisInput(
      text: input.text.trim(),
      locale: input.locale,
      photo: input.photo,
    );
    _step = MealFlowStep.analyzing;
    _error = null;
    notifyListeners();
    try {
      _draft = await _repository.analyze(normalized);
      _step = MealFlowStep.review;
    } on MealAnalysisException catch (error) {
      _error = _messageFor(error.kind);
      _step = MealFlowStep.compose;
    } catch (_) {
      _error = 'Öğünü analiz edemedik. Bağlantını kontrol edip tekrar dene.';
      _step = MealFlowStep.compose;
    }
    notifyListeners();
  }

  String _messageFor(MealAnalysisFailureKind kind) {
    return switch (kind) {
      MealAnalysisFailureKind.noMatch =>
        'Bu yiyeceği katalogda güvenle eşleştiremedik. Daha açık tarif etmeyi dene.',
      MealAnalysisFailureKind.unauthenticated =>
        'Oturumun yenilenmeli. Tekrar giriş yapıp deneyebilirsin.',
      MealAnalysisFailureKind.invalidRequest =>
        'Açıklamayı anlayamadık. Daha kısa ve net yazmayı dene.',
      MealAnalysisFailureKind.rateLimited =>
        'Çok hızlı deneme yaptın. Biraz bekleyip tekrar dene.',
      MealAnalysisFailureKind.unavailable ||
      MealAnalysisFailureKind.invalidResponse ||
      MealAnalysisFailureKind.unknown =>
        'Öğünü analiz edemedik. Bağlantını kontrol edip tekrar dene.',
    };
  }

  void showComposer() {
    if (_step == MealFlowStep.compose) return;
    _step = MealFlowStep.compose;
    notifyListeners();
  }

  void updateItem(MealItem updated) {
    if (_draft == null) return;
    _draft = _draft!.updateItem(updated);
    notifyListeners();
  }
}
