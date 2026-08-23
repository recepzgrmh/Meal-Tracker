import 'package:drift/drift.dart';

class LocalProfiles extends Table {
  TextColumn get userId => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get locale => text().withDefault(const Constant('tr-TR'))();
  TextColumn get timezone =>
      text().withDefault(const Constant('Europe/Istanbul'))();
  IntColumn get dailyCalorieTarget => integer().nullable()();
  TextColumn get primaryIntention => text().nullable()();
  IntColumn get onboardingVersion => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

class LocalMeals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get rawInput => text().nullable()();
  DateTimeColumn get eatenAt => dateTime()();
  TextColumn get imageAsset => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  IntColumn get rowVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get localUpdatedAt => dateTime()();
  DateTimeColumn get remoteUpdatedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {userId, id},
  ];
}

class LocalMealItems extends Table {
  TextColumn get id => text()();
  TextColumn get mealId =>
      text().references(LocalMeals, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text()();
  TextColumn get foodId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get sourceText => text()();
  TextColumn get portionLabel => text()();
  RealColumn get grams => real()();
  RealColumn get caloriesPer100g => real()();
  RealColumn get proteinPer100g => real()();
  RealColumn get carbsPer100g => real()();
  RealColumn get fatPer100g => real()();
  TextColumn get matchState => text()();
  TextColumn get sourceName => text()();

  /// How the item's nutrition was matched (`exact`, `llm`, `manual`,
  /// `ai_estimate`, ...). Nullable: rows written before schema v2 never
  /// recorded it, and "unknown" must stay distinct from any real method —
  /// `ai_estimate` in particular drives the persistent AI-estimate marker.
  TextColumn get matchMethod => text().nullable()();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncOperations extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operationType => text()();
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastErrorCode => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncCheckpoints extends Table {
  TextColumn get userId => text()();
  TextColumn get scope => text()();
  TextColumn get cursor => text().nullable()();
  DateTimeColumn get pulledAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId, scope};
}

class AppPreferences extends Table {
  TextColumn get userId => text()();
  TextColumn get key => text()();
  TextColumn get valueJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId, key};
}
