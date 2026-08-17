import 'package:flutter/foundation.dart';

import '../data/meal_repository.dart';
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

  Future<void> analyze(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty || _step == MealFlowStep.analyzing) return;
    _step = MealFlowStep.analyzing;
    _error = null;
    notifyListeners();
    try {
      _draft = await _repository.analyze(trimmed);
      _step = MealFlowStep.review;
    } catch (_) {
      _error = 'Öğünü analiz edemedik. Lütfen tekrar dene.';
      _step = MealFlowStep.compose;
    }
    notifyListeners();
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
