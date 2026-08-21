import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/l10n/generated/app_localizations.dart';
import 'package:meal_clarity/src/data/meal_repository.dart';
import 'package:meal_clarity/src/domain/meal_analysis_input.dart';
import 'package:meal_clarity/src/features/meal_flow.dart';
import 'package:meal_clarity/src/media/meal_photo_picker.dart';
import 'package:meal_clarity/src/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('photo-only input enables analysis after gallery selection', (
    tester,
  ) async {
    final picker = _FakePhotoPicker();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(),
        home: MealFlow(repository: MockMealRepository(), photoPicker: picker),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('add-photo-button')));
    await tester.tap(find.byKey(const Key('add-photo-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galeriden seç'));
    await tester.pumpAndSettle();

    expect(picker.lastSource, MealPhotoSource.gallery);
    expect(find.byKey(const Key('meal-photo-preview')), findsOneWidget);
    final analyze = tester.widget<FilledButton>(
      find.byKey(const Key('analyze-button')),
    );
    expect(analyze.onPressed, isNotNull);

    await tester.ensureVisible(find.byKey(const Key('analyze-button')));
    await tester.tap(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('review-photo-preview')), findsOneWidget);
  });

  testWidgets('camera entry skips text composer and explains meal scanning', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final picker = _FakePhotoPicker();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(),
        home: MealFlow(
          repository: MockMealRepository(),
          photoPicker: picker,
          initialPhotoSource: MealPhotoSource.camera,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Yemeğini nasıl taratırsın?'), findsOneWidget);
    expect(
      find.text(
        'Tabağın tamamı görünsün; telefonu mümkün olduğunca yukarıdan ve sabit tut.',
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const Key('open-meal-camera-button')),
    );
    await tester.tap(find.byKey(const Key('open-meal-camera-button')));
    await tester.pumpAndSettle();

    expect(picker.lastSource, MealPhotoSource.camera);
    expect(find.byKey(const Key('meal-input')), findsNothing);
    expect(find.byKey(const Key('dedicated-photo-preview')), findsOneWidget);
    expect(find.byKey(const Key('analyze-photo-button')), findsOneWidget);
  });
}

class _FakePhotoPicker implements MealPhotoPicker {
  MealPhotoSource? lastSource;

  @override
  Future<MealPhotoAttachment?> pick(MealPhotoSource source) async {
    lastSource = source;
    return MealPhotoAttachment(
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
      fileName: 'meal.png',
      mimeType: 'image/png',
    );
  }

  @override
  Future<MealPhotoAttachment?> recoverLost() async => null;
}
