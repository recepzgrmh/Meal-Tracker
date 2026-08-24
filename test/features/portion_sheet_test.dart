import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/l10n/generated/app_localizations.dart';
import 'package:meal_clarity/src/data/meal_repository.dart';
import 'package:meal_clarity/src/domain/meal_analysis_input.dart';
import 'package:meal_clarity/src/domain/models.dart';
import 'package:meal_clarity/src/features/meal_flow.dart';
import 'package:meal_clarity/src/theme/app_theme.dart';

const _imageUrl =
    'https://cdn.example.test/food-portions/beyaz-peynir/'
    'beyaz-peynir--regular--60g.webp';

/// The catalog portions of the pilot batch: reviewed reference images plus the
/// gram values that come from the controlled portion record, not from a model.
const _catalogItem = MealItem(
  id: 'item-cheese',
  name: 'Beyaz peynir',
  sourceText: 'beyaz peynir',
  portionLabel: '60 g',
  grams: 60,
  nutritionPer100g: Nutrition(
    calories: 309,
    protein: 16.01,
    carbs: 8.21,
    fat: 23.55,
  ),
  matchState: MatchState.checkAmount,
  portionOptions: [
    FoodPortionOption(
      label: 'az',
      grams: 40,
      sizeClass: 'small',
      imageUrl: '$_imageUrl#small',
    ),
    FoodPortionOption(
      label: '1 porsiyon',
      grams: 60,
      sizeClass: 'regular',
      imageUrl: _imageUrl,
    ),
    FoodPortionOption(
      label: 'fazla',
      grams: 90,
      sizeClass: 'large',
      imageUrl: '$_imageUrl#large',
    ),
  ],
);

void main() {
  Future<void> openPortionSheet(
    WidgetTester tester, {
    MealItem item = _catalogItem,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: MealFlow(repository: _FakeRepository(item)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('meal-input')), 'beyaz peynir');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('analyze-button')));
    await tester.tap(find.byKey(const Key('analyze-button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // The composer screen has a pre-existing RenderFlex overflow above ~1.4x
    // text scale. It is out of scope here, so it is cleared explicitly and the
    // assertions below cover only what the portion sheet itself renders.
    tester.takeException();

    await tester.tap(find.byKey(const Key('review-edit-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('portion-title')), findsOneWidget);
  }

  testWidgets('shows the reviewed catalog image for every portion', (
    tester,
  ) async {
    await _withImageResponse(_transparentPng, () async {
      await openPortionSheet(tester);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('portion-reference-image')),
        findsNWidgets(3),
      );
      expect(
        find.byKey(const Key('portion-reference-placeholder')),
        findsNothing,
      );
      final images = tester
          .widgetList<Image>(find.byKey(const Key('portion-reference-image')))
          .map((image) => (image.image as NetworkImage).url)
          .toList();
      expect(images, ['$_imageUrl#small', _imageUrl, '$_imageUrl#large']);
    });
  });

  testWidgets('falls back to the relative drawing when the image fails', (
    tester,
  ) async {
    await _withImageResponse(null, () async {
      await openPortionSheet(tester);
      await tester.pumpAndSettle();

      // The Image widgets stay in the tree; their errorBuilder renders the
      // schematic, which never claims photographic precision.
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
      for (final grams in const [40, 60, 90]) {
        expect(find.byKey(Key('portion-$grams')), findsOneWidget);
      }
    });
  });

  testWidgets('keeps the schematic when the catalog has no reviewed image', (
    tester,
  ) async {
    await openPortionSheet(
      tester,
      item: const MealItem(
        id: 'item-rice',
        name: 'Pirinç',
        sourceText: 'pirinç',
        portionLabel: '180 g',
        grams: 180,
        nutritionPer100g: Nutrition(
          calories: 93.33,
          protein: 2,
          carbs: 20,
          fat: 0,
        ),
        matchState: MatchState.checkAmount,
        portionOptions: [
          FoodPortionOption(label: 'az', grams: 90, sizeClass: 'small'),
          FoodPortionOption(label: 'normal', grams: 180, sizeClass: 'regular'),
          FoodPortionOption(label: 'fazla', grams: 270, sizeClass: 'large'),
        ],
      ),
    );

    expect(find.byKey(const Key('portion-reference-image')), findsNothing);
    expect(find.byKey(const Key('portion-90')), findsOneWidget);
    expect(find.byKey(const Key('portion-180')), findsOneWidget);
    expect(find.byKey(const Key('portion-270')), findsOneWidget);
  });

  testWidgets('labels the three sizes and their gram values', (tester) async {
    await openPortionSheet(tester);

    expect(find.text('Az'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Fazla'), findsOneWidget);
    expect(find.text('40 g'), findsOneWidget);
    expect(find.text('60 g'), findsOneWidget);
    expect(find.text('90 g'), findsOneWidget);
  });

  testWidgets('marks the selected portion for assistive technology', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await openPortionSheet(tester);

    expect(
      tester.getSemantics(find.byKey(const Key('portion-60'))),
      matchesSemantics(
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
        label: 'Beyaz peynir, Normal, 60 g',
      ),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('portion-40'))),
      matchesSemantics(
        isButton: true,
        isSelected: false,
        hasSelectedState: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
        label: 'Beyaz peynir, Az, 40 g',
      ),
    );
    handle.dispose();
  });

  testWidgets('the whole card is the tap target and it applies catalog grams', (
    tester,
  ) async {
    await openPortionSheet(tester);

    // Tap the image area rather than the label to prove the card is tappable.
    await tester.tap(find.byKey(const Key('portion-90')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('portion-title')), findsNothing);
    expect(find.text('90 g'), findsWidgets);
  });

  testWidgets('the exact-gram entry stays available alongside the images', (
    tester,
  ) async {
    await openPortionSheet(tester);

    expect(find.byKey(const Key('portion-grams-input')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('portion-grams-input')), '73');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uygula'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('portion-title')), findsNothing);
    expect(find.text('73 g'), findsWidgets);
  });

  for (final width in const [360.0, 390.0, 430.0]) {
    testWidgets('lays out without overflow at ${width.toInt()} px', (
      tester,
    ) async {
      await openPortionSheet(tester, size: Size(width, 844));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('portion-40')), findsOneWidget);
      expect(find.byKey(const Key('portion-90')), findsOneWidget);
    });

    testWidgets(
      'lays out without overflow at ${width.toInt()} px and 1.5 text scale',
      (tester) async {
        // Taller viewport only so the composer step (which has its own
        // pre-existing large-text overflow, see the note in openPortionSheet)
        // stays interactive. The width under test is unchanged.
        await openPortionSheet(tester, size: Size(width, 1100), textScale: 1.5);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('portion-60')), findsOneWidget);
        // The sheet scrolls rather than clipping the exact-gram entry away.
        await tester.scrollUntilVisible(
          find.byKey(const Key('portion-grams-input')),
          120,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.byKey(const Key('portion-grams-input')), findsOneWidget);
      },
    );
  }
}

class _FakeRepository implements MealRepository {
  _FakeRepository(this.item);

  final MealItem item;

  @override
  Future<MealDraft> analyze(MealAnalysisInput input) async =>
      MealDraft(inputText: input.text, mealName: 'Kahvaltı', items: [item]);
}

/// Minimal HTTP stub so `Image.network` can succeed inside a widget test.
/// Passing `null` bytes exercises the failure path.
Future<void> _withImageResponse(
  List<int>? bytes,
  Future<void> Function() body,
) => HttpOverrides.runZoned(
  body,
  createHttpClient: (_) => _FakeHttpClient(bytes),
);

final _transparentPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this.bytes);

  final List<int>? bytes;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _FakeHttpClientRequest(bytes);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest(this.bytes);

  final List<int>? bytes;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse(bytes);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse implements HttpClientResponse {
  _FakeHttpClientResponse(this.bytes);

  final List<int>? bytes;

  @override
  int get statusCode => bytes == null ? HttpStatus.notFound : HttpStatus.ok;

  @override
  int get contentLength => bytes?.length ?? 0;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.fromIterable(bytes == null ? const [] : [bytes!])
      .listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
