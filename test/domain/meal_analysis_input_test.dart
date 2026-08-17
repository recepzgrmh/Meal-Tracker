import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/domain/meal_analysis_input.dart';

void main() {
  const text = MealAnalysisInput(text: 'egg', locale: 'en-US');
  final photo = MealPhotoAttachment(
    bytes: Uint8List.fromList([1, 2, 3]),
    fileName: 'meal.jpg',
    mimeType: 'image/jpeg',
  );

  test('derives text, photo, and mixed kinds from actual attachments', () {
    expect(text.kind, MealInputKind.text);
    expect(
      MealAnalysisInput(text: '', locale: 'tr-TR', photo: photo).kind,
      MealInputKind.photo,
    );
    expect(
      MealAnalysisInput(text: 'yumurta', locale: 'tr-TR', photo: photo).kind,
      MealInputKind.mixed,
    );
  });

  test('only considers a request empty when text and photo are absent', () {
    expect(
      const MealAnalysisInput(text: '  ', locale: 'tr-TR').isEmpty,
      isTrue,
    );
    expect(
      MealAnalysisInput(text: '', locale: 'tr-TR', photo: photo).isEmpty,
      isFalse,
    );
  });
}
