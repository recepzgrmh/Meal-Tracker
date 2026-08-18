import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/src/app.dart';
import 'package:meal_clarity/src/local/app_database.dart';
import 'package:meal_clarity/src/local/meal_dao.dart';
import 'package:meal_clarity/src/meals/data/cached_meal_repository.dart';
import 'package:meal_clarity/src/meals/data/meal_remote_data_source.dart';
import 'package:meal_clarity/src/meals/data/meal_remote_dto.dart';
import 'package:meal_clarity/src/theme/app_theme.dart';

void main() {
  testWidgets('logged meal is rendered from Drift and queued atomically', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = CachedMealRepository(
      local: MealDao(database),
      remote: _EmptyRemote(),
    );
    var syncRequests = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: MealClarityShell(
          cachedRepository: repository,
          userId: 'user-a',
          onSyncRequested: () async => syncRequests++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quick-composer')), findsOneWidget);
    final syncRequestsBeforeResume = syncRequests;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(syncRequests, syncRequestsBeforeResume + 1);

    await tester.tap(find.byKey(const Key('quick-composer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-meal-text')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('meal-input')),
      '2 yumurta, biraz beyaz peynir ve yarım simit',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('analyze-button')));
    await tester.tap(find.byKey(const Key('analyze-button')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-edit-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('portion-30')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-primary-button')));
    await tester.pumpAndSettle();

    final localMeals = await database.select(database.localMeals).get();
    final operations = await database.select(database.syncOperations).get();
    final items = await database.select(database.localMealItems).get();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Kahvaltı'), findsWidgets);
    expect(localMeals, hasLength(1));
    expect(items, hasLength(3));
    expect(operations, hasLength(1));
    expect(localMeals.single.syncStatus, 'pending');
    expect(items.every((item) => _isUuid(item.id)), isTrue);

    await tester.tap(find.text('Geçmiş'));
    await tester.pumpAndSettle();
    expect(find.text('Kahvaltı'), findsOneWidget);
    expect(find.textContaining('1 öğün ·'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });
}

class _EmptyRemote implements MealRemoteDataSource {
  @override
  Future<List<MealRemoteDto>> fetchWindow({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    return const [];
  }
}

bool _isUuid(String value) {
  return RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value);
}
