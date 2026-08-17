// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalProfilesTable extends LocalProfiles
    with TableInfo<$LocalProfilesTable, LocalProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
    'locale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('tr-TR'),
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Europe/Istanbul'),
  );
  static const VerificationMeta _dailyCalorieTargetMeta =
      const VerificationMeta('dailyCalorieTarget');
  @override
  late final GeneratedColumn<int> dailyCalorieTarget = GeneratedColumn<int>(
    'daily_calorie_target',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _primaryIntentionMeta = const VerificationMeta(
    'primaryIntention',
  );
  @override
  late final GeneratedColumn<String> primaryIntention = GeneratedColumn<String>(
    'primary_intention',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _onboardingVersionMeta = const VerificationMeta(
    'onboardingVersion',
  );
  @override
  late final GeneratedColumn<int> onboardingVersion = GeneratedColumn<int>(
    'onboarding_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    displayName,
    locale,
    timezone,
    dailyCalorieTarget,
    primaryIntention,
    onboardingVersion,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('locale')) {
      context.handle(
        _localeMeta,
        locale.isAcceptableOrUnknown(data['locale']!, _localeMeta),
      );
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    }
    if (data.containsKey('daily_calorie_target')) {
      context.handle(
        _dailyCalorieTargetMeta,
        dailyCalorieTarget.isAcceptableOrUnknown(
          data['daily_calorie_target']!,
          _dailyCalorieTargetMeta,
        ),
      );
    }
    if (data.containsKey('primary_intention')) {
      context.handle(
        _primaryIntentionMeta,
        primaryIntention.isAcceptableOrUnknown(
          data['primary_intention']!,
          _primaryIntentionMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_version')) {
      context.handle(
        _onboardingVersionMeta,
        onboardingVersion.isAcceptableOrUnknown(
          data['onboarding_version']!,
          _onboardingVersionMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  LocalProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProfile(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      locale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      dailyCalorieTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_calorie_target'],
      ),
      primaryIntention: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_intention'],
      ),
      onboardingVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}onboarding_version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalProfilesTable createAlias(String alias) {
    return $LocalProfilesTable(attachedDatabase, alias);
  }
}

class LocalProfile extends DataClass implements Insertable<LocalProfile> {
  final String userId;
  final String? displayName;
  final String locale;
  final String timezone;
  final int? dailyCalorieTarget;
  final String? primaryIntention;
  final int onboardingVersion;
  final DateTime updatedAt;
  const LocalProfile({
    required this.userId,
    this.displayName,
    required this.locale,
    required this.timezone,
    this.dailyCalorieTarget,
    this.primaryIntention,
    required this.onboardingVersion,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['locale'] = Variable<String>(locale);
    map['timezone'] = Variable<String>(timezone);
    if (!nullToAbsent || dailyCalorieTarget != null) {
      map['daily_calorie_target'] = Variable<int>(dailyCalorieTarget);
    }
    if (!nullToAbsent || primaryIntention != null) {
      map['primary_intention'] = Variable<String>(primaryIntention);
    }
    map['onboarding_version'] = Variable<int>(onboardingVersion);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalProfilesCompanion toCompanion(bool nullToAbsent) {
    return LocalProfilesCompanion(
      userId: Value(userId),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      locale: Value(locale),
      timezone: Value(timezone),
      dailyCalorieTarget: dailyCalorieTarget == null && nullToAbsent
          ? const Value.absent()
          : Value(dailyCalorieTarget),
      primaryIntention: primaryIntention == null && nullToAbsent
          ? const Value.absent()
          : Value(primaryIntention),
      onboardingVersion: Value(onboardingVersion),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProfile(
      userId: serializer.fromJson<String>(json['userId']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      locale: serializer.fromJson<String>(json['locale']),
      timezone: serializer.fromJson<String>(json['timezone']),
      dailyCalorieTarget: serializer.fromJson<int?>(json['dailyCalorieTarget']),
      primaryIntention: serializer.fromJson<String?>(json['primaryIntention']),
      onboardingVersion: serializer.fromJson<int>(json['onboardingVersion']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'displayName': serializer.toJson<String?>(displayName),
      'locale': serializer.toJson<String>(locale),
      'timezone': serializer.toJson<String>(timezone),
      'dailyCalorieTarget': serializer.toJson<int?>(dailyCalorieTarget),
      'primaryIntention': serializer.toJson<String?>(primaryIntention),
      'onboardingVersion': serializer.toJson<int>(onboardingVersion),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalProfile copyWith({
    String? userId,
    Value<String?> displayName = const Value.absent(),
    String? locale,
    String? timezone,
    Value<int?> dailyCalorieTarget = const Value.absent(),
    Value<String?> primaryIntention = const Value.absent(),
    int? onboardingVersion,
    DateTime? updatedAt,
  }) => LocalProfile(
    userId: userId ?? this.userId,
    displayName: displayName.present ? displayName.value : this.displayName,
    locale: locale ?? this.locale,
    timezone: timezone ?? this.timezone,
    dailyCalorieTarget: dailyCalorieTarget.present
        ? dailyCalorieTarget.value
        : this.dailyCalorieTarget,
    primaryIntention: primaryIntention.present
        ? primaryIntention.value
        : this.primaryIntention,
    onboardingVersion: onboardingVersion ?? this.onboardingVersion,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalProfile copyWithCompanion(LocalProfilesCompanion data) {
    return LocalProfile(
      userId: data.userId.present ? data.userId.value : this.userId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      locale: data.locale.present ? data.locale.value : this.locale,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      dailyCalorieTarget: data.dailyCalorieTarget.present
          ? data.dailyCalorieTarget.value
          : this.dailyCalorieTarget,
      primaryIntention: data.primaryIntention.present
          ? data.primaryIntention.value
          : this.primaryIntention,
      onboardingVersion: data.onboardingVersion.present
          ? data.onboardingVersion.value
          : this.onboardingVersion,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProfile(')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('locale: $locale, ')
          ..write('timezone: $timezone, ')
          ..write('dailyCalorieTarget: $dailyCalorieTarget, ')
          ..write('primaryIntention: $primaryIntention, ')
          ..write('onboardingVersion: $onboardingVersion, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    displayName,
    locale,
    timezone,
    dailyCalorieTarget,
    primaryIntention,
    onboardingVersion,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProfile &&
          other.userId == this.userId &&
          other.displayName == this.displayName &&
          other.locale == this.locale &&
          other.timezone == this.timezone &&
          other.dailyCalorieTarget == this.dailyCalorieTarget &&
          other.primaryIntention == this.primaryIntention &&
          other.onboardingVersion == this.onboardingVersion &&
          other.updatedAt == this.updatedAt);
}

class LocalProfilesCompanion extends UpdateCompanion<LocalProfile> {
  final Value<String> userId;
  final Value<String?> displayName;
  final Value<String> locale;
  final Value<String> timezone;
  final Value<int?> dailyCalorieTarget;
  final Value<String?> primaryIntention;
  final Value<int> onboardingVersion;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalProfilesCompanion({
    this.userId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.locale = const Value.absent(),
    this.timezone = const Value.absent(),
    this.dailyCalorieTarget = const Value.absent(),
    this.primaryIntention = const Value.absent(),
    this.onboardingVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProfilesCompanion.insert({
    required String userId,
    this.displayName = const Value.absent(),
    this.locale = const Value.absent(),
    this.timezone = const Value.absent(),
    this.dailyCalorieTarget = const Value.absent(),
    this.primaryIntention = const Value.absent(),
    this.onboardingVersion = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       updatedAt = Value(updatedAt);
  static Insertable<LocalProfile> custom({
    Expression<String>? userId,
    Expression<String>? displayName,
    Expression<String>? locale,
    Expression<String>? timezone,
    Expression<int>? dailyCalorieTarget,
    Expression<String>? primaryIntention,
    Expression<int>? onboardingVersion,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (displayName != null) 'display_name': displayName,
      if (locale != null) 'locale': locale,
      if (timezone != null) 'timezone': timezone,
      if (dailyCalorieTarget != null)
        'daily_calorie_target': dailyCalorieTarget,
      if (primaryIntention != null) 'primary_intention': primaryIntention,
      if (onboardingVersion != null) 'onboarding_version': onboardingVersion,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProfilesCompanion copyWith({
    Value<String>? userId,
    Value<String?>? displayName,
    Value<String>? locale,
    Value<String>? timezone,
    Value<int?>? dailyCalorieTarget,
    Value<String?>? primaryIntention,
    Value<int>? onboardingVersion,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalProfilesCompanion(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      locale: locale ?? this.locale,
      timezone: timezone ?? this.timezone,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      primaryIntention: primaryIntention ?? this.primaryIntention,
      onboardingVersion: onboardingVersion ?? this.onboardingVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (dailyCalorieTarget.present) {
      map['daily_calorie_target'] = Variable<int>(dailyCalorieTarget.value);
    }
    if (primaryIntention.present) {
      map['primary_intention'] = Variable<String>(primaryIntention.value);
    }
    if (onboardingVersion.present) {
      map['onboarding_version'] = Variable<int>(onboardingVersion.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProfilesCompanion(')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('locale: $locale, ')
          ..write('timezone: $timezone, ')
          ..write('dailyCalorieTarget: $dailyCalorieTarget, ')
          ..write('primaryIntention: $primaryIntention, ')
          ..write('onboardingVersion: $onboardingVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMealsTable extends LocalMeals
    with TableInfo<$LocalMealsTable, LocalMeal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMealsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawInputMeta = const VerificationMeta(
    'rawInput',
  );
  @override
  late final GeneratedColumn<String> rawInput = GeneratedColumn<String>(
    'raw_input',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eatenAtMeta = const VerificationMeta(
    'eatenAt',
  );
  @override
  late final GeneratedColumn<DateTime> eatenAt = GeneratedColumn<DateTime>(
    'eaten_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageAssetMeta = const VerificationMeta(
    'imageAsset',
  );
  @override
  late final GeneratedColumn<String> imageAsset = GeneratedColumn<String>(
    'image_asset',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _rowVersionMeta = const VerificationMeta(
    'rowVersion',
  );
  @override
  late final GeneratedColumn<int> rowVersion = GeneratedColumn<int>(
    'row_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _remoteUpdatedAtMeta = const VerificationMeta(
    'remoteUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> remoteUpdatedAt =
      GeneratedColumn<DateTime>(
        'remote_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    rawInput,
    eatenAt,
    imageAsset,
    syncStatus,
    rowVersion,
    localUpdatedAt,
    remoteUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_meals';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMeal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('raw_input')) {
      context.handle(
        _rawInputMeta,
        rawInput.isAcceptableOrUnknown(data['raw_input']!, _rawInputMeta),
      );
    }
    if (data.containsKey('eaten_at')) {
      context.handle(
        _eatenAtMeta,
        eatenAt.isAcceptableOrUnknown(data['eaten_at']!, _eatenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_eatenAtMeta);
    }
    if (data.containsKey('image_asset')) {
      context.handle(
        _imageAssetMeta,
        imageAsset.isAcceptableOrUnknown(data['image_asset']!, _imageAssetMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('row_version')) {
      context.handle(
        _rowVersionMeta,
        rowVersion.isAcceptableOrUnknown(data['row_version']!, _rowVersionMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    if (data.containsKey('remote_updated_at')) {
      context.handle(
        _remoteUpdatedAtMeta,
        remoteUpdatedAt.isAcceptableOrUnknown(
          data['remote_updated_at']!,
          _remoteUpdatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {userId, id},
  ];
  @override
  LocalMeal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMeal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      rawInput: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_input'],
      ),
      eatenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}eaten_at'],
      )!,
      imageAsset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_asset'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      rowVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_version'],
      )!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
      remoteUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}remote_updated_at'],
      ),
    );
  }

  @override
  $LocalMealsTable createAlias(String alias) {
    return $LocalMealsTable(attachedDatabase, alias);
  }
}

class LocalMeal extends DataClass implements Insertable<LocalMeal> {
  final String id;
  final String userId;
  final String name;
  final String? rawInput;
  final DateTime eatenAt;
  final String? imageAsset;
  final String syncStatus;
  final int rowVersion;
  final DateTime localUpdatedAt;
  final DateTime? remoteUpdatedAt;
  const LocalMeal({
    required this.id,
    required this.userId,
    required this.name,
    this.rawInput,
    required this.eatenAt,
    this.imageAsset,
    required this.syncStatus,
    required this.rowVersion,
    required this.localUpdatedAt,
    this.remoteUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || rawInput != null) {
      map['raw_input'] = Variable<String>(rawInput);
    }
    map['eaten_at'] = Variable<DateTime>(eatenAt);
    if (!nullToAbsent || imageAsset != null) {
      map['image_asset'] = Variable<String>(imageAsset);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['row_version'] = Variable<int>(rowVersion);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    if (!nullToAbsent || remoteUpdatedAt != null) {
      map['remote_updated_at'] = Variable<DateTime>(remoteUpdatedAt);
    }
    return map;
  }

  LocalMealsCompanion toCompanion(bool nullToAbsent) {
    return LocalMealsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      rawInput: rawInput == null && nullToAbsent
          ? const Value.absent()
          : Value(rawInput),
      eatenAt: Value(eatenAt),
      imageAsset: imageAsset == null && nullToAbsent
          ? const Value.absent()
          : Value(imageAsset),
      syncStatus: Value(syncStatus),
      rowVersion: Value(rowVersion),
      localUpdatedAt: Value(localUpdatedAt),
      remoteUpdatedAt: remoteUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUpdatedAt),
    );
  }

  factory LocalMeal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMeal(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      rawInput: serializer.fromJson<String?>(json['rawInput']),
      eatenAt: serializer.fromJson<DateTime>(json['eatenAt']),
      imageAsset: serializer.fromJson<String?>(json['imageAsset']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      rowVersion: serializer.fromJson<int>(json['rowVersion']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      remoteUpdatedAt: serializer.fromJson<DateTime?>(json['remoteUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'rawInput': serializer.toJson<String?>(rawInput),
      'eatenAt': serializer.toJson<DateTime>(eatenAt),
      'imageAsset': serializer.toJson<String?>(imageAsset),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'rowVersion': serializer.toJson<int>(rowVersion),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'remoteUpdatedAt': serializer.toJson<DateTime?>(remoteUpdatedAt),
    };
  }

  LocalMeal copyWith({
    String? id,
    String? userId,
    String? name,
    Value<String?> rawInput = const Value.absent(),
    DateTime? eatenAt,
    Value<String?> imageAsset = const Value.absent(),
    String? syncStatus,
    int? rowVersion,
    DateTime? localUpdatedAt,
    Value<DateTime?> remoteUpdatedAt = const Value.absent(),
  }) => LocalMeal(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    rawInput: rawInput.present ? rawInput.value : this.rawInput,
    eatenAt: eatenAt ?? this.eatenAt,
    imageAsset: imageAsset.present ? imageAsset.value : this.imageAsset,
    syncStatus: syncStatus ?? this.syncStatus,
    rowVersion: rowVersion ?? this.rowVersion,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    remoteUpdatedAt: remoteUpdatedAt.present
        ? remoteUpdatedAt.value
        : this.remoteUpdatedAt,
  );
  LocalMeal copyWithCompanion(LocalMealsCompanion data) {
    return LocalMeal(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      rawInput: data.rawInput.present ? data.rawInput.value : this.rawInput,
      eatenAt: data.eatenAt.present ? data.eatenAt.value : this.eatenAt,
      imageAsset: data.imageAsset.present
          ? data.imageAsset.value
          : this.imageAsset,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      rowVersion: data.rowVersion.present
          ? data.rowVersion.value
          : this.rowVersion,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      remoteUpdatedAt: data.remoteUpdatedAt.present
          ? data.remoteUpdatedAt.value
          : this.remoteUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMeal(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('rawInput: $rawInput, ')
          ..write('eatenAt: $eatenAt, ')
          ..write('imageAsset: $imageAsset, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    rawInput,
    eatenAt,
    imageAsset,
    syncStatus,
    rowVersion,
    localUpdatedAt,
    remoteUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMeal &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.rawInput == this.rawInput &&
          other.eatenAt == this.eatenAt &&
          other.imageAsset == this.imageAsset &&
          other.syncStatus == this.syncStatus &&
          other.rowVersion == this.rowVersion &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.remoteUpdatedAt == this.remoteUpdatedAt);
}

class LocalMealsCompanion extends UpdateCompanion<LocalMeal> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String?> rawInput;
  final Value<DateTime> eatenAt;
  final Value<String?> imageAsset;
  final Value<String> syncStatus;
  final Value<int> rowVersion;
  final Value<DateTime> localUpdatedAt;
  final Value<DateTime?> remoteUpdatedAt;
  final Value<int> rowid;
  const LocalMealsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.rawInput = const Value.absent(),
    this.eatenAt = const Value.absent(),
    this.imageAsset = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowVersion = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMealsCompanion.insert({
    required String id,
    required String userId,
    required String name,
    this.rawInput = const Value.absent(),
    required DateTime eatenAt,
    this.imageAsset = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowVersion = const Value.absent(),
    required DateTime localUpdatedAt,
    this.remoteUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       name = Value(name),
       eatenAt = Value(eatenAt),
       localUpdatedAt = Value(localUpdatedAt);
  static Insertable<LocalMeal> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? rawInput,
    Expression<DateTime>? eatenAt,
    Expression<String>? imageAsset,
    Expression<String>? syncStatus,
    Expression<int>? rowVersion,
    Expression<DateTime>? localUpdatedAt,
    Expression<DateTime>? remoteUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (rawInput != null) 'raw_input': rawInput,
      if (eatenAt != null) 'eaten_at': eatenAt,
      if (imageAsset != null) 'image_asset': imageAsset,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowVersion != null) 'row_version': rowVersion,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (remoteUpdatedAt != null) 'remote_updated_at': remoteUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMealsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<String?>? rawInput,
    Value<DateTime>? eatenAt,
    Value<String?>? imageAsset,
    Value<String>? syncStatus,
    Value<int>? rowVersion,
    Value<DateTime>? localUpdatedAt,
    Value<DateTime?>? remoteUpdatedAt,
    Value<int>? rowid,
  }) {
    return LocalMealsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      rawInput: rawInput ?? this.rawInput,
      eatenAt: eatenAt ?? this.eatenAt,
      imageAsset: imageAsset ?? this.imageAsset,
      syncStatus: syncStatus ?? this.syncStatus,
      rowVersion: rowVersion ?? this.rowVersion,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rawInput.present) {
      map['raw_input'] = Variable<String>(rawInput.value);
    }
    if (eatenAt.present) {
      map['eaten_at'] = Variable<DateTime>(eatenAt.value);
    }
    if (imageAsset.present) {
      map['image_asset'] = Variable<String>(imageAsset.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowVersion.present) {
      map['row_version'] = Variable<int>(rowVersion.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (remoteUpdatedAt.present) {
      map['remote_updated_at'] = Variable<DateTime>(remoteUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMealsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('rawInput: $rawInput, ')
          ..write('eatenAt: $eatenAt, ')
          ..write('imageAsset: $imageAsset, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowVersion: $rowVersion, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMealItemsTable extends LocalMealItems
    with TableInfo<$LocalMealItemsTable, LocalMealItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMealItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<String> mealId = GeneratedColumn<String>(
    'meal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_meals (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
    'food_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTextMeta = const VerificationMeta(
    'sourceText',
  );
  @override
  late final GeneratedColumn<String> sourceText = GeneratedColumn<String>(
    'source_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portionLabelMeta = const VerificationMeta(
    'portionLabel',
  );
  @override
  late final GeneratedColumn<String> portionLabel = GeneratedColumn<String>(
    'portion_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caloriesPer100gMeta = const VerificationMeta(
    'caloriesPer100g',
  );
  @override
  late final GeneratedColumn<double> caloriesPer100g = GeneratedColumn<double>(
    'calories_per100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinPer100gMeta = const VerificationMeta(
    'proteinPer100g',
  );
  @override
  late final GeneratedColumn<double> proteinPer100g = GeneratedColumn<double>(
    'protein_per100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsPer100gMeta = const VerificationMeta(
    'carbsPer100g',
  );
  @override
  late final GeneratedColumn<double> carbsPer100g = GeneratedColumn<double>(
    'carbs_per100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatPer100gMeta = const VerificationMeta(
    'fatPer100g',
  );
  @override
  late final GeneratedColumn<double> fatPer100g = GeneratedColumn<double>(
    'fat_per100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchStateMeta = const VerificationMeta(
    'matchState',
  );
  @override
  late final GeneratedColumn<String> matchState = GeneratedColumn<String>(
    'match_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNameMeta = const VerificationMeta(
    'sourceName',
  );
  @override
  late final GeneratedColumn<String> sourceName = GeneratedColumn<String>(
    'source_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mealId,
    userId,
    foodId,
    name,
    sourceText,
    portionLabel,
    grams,
    caloriesPer100g,
    proteinPer100g,
    carbsPer100g,
    fatPer100g,
    matchState,
    sourceName,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_meal_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMealItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('meal_id')) {
      context.handle(
        _mealIdMeta,
        mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source_text')) {
      context.handle(
        _sourceTextMeta,
        sourceText.isAcceptableOrUnknown(data['source_text']!, _sourceTextMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTextMeta);
    }
    if (data.containsKey('portion_label')) {
      context.handle(
        _portionLabelMeta,
        portionLabel.isAcceptableOrUnknown(
          data['portion_label']!,
          _portionLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_portionLabelMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('calories_per100g')) {
      context.handle(
        _caloriesPer100gMeta,
        caloriesPer100g.isAcceptableOrUnknown(
          data['calories_per100g']!,
          _caloriesPer100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caloriesPer100gMeta);
    }
    if (data.containsKey('protein_per100g')) {
      context.handle(
        _proteinPer100gMeta,
        proteinPer100g.isAcceptableOrUnknown(
          data['protein_per100g']!,
          _proteinPer100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proteinPer100gMeta);
    }
    if (data.containsKey('carbs_per100g')) {
      context.handle(
        _carbsPer100gMeta,
        carbsPer100g.isAcceptableOrUnknown(
          data['carbs_per100g']!,
          _carbsPer100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_carbsPer100gMeta);
    }
    if (data.containsKey('fat_per100g')) {
      context.handle(
        _fatPer100gMeta,
        fatPer100g.isAcceptableOrUnknown(data['fat_per100g']!, _fatPer100gMeta),
      );
    } else if (isInserting) {
      context.missing(_fatPer100gMeta);
    }
    if (data.containsKey('match_state')) {
      context.handle(
        _matchStateMeta,
        matchState.isAcceptableOrUnknown(data['match_state']!, _matchStateMeta),
      );
    } else if (isInserting) {
      context.missing(_matchStateMeta);
    }
    if (data.containsKey('source_name')) {
      context.handle(
        _sourceNameMeta,
        sourceName.isAcceptableOrUnknown(data['source_name']!, _sourceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceNameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMealItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMealItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mealId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sourceText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_text'],
      )!,
      portionLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}portion_label'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      caloriesPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calories_per100g'],
      )!,
      proteinPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_per100g'],
      )!,
      carbsPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_per100g'],
      )!,
      fatPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_per100g'],
      )!,
      matchState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_state'],
      )!,
      sourceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $LocalMealItemsTable createAlias(String alias) {
    return $LocalMealItemsTable(attachedDatabase, alias);
  }
}

class LocalMealItem extends DataClass implements Insertable<LocalMealItem> {
  final String id;
  final String mealId;
  final String userId;
  final String? foodId;
  final String name;
  final String sourceText;
  final String portionLabel;
  final double grams;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final String matchState;
  final String sourceName;
  final int position;
  const LocalMealItem({
    required this.id,
    required this.mealId,
    required this.userId,
    this.foodId,
    required this.name,
    required this.sourceText,
    required this.portionLabel,
    required this.grams,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.matchState,
    required this.sourceName,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['meal_id'] = Variable<String>(mealId);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || foodId != null) {
      map['food_id'] = Variable<String>(foodId);
    }
    map['name'] = Variable<String>(name);
    map['source_text'] = Variable<String>(sourceText);
    map['portion_label'] = Variable<String>(portionLabel);
    map['grams'] = Variable<double>(grams);
    map['calories_per100g'] = Variable<double>(caloriesPer100g);
    map['protein_per100g'] = Variable<double>(proteinPer100g);
    map['carbs_per100g'] = Variable<double>(carbsPer100g);
    map['fat_per100g'] = Variable<double>(fatPer100g);
    map['match_state'] = Variable<String>(matchState);
    map['source_name'] = Variable<String>(sourceName);
    map['position'] = Variable<int>(position);
    return map;
  }

  LocalMealItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalMealItemsCompanion(
      id: Value(id),
      mealId: Value(mealId),
      userId: Value(userId),
      foodId: foodId == null && nullToAbsent
          ? const Value.absent()
          : Value(foodId),
      name: Value(name),
      sourceText: Value(sourceText),
      portionLabel: Value(portionLabel),
      grams: Value(grams),
      caloriesPer100g: Value(caloriesPer100g),
      proteinPer100g: Value(proteinPer100g),
      carbsPer100g: Value(carbsPer100g),
      fatPer100g: Value(fatPer100g),
      matchState: Value(matchState),
      sourceName: Value(sourceName),
      position: Value(position),
    );
  }

  factory LocalMealItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMealItem(
      id: serializer.fromJson<String>(json['id']),
      mealId: serializer.fromJson<String>(json['mealId']),
      userId: serializer.fromJson<String>(json['userId']),
      foodId: serializer.fromJson<String?>(json['foodId']),
      name: serializer.fromJson<String>(json['name']),
      sourceText: serializer.fromJson<String>(json['sourceText']),
      portionLabel: serializer.fromJson<String>(json['portionLabel']),
      grams: serializer.fromJson<double>(json['grams']),
      caloriesPer100g: serializer.fromJson<double>(json['caloriesPer100g']),
      proteinPer100g: serializer.fromJson<double>(json['proteinPer100g']),
      carbsPer100g: serializer.fromJson<double>(json['carbsPer100g']),
      fatPer100g: serializer.fromJson<double>(json['fatPer100g']),
      matchState: serializer.fromJson<String>(json['matchState']),
      sourceName: serializer.fromJson<String>(json['sourceName']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mealId': serializer.toJson<String>(mealId),
      'userId': serializer.toJson<String>(userId),
      'foodId': serializer.toJson<String?>(foodId),
      'name': serializer.toJson<String>(name),
      'sourceText': serializer.toJson<String>(sourceText),
      'portionLabel': serializer.toJson<String>(portionLabel),
      'grams': serializer.toJson<double>(grams),
      'caloriesPer100g': serializer.toJson<double>(caloriesPer100g),
      'proteinPer100g': serializer.toJson<double>(proteinPer100g),
      'carbsPer100g': serializer.toJson<double>(carbsPer100g),
      'fatPer100g': serializer.toJson<double>(fatPer100g),
      'matchState': serializer.toJson<String>(matchState),
      'sourceName': serializer.toJson<String>(sourceName),
      'position': serializer.toJson<int>(position),
    };
  }

  LocalMealItem copyWith({
    String? id,
    String? mealId,
    String? userId,
    Value<String?> foodId = const Value.absent(),
    String? name,
    String? sourceText,
    String? portionLabel,
    double? grams,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
    String? matchState,
    String? sourceName,
    int? position,
  }) => LocalMealItem(
    id: id ?? this.id,
    mealId: mealId ?? this.mealId,
    userId: userId ?? this.userId,
    foodId: foodId.present ? foodId.value : this.foodId,
    name: name ?? this.name,
    sourceText: sourceText ?? this.sourceText,
    portionLabel: portionLabel ?? this.portionLabel,
    grams: grams ?? this.grams,
    caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
    proteinPer100g: proteinPer100g ?? this.proteinPer100g,
    carbsPer100g: carbsPer100g ?? this.carbsPer100g,
    fatPer100g: fatPer100g ?? this.fatPer100g,
    matchState: matchState ?? this.matchState,
    sourceName: sourceName ?? this.sourceName,
    position: position ?? this.position,
  );
  LocalMealItem copyWithCompanion(LocalMealItemsCompanion data) {
    return LocalMealItem(
      id: data.id.present ? data.id.value : this.id,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      userId: data.userId.present ? data.userId.value : this.userId,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      name: data.name.present ? data.name.value : this.name,
      sourceText: data.sourceText.present
          ? data.sourceText.value
          : this.sourceText,
      portionLabel: data.portionLabel.present
          ? data.portionLabel.value
          : this.portionLabel,
      grams: data.grams.present ? data.grams.value : this.grams,
      caloriesPer100g: data.caloriesPer100g.present
          ? data.caloriesPer100g.value
          : this.caloriesPer100g,
      proteinPer100g: data.proteinPer100g.present
          ? data.proteinPer100g.value
          : this.proteinPer100g,
      carbsPer100g: data.carbsPer100g.present
          ? data.carbsPer100g.value
          : this.carbsPer100g,
      fatPer100g: data.fatPer100g.present
          ? data.fatPer100g.value
          : this.fatPer100g,
      matchState: data.matchState.present
          ? data.matchState.value
          : this.matchState,
      sourceName: data.sourceName.present
          ? data.sourceName.value
          : this.sourceName,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMealItem(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('userId: $userId, ')
          ..write('foodId: $foodId, ')
          ..write('name: $name, ')
          ..write('sourceText: $sourceText, ')
          ..write('portionLabel: $portionLabel, ')
          ..write('grams: $grams, ')
          ..write('caloriesPer100g: $caloriesPer100g, ')
          ..write('proteinPer100g: $proteinPer100g, ')
          ..write('carbsPer100g: $carbsPer100g, ')
          ..write('fatPer100g: $fatPer100g, ')
          ..write('matchState: $matchState, ')
          ..write('sourceName: $sourceName, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mealId,
    userId,
    foodId,
    name,
    sourceText,
    portionLabel,
    grams,
    caloriesPer100g,
    proteinPer100g,
    carbsPer100g,
    fatPer100g,
    matchState,
    sourceName,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMealItem &&
          other.id == this.id &&
          other.mealId == this.mealId &&
          other.userId == this.userId &&
          other.foodId == this.foodId &&
          other.name == this.name &&
          other.sourceText == this.sourceText &&
          other.portionLabel == this.portionLabel &&
          other.grams == this.grams &&
          other.caloriesPer100g == this.caloriesPer100g &&
          other.proteinPer100g == this.proteinPer100g &&
          other.carbsPer100g == this.carbsPer100g &&
          other.fatPer100g == this.fatPer100g &&
          other.matchState == this.matchState &&
          other.sourceName == this.sourceName &&
          other.position == this.position);
}

class LocalMealItemsCompanion extends UpdateCompanion<LocalMealItem> {
  final Value<String> id;
  final Value<String> mealId;
  final Value<String> userId;
  final Value<String?> foodId;
  final Value<String> name;
  final Value<String> sourceText;
  final Value<String> portionLabel;
  final Value<double> grams;
  final Value<double> caloriesPer100g;
  final Value<double> proteinPer100g;
  final Value<double> carbsPer100g;
  final Value<double> fatPer100g;
  final Value<String> matchState;
  final Value<String> sourceName;
  final Value<int> position;
  final Value<int> rowid;
  const LocalMealItemsCompanion({
    this.id = const Value.absent(),
    this.mealId = const Value.absent(),
    this.userId = const Value.absent(),
    this.foodId = const Value.absent(),
    this.name = const Value.absent(),
    this.sourceText = const Value.absent(),
    this.portionLabel = const Value.absent(),
    this.grams = const Value.absent(),
    this.caloriesPer100g = const Value.absent(),
    this.proteinPer100g = const Value.absent(),
    this.carbsPer100g = const Value.absent(),
    this.fatPer100g = const Value.absent(),
    this.matchState = const Value.absent(),
    this.sourceName = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMealItemsCompanion.insert({
    required String id,
    required String mealId,
    required String userId,
    this.foodId = const Value.absent(),
    required String name,
    required String sourceText,
    required String portionLabel,
    required double grams,
    required double caloriesPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
    required String matchState,
    required String sourceName,
    required int position,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mealId = Value(mealId),
       userId = Value(userId),
       name = Value(name),
       sourceText = Value(sourceText),
       portionLabel = Value(portionLabel),
       grams = Value(grams),
       caloriesPer100g = Value(caloriesPer100g),
       proteinPer100g = Value(proteinPer100g),
       carbsPer100g = Value(carbsPer100g),
       fatPer100g = Value(fatPer100g),
       matchState = Value(matchState),
       sourceName = Value(sourceName),
       position = Value(position);
  static Insertable<LocalMealItem> custom({
    Expression<String>? id,
    Expression<String>? mealId,
    Expression<String>? userId,
    Expression<String>? foodId,
    Expression<String>? name,
    Expression<String>? sourceText,
    Expression<String>? portionLabel,
    Expression<double>? grams,
    Expression<double>? caloriesPer100g,
    Expression<double>? proteinPer100g,
    Expression<double>? carbsPer100g,
    Expression<double>? fatPer100g,
    Expression<String>? matchState,
    Expression<String>? sourceName,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mealId != null) 'meal_id': mealId,
      if (userId != null) 'user_id': userId,
      if (foodId != null) 'food_id': foodId,
      if (name != null) 'name': name,
      if (sourceText != null) 'source_text': sourceText,
      if (portionLabel != null) 'portion_label': portionLabel,
      if (grams != null) 'grams': grams,
      if (caloriesPer100g != null) 'calories_per100g': caloriesPer100g,
      if (proteinPer100g != null) 'protein_per100g': proteinPer100g,
      if (carbsPer100g != null) 'carbs_per100g': carbsPer100g,
      if (fatPer100g != null) 'fat_per100g': fatPer100g,
      if (matchState != null) 'match_state': matchState,
      if (sourceName != null) 'source_name': sourceName,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMealItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? mealId,
    Value<String>? userId,
    Value<String?>? foodId,
    Value<String>? name,
    Value<String>? sourceText,
    Value<String>? portionLabel,
    Value<double>? grams,
    Value<double>? caloriesPer100g,
    Value<double>? proteinPer100g,
    Value<double>? carbsPer100g,
    Value<double>? fatPer100g,
    Value<String>? matchState,
    Value<String>? sourceName,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return LocalMealItemsCompanion(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      userId: userId ?? this.userId,
      foodId: foodId ?? this.foodId,
      name: name ?? this.name,
      sourceText: sourceText ?? this.sourceText,
      portionLabel: portionLabel ?? this.portionLabel,
      grams: grams ?? this.grams,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      matchState: matchState ?? this.matchState,
      sourceName: sourceName ?? this.sourceName,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<String>(mealId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sourceText.present) {
      map['source_text'] = Variable<String>(sourceText.value);
    }
    if (portionLabel.present) {
      map['portion_label'] = Variable<String>(portionLabel.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (caloriesPer100g.present) {
      map['calories_per100g'] = Variable<double>(caloriesPer100g.value);
    }
    if (proteinPer100g.present) {
      map['protein_per100g'] = Variable<double>(proteinPer100g.value);
    }
    if (carbsPer100g.present) {
      map['carbs_per100g'] = Variable<double>(carbsPer100g.value);
    }
    if (fatPer100g.present) {
      map['fat_per100g'] = Variable<double>(fatPer100g.value);
    }
    if (matchState.present) {
      map['match_state'] = Variable<String>(matchState.value);
    }
    if (sourceName.present) {
      map['source_name'] = Variable<String>(sourceName.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMealItemsCompanion(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('userId: $userId, ')
          ..write('foodId: $foodId, ')
          ..write('name: $name, ')
          ..write('sourceText: $sourceText, ')
          ..write('portionLabel: $portionLabel, ')
          ..write('grams: $grams, ')
          ..write('caloriesPer100g: $caloriesPer100g, ')
          ..write('proteinPer100g: $proteinPer100g, ')
          ..write('carbsPer100g: $carbsPer100g, ')
          ..write('fatPer100g: $fatPer100g, ')
          ..write('matchState: $matchState, ')
          ..write('sourceName: $sourceName, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOperationsTable extends SyncOperations
    with TableInfo<$SyncOperationsTable, SyncOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    entityType,
    entityId,
    operationType,
    payloadJson,
    status,
    attemptCount,
    nextAttemptAt,
    lastErrorCode,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOperation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOperation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncOperationsTable createAlias(String alias) {
    return $SyncOperationsTable(attachedDatabase, alias);
  }
}

class SyncOperation extends DataClass implements Insertable<SyncOperation> {
  final String id;
  final String userId;
  final String entityType;
  final String entityId;
  final String operationType;
  final String payloadJson;
  final String status;
  final int attemptCount;
  final DateTime? nextAttemptAt;
  final String? lastErrorCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SyncOperation({
    required this.id,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.payloadJson,
    required this.status,
    required this.attemptCount,
    this.nextAttemptAt,
    this.lastErrorCode,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation_type'] = Variable<String>(operationType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncOperationsCompanion toCompanion(bool nullToAbsent) {
    return SyncOperationsCompanion(
      id: Value(id),
      userId: Value(userId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operationType: Value(operationType),
      payloadJson: Value(payloadJson),
      status: Value(status),
      attemptCount: Value(attemptCount),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncOperation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOperation(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operationType: serializer.fromJson<String>(json['operationType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operationType': serializer.toJson<String>(operationType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncOperation copyWith({
    String? id,
    String? userId,
    String? entityType,
    String? entityId,
    String? operationType,
    String? payloadJson,
    String? status,
    int? attemptCount,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> lastErrorCode = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SyncOperation(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operationType: operationType ?? this.operationType,
    payloadJson: payloadJson ?? this.payloadJson,
    status: status ?? this.status,
    attemptCount: attemptCount ?? this.attemptCount,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncOperation copyWithCompanion(SyncOperationsCompanion data) {
    return SyncOperation(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOperation(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    entityType,
    entityId,
    operationType,
    payloadJson,
    status,
    attemptCount,
    nextAttemptAt,
    lastErrorCode,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOperation &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operationType == this.operationType &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastErrorCode == this.lastErrorCode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SyncOperationsCompanion extends UpdateCompanion<SyncOperation> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operationType;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> lastErrorCode;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncOperationsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operationType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOperationsCompanion.insert({
    required String id,
    required String userId,
    required String entityType,
    required String entityId,
    required String operationType,
    required String payloadJson,
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       operationType = Value(operationType),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SyncOperation> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operationType,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastErrorCode,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operationType != null) 'operation_type': operationType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOperationsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? operationType,
    Value<String>? payloadJson,
    Value<String>? status,
    Value<int>? attemptCount,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? lastErrorCode,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncOperationsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operationType: operationType ?? this.operationType,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOperationsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncCheckpointsTable extends SyncCheckpoints
    with TableInfo<$SyncCheckpointsTable, SyncCheckpoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCheckpointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pulledAtMeta = const VerificationMeta(
    'pulledAt',
  );
  @override
  late final GeneratedColumn<DateTime> pulledAt = GeneratedColumn<DateTime>(
    'pulled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [userId, scope, cursor, pulledAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_checkpoints';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCheckpoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    if (data.containsKey('pulled_at')) {
      context.handle(
        _pulledAtMeta,
        pulledAt.isAcceptableOrUnknown(data['pulled_at']!, _pulledAtMeta),
      );
    } else if (isInserting) {
      context.missing(_pulledAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, scope};
  @override
  SyncCheckpoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCheckpoint(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      ),
      pulledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pulled_at'],
      )!,
    );
  }

  @override
  $SyncCheckpointsTable createAlias(String alias) {
    return $SyncCheckpointsTable(attachedDatabase, alias);
  }
}

class SyncCheckpoint extends DataClass implements Insertable<SyncCheckpoint> {
  final String userId;
  final String scope;
  final String? cursor;
  final DateTime pulledAt;
  const SyncCheckpoint({
    required this.userId,
    required this.scope,
    this.cursor,
    required this.pulledAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || cursor != null) {
      map['cursor'] = Variable<String>(cursor);
    }
    map['pulled_at'] = Variable<DateTime>(pulledAt);
    return map;
  }

  SyncCheckpointsCompanion toCompanion(bool nullToAbsent) {
    return SyncCheckpointsCompanion(
      userId: Value(userId),
      scope: Value(scope),
      cursor: cursor == null && nullToAbsent
          ? const Value.absent()
          : Value(cursor),
      pulledAt: Value(pulledAt),
    );
  }

  factory SyncCheckpoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCheckpoint(
      userId: serializer.fromJson<String>(json['userId']),
      scope: serializer.fromJson<String>(json['scope']),
      cursor: serializer.fromJson<String?>(json['cursor']),
      pulledAt: serializer.fromJson<DateTime>(json['pulledAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'scope': serializer.toJson<String>(scope),
      'cursor': serializer.toJson<String?>(cursor),
      'pulledAt': serializer.toJson<DateTime>(pulledAt),
    };
  }

  SyncCheckpoint copyWith({
    String? userId,
    String? scope,
    Value<String?> cursor = const Value.absent(),
    DateTime? pulledAt,
  }) => SyncCheckpoint(
    userId: userId ?? this.userId,
    scope: scope ?? this.scope,
    cursor: cursor.present ? cursor.value : this.cursor,
    pulledAt: pulledAt ?? this.pulledAt,
  );
  SyncCheckpoint copyWithCompanion(SyncCheckpointsCompanion data) {
    return SyncCheckpoint(
      userId: data.userId.present ? data.userId.value : this.userId,
      scope: data.scope.present ? data.scope.value : this.scope,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      pulledAt: data.pulledAt.present ? data.pulledAt.value : this.pulledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCheckpoint(')
          ..write('userId: $userId, ')
          ..write('scope: $scope, ')
          ..write('cursor: $cursor, ')
          ..write('pulledAt: $pulledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, scope, cursor, pulledAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCheckpoint &&
          other.userId == this.userId &&
          other.scope == this.scope &&
          other.cursor == this.cursor &&
          other.pulledAt == this.pulledAt);
}

class SyncCheckpointsCompanion extends UpdateCompanion<SyncCheckpoint> {
  final Value<String> userId;
  final Value<String> scope;
  final Value<String?> cursor;
  final Value<DateTime> pulledAt;
  final Value<int> rowid;
  const SyncCheckpointsCompanion({
    this.userId = const Value.absent(),
    this.scope = const Value.absent(),
    this.cursor = const Value.absent(),
    this.pulledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCheckpointsCompanion.insert({
    required String userId,
    required String scope,
    this.cursor = const Value.absent(),
    required DateTime pulledAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       scope = Value(scope),
       pulledAt = Value(pulledAt);
  static Insertable<SyncCheckpoint> custom({
    Expression<String>? userId,
    Expression<String>? scope,
    Expression<String>? cursor,
    Expression<DateTime>? pulledAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (scope != null) 'scope': scope,
      if (cursor != null) 'cursor': cursor,
      if (pulledAt != null) 'pulled_at': pulledAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCheckpointsCompanion copyWith({
    Value<String>? userId,
    Value<String>? scope,
    Value<String?>? cursor,
    Value<DateTime>? pulledAt,
    Value<int>? rowid,
  }) {
    return SyncCheckpointsCompanion(
      userId: userId ?? this.userId,
      scope: scope ?? this.scope,
      cursor: cursor ?? this.cursor,
      pulledAt: pulledAt ?? this.pulledAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (pulledAt.present) {
      map['pulled_at'] = Variable<DateTime>(pulledAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCheckpointsCompanion(')
          ..write('userId: $userId, ')
          ..write('scope: $scope, ')
          ..write('cursor: $cursor, ')
          ..write('pulledAt: $pulledAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppPreferencesTable extends AppPreferences
    with TableInfo<$AppPreferencesTable, AppPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [userId, key, valueJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, key};
  @override
  AppPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppPreference(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppPreferencesTable createAlias(String alias) {
    return $AppPreferencesTable(attachedDatabase, alias);
  }
}

class AppPreference extends DataClass implements Insertable<AppPreference> {
  final String userId;
  final String key;
  final String valueJson;
  final DateTime updatedAt;
  const AppPreference({
    required this.userId,
    required this.key,
    required this.valueJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['key'] = Variable<String>(key);
    map['value_json'] = Variable<String>(valueJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppPreferencesCompanion toCompanion(bool nullToAbsent) {
    return AppPreferencesCompanion(
      userId: Value(userId),
      key: Value(key),
      valueJson: Value(valueJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppPreference(
      userId: serializer.fromJson<String>(json['userId']),
      key: serializer.fromJson<String>(json['key']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'key': serializer.toJson<String>(key),
      'valueJson': serializer.toJson<String>(valueJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppPreference copyWith({
    String? userId,
    String? key,
    String? valueJson,
    DateTime? updatedAt,
  }) => AppPreference(
    userId: userId ?? this.userId,
    key: key ?? this.key,
    valueJson: valueJson ?? this.valueJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppPreference copyWithCompanion(AppPreferencesCompanion data) {
    return AppPreference(
      userId: data.userId.present ? data.userId.value : this.userId,
      key: data.key.present ? data.key.value : this.key,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppPreference(')
          ..write('userId: $userId, ')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, key, valueJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppPreference &&
          other.userId == this.userId &&
          other.key == this.key &&
          other.valueJson == this.valueJson &&
          other.updatedAt == this.updatedAt);
}

class AppPreferencesCompanion extends UpdateCompanion<AppPreference> {
  final Value<String> userId;
  final Value<String> key;
  final Value<String> valueJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppPreferencesCompanion({
    this.userId = const Value.absent(),
    this.key = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppPreferencesCompanion.insert({
    required String userId,
    required String key,
    required String valueJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       key = Value(key),
       valueJson = Value(valueJson),
       updatedAt = Value(updatedAt);
  static Insertable<AppPreference> custom({
    Expression<String>? userId,
    Expression<String>? key,
    Expression<String>? valueJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (key != null) 'key': key,
      if (valueJson != null) 'value_json': valueJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppPreferencesCompanion copyWith({
    Value<String>? userId,
    Value<String>? key,
    Value<String>? valueJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppPreferencesCompanion(
      userId: userId ?? this.userId,
      key: key ?? this.key,
      valueJson: valueJson ?? this.valueJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppPreferencesCompanion(')
          ..write('userId: $userId, ')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalProfilesTable localProfiles = $LocalProfilesTable(this);
  late final $LocalMealsTable localMeals = $LocalMealsTable(this);
  late final $LocalMealItemsTable localMealItems = $LocalMealItemsTable(this);
  late final $SyncOperationsTable syncOperations = $SyncOperationsTable(this);
  late final $SyncCheckpointsTable syncCheckpoints = $SyncCheckpointsTable(
    this,
  );
  late final $AppPreferencesTable appPreferences = $AppPreferencesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localProfiles,
    localMeals,
    localMealItems,
    syncOperations,
    syncCheckpoints,
    appPreferences,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'local_meals',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('local_meal_items', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$LocalProfilesTableCreateCompanionBuilder =
    LocalProfilesCompanion Function({
      required String userId,
      Value<String?> displayName,
      Value<String> locale,
      Value<String> timezone,
      Value<int?> dailyCalorieTarget,
      Value<String?> primaryIntention,
      Value<int> onboardingVersion,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalProfilesTableUpdateCompanionBuilder =
    LocalProfilesCompanion Function({
      Value<String> userId,
      Value<String?> displayName,
      Value<String> locale,
      Value<String> timezone,
      Value<int?> dailyCalorieTarget,
      Value<String?> primaryIntention,
      Value<int> onboardingVersion,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyCalorieTarget => $composableBuilder(
    column: $table.dailyCalorieTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryIntention => $composableBuilder(
    column: $table.primaryIntention,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get onboardingVersion => $composableBuilder(
    column: $table.onboardingVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyCalorieTarget => $composableBuilder(
    column: $table.dailyCalorieTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryIntention => $composableBuilder(
    column: $table.primaryIntention,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get onboardingVersion => $composableBuilder(
    column: $table.onboardingVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locale =>
      $composableBuilder(column: $table.locale, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<int> get dailyCalorieTarget => $composableBuilder(
    column: $table.dailyCalorieTarget,
    builder: (column) => column,
  );

  GeneratedColumn<String> get primaryIntention => $composableBuilder(
    column: $table.primaryIntention,
    builder: (column) => column,
  );

  GeneratedColumn<int> get onboardingVersion => $composableBuilder(
    column: $table.onboardingVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalProfilesTable,
          LocalProfile,
          $$LocalProfilesTableFilterComposer,
          $$LocalProfilesTableOrderingComposer,
          $$LocalProfilesTableAnnotationComposer,
          $$LocalProfilesTableCreateCompanionBuilder,
          $$LocalProfilesTableUpdateCompanionBuilder,
          (
            LocalProfile,
            BaseReferences<_$AppDatabase, $LocalProfilesTable, LocalProfile>,
          ),
          LocalProfile,
          PrefetchHooks Function()
        > {
  $$LocalProfilesTableTableManager(_$AppDatabase db, $LocalProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String> locale = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<int?> dailyCalorieTarget = const Value.absent(),
                Value<String?> primaryIntention = const Value.absent(),
                Value<int> onboardingVersion = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProfilesCompanion(
                userId: userId,
                displayName: displayName,
                locale: locale,
                timezone: timezone,
                dailyCalorieTarget: dailyCalorieTarget,
                primaryIntention: primaryIntention,
                onboardingVersion: onboardingVersion,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<String?> displayName = const Value.absent(),
                Value<String> locale = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<int?> dailyCalorieTarget = const Value.absent(),
                Value<String?> primaryIntention = const Value.absent(),
                Value<int> onboardingVersion = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalProfilesCompanion.insert(
                userId: userId,
                displayName: displayName,
                locale: locale,
                timezone: timezone,
                dailyCalorieTarget: dailyCalorieTarget,
                primaryIntention: primaryIntention,
                onboardingVersion: onboardingVersion,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalProfilesTable,
      LocalProfile,
      $$LocalProfilesTableFilterComposer,
      $$LocalProfilesTableOrderingComposer,
      $$LocalProfilesTableAnnotationComposer,
      $$LocalProfilesTableCreateCompanionBuilder,
      $$LocalProfilesTableUpdateCompanionBuilder,
      (
        LocalProfile,
        BaseReferences<_$AppDatabase, $LocalProfilesTable, LocalProfile>,
      ),
      LocalProfile,
      PrefetchHooks Function()
    >;
typedef $$LocalMealsTableCreateCompanionBuilder =
    LocalMealsCompanion Function({
      required String id,
      required String userId,
      required String name,
      Value<String?> rawInput,
      required DateTime eatenAt,
      Value<String?> imageAsset,
      Value<String> syncStatus,
      Value<int> rowVersion,
      required DateTime localUpdatedAt,
      Value<DateTime?> remoteUpdatedAt,
      Value<int> rowid,
    });
typedef $$LocalMealsTableUpdateCompanionBuilder =
    LocalMealsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> name,
      Value<String?> rawInput,
      Value<DateTime> eatenAt,
      Value<String?> imageAsset,
      Value<String> syncStatus,
      Value<int> rowVersion,
      Value<DateTime> localUpdatedAt,
      Value<DateTime?> remoteUpdatedAt,
      Value<int> rowid,
    });

final class $$LocalMealsTableReferences
    extends BaseReferences<_$AppDatabase, $LocalMealsTable, LocalMeal> {
  $$LocalMealsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LocalMealItemsTable, List<LocalMealItem>>
  _localMealItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.localMealItems,
    aliasName: 'local_meals__id__local_meal_items__meal_id',
  );

  $$LocalMealItemsTableProcessedTableManager get localMealItemsRefs {
    final manager = $$LocalMealItemsTableTableManager(
      $_db,
      $_db.localMealItems,
    ).filter((f) => f.mealId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_localMealItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalMealsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMealsTable> {
  $$LocalMealsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawInput => $composableBuilder(
    column: $table.rawInput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get eatenAt => $composableBuilder(
    column: $table.eatenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageAsset => $composableBuilder(
    column: $table.imageAsset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> localMealItemsRefs(
    Expression<bool> Function($$LocalMealItemsTableFilterComposer f) f,
  ) {
    final $$LocalMealItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localMealItems,
      getReferencedColumn: (t) => t.mealId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalMealItemsTableFilterComposer(
            $db: $db,
            $table: $db.localMealItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalMealsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMealsTable> {
  $$LocalMealsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawInput => $composableBuilder(
    column: $table.rawInput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get eatenAt => $composableBuilder(
    column: $table.eatenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageAsset => $composableBuilder(
    column: $table.imageAsset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMealsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMealsTable> {
  $$LocalMealsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get rawInput =>
      $composableBuilder(column: $table.rawInput, builder: (column) => column);

  GeneratedColumn<DateTime> get eatenAt =>
      $composableBuilder(column: $table.eatenAt, builder: (column) => column);

  GeneratedColumn<String> get imageAsset => $composableBuilder(
    column: $table.imageAsset,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rowVersion => $composableBuilder(
    column: $table.rowVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => column,
  );

  Expression<T> localMealItemsRefs<T extends Object>(
    Expression<T> Function($$LocalMealItemsTableAnnotationComposer a) f,
  ) {
    final $$LocalMealItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localMealItems,
      getReferencedColumn: (t) => t.mealId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalMealItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.localMealItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalMealsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMealsTable,
          LocalMeal,
          $$LocalMealsTableFilterComposer,
          $$LocalMealsTableOrderingComposer,
          $$LocalMealsTableAnnotationComposer,
          $$LocalMealsTableCreateCompanionBuilder,
          $$LocalMealsTableUpdateCompanionBuilder,
          (LocalMeal, $$LocalMealsTableReferences),
          LocalMeal,
          PrefetchHooks Function({bool localMealItemsRefs})
        > {
  $$LocalMealsTableTableManager(_$AppDatabase db, $LocalMealsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMealsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMealsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMealsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> rawInput = const Value.absent(),
                Value<DateTime> eatenAt = const Value.absent(),
                Value<String?> imageAsset = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowVersion = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<DateTime?> remoteUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMealsCompanion(
                id: id,
                userId: userId,
                name: name,
                rawInput: rawInput,
                eatenAt: eatenAt,
                imageAsset: imageAsset,
                syncStatus: syncStatus,
                rowVersion: rowVersion,
                localUpdatedAt: localUpdatedAt,
                remoteUpdatedAt: remoteUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String name,
                Value<String?> rawInput = const Value.absent(),
                required DateTime eatenAt,
                Value<String?> imageAsset = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowVersion = const Value.absent(),
                required DateTime localUpdatedAt,
                Value<DateTime?> remoteUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMealsCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                rawInput: rawInput,
                eatenAt: eatenAt,
                imageAsset: imageAsset,
                syncStatus: syncStatus,
                rowVersion: rowVersion,
                localUpdatedAt: localUpdatedAt,
                remoteUpdatedAt: remoteUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalMealsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localMealItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (localMealItemsRefs) db.localMealItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (localMealItemsRefs)
                    await $_getPrefetchedData<
                      LocalMeal,
                      $LocalMealsTable,
                      LocalMealItem
                    >(
                      currentTable: table,
                      referencedTable: $$LocalMealsTableReferences
                          ._localMealItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LocalMealsTableReferences(
                            db,
                            table,
                            p0,
                          ).localMealItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.mealId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LocalMealsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMealsTable,
      LocalMeal,
      $$LocalMealsTableFilterComposer,
      $$LocalMealsTableOrderingComposer,
      $$LocalMealsTableAnnotationComposer,
      $$LocalMealsTableCreateCompanionBuilder,
      $$LocalMealsTableUpdateCompanionBuilder,
      (LocalMeal, $$LocalMealsTableReferences),
      LocalMeal,
      PrefetchHooks Function({bool localMealItemsRefs})
    >;
typedef $$LocalMealItemsTableCreateCompanionBuilder =
    LocalMealItemsCompanion Function({
      required String id,
      required String mealId,
      required String userId,
      Value<String?> foodId,
      required String name,
      required String sourceText,
      required String portionLabel,
      required double grams,
      required double caloriesPer100g,
      required double proteinPer100g,
      required double carbsPer100g,
      required double fatPer100g,
      required String matchState,
      required String sourceName,
      required int position,
      Value<int> rowid,
    });
typedef $$LocalMealItemsTableUpdateCompanionBuilder =
    LocalMealItemsCompanion Function({
      Value<String> id,
      Value<String> mealId,
      Value<String> userId,
      Value<String?> foodId,
      Value<String> name,
      Value<String> sourceText,
      Value<String> portionLabel,
      Value<double> grams,
      Value<double> caloriesPer100g,
      Value<double> proteinPer100g,
      Value<double> carbsPer100g,
      Value<double> fatPer100g,
      Value<String> matchState,
      Value<String> sourceName,
      Value<int> position,
      Value<int> rowid,
    });

final class $$LocalMealItemsTableReferences
    extends BaseReferences<_$AppDatabase, $LocalMealItemsTable, LocalMealItem> {
  $$LocalMealItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalMealsTable _mealIdTable(_$AppDatabase db) =>
      db.localMeals.createAlias('local_meal_items__meal_id__local_meals__id');

  $$LocalMealsTableProcessedTableManager get mealId {
    final $_column = $_itemColumn<String>('meal_id')!;

    final manager = $$LocalMealsTableTableManager(
      $_db,
      $_db.localMeals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mealIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalMealItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMealItemsTable> {
  $$LocalMealItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get portionLabel => $composableBuilder(
    column: $table.portionLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get caloriesPer100g => $composableBuilder(
    column: $table.caloriesPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchState => $composableBuilder(
    column: $table.matchState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalMealsTableFilterComposer get mealId {
    final $$LocalMealsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealId,
      referencedTable: $db.localMeals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalMealsTableFilterComposer(
            $db: $db,
            $table: $db.localMeals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalMealItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMealItemsTable> {
  $$LocalMealItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get portionLabel => $composableBuilder(
    column: $table.portionLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get caloriesPer100g => $composableBuilder(
    column: $table.caloriesPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchState => $composableBuilder(
    column: $table.matchState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalMealsTableOrderingComposer get mealId {
    final $$LocalMealsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealId,
      referencedTable: $db.localMeals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalMealsTableOrderingComposer(
            $db: $db,
            $table: $db.localMeals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalMealItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMealItemsTable> {
  $$LocalMealItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get portionLabel => $composableBuilder(
    column: $table.portionLabel,
    builder: (column) => column,
  );

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<double> get caloriesPer100g => $composableBuilder(
    column: $table.caloriesPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matchState => $composableBuilder(
    column: $table.matchState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$LocalMealsTableAnnotationComposer get mealId {
    final $$LocalMealsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealId,
      referencedTable: $db.localMeals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalMealsTableAnnotationComposer(
            $db: $db,
            $table: $db.localMeals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalMealItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMealItemsTable,
          LocalMealItem,
          $$LocalMealItemsTableFilterComposer,
          $$LocalMealItemsTableOrderingComposer,
          $$LocalMealItemsTableAnnotationComposer,
          $$LocalMealItemsTableCreateCompanionBuilder,
          $$LocalMealItemsTableUpdateCompanionBuilder,
          (LocalMealItem, $$LocalMealItemsTableReferences),
          LocalMealItem,
          PrefetchHooks Function({bool mealId})
        > {
  $$LocalMealItemsTableTableManager(
    _$AppDatabase db,
    $LocalMealItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMealItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMealItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMealItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> mealId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> foodId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> sourceText = const Value.absent(),
                Value<String> portionLabel = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<double> caloriesPer100g = const Value.absent(),
                Value<double> proteinPer100g = const Value.absent(),
                Value<double> carbsPer100g = const Value.absent(),
                Value<double> fatPer100g = const Value.absent(),
                Value<String> matchState = const Value.absent(),
                Value<String> sourceName = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMealItemsCompanion(
                id: id,
                mealId: mealId,
                userId: userId,
                foodId: foodId,
                name: name,
                sourceText: sourceText,
                portionLabel: portionLabel,
                grams: grams,
                caloriesPer100g: caloriesPer100g,
                proteinPer100g: proteinPer100g,
                carbsPer100g: carbsPer100g,
                fatPer100g: fatPer100g,
                matchState: matchState,
                sourceName: sourceName,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String mealId,
                required String userId,
                Value<String?> foodId = const Value.absent(),
                required String name,
                required String sourceText,
                required String portionLabel,
                required double grams,
                required double caloriesPer100g,
                required double proteinPer100g,
                required double carbsPer100g,
                required double fatPer100g,
                required String matchState,
                required String sourceName,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => LocalMealItemsCompanion.insert(
                id: id,
                mealId: mealId,
                userId: userId,
                foodId: foodId,
                name: name,
                sourceText: sourceText,
                portionLabel: portionLabel,
                grams: grams,
                caloriesPer100g: caloriesPer100g,
                proteinPer100g: proteinPer100g,
                carbsPer100g: carbsPer100g,
                fatPer100g: fatPer100g,
                matchState: matchState,
                sourceName: sourceName,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalMealItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mealId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (mealId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.mealId,
                                referencedTable: $$LocalMealItemsTableReferences
                                    ._mealIdTable(db),
                                referencedColumn:
                                    $$LocalMealItemsTableReferences
                                        ._mealIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalMealItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMealItemsTable,
      LocalMealItem,
      $$LocalMealItemsTableFilterComposer,
      $$LocalMealItemsTableOrderingComposer,
      $$LocalMealItemsTableAnnotationComposer,
      $$LocalMealItemsTableCreateCompanionBuilder,
      $$LocalMealItemsTableUpdateCompanionBuilder,
      (LocalMealItem, $$LocalMealItemsTableReferences),
      LocalMealItem,
      PrefetchHooks Function({bool mealId})
    >;
typedef $$SyncOperationsTableCreateCompanionBuilder =
    SyncOperationsCompanion Function({
      required String id,
      required String userId,
      required String entityType,
      required String entityId,
      required String operationType,
      required String payloadJson,
      Value<String> status,
      Value<int> attemptCount,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastErrorCode,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SyncOperationsTableUpdateCompanionBuilder =
    SyncOperationsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> operationType,
      Value<String> payloadJson,
      Value<String> status,
      Value<int> attemptCount,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastErrorCode,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SyncOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOperationsTable> {
  $$SyncOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOperationsTable> {
  $$SyncOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOperationsTable> {
  $$SyncOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncOperationsTable,
          SyncOperation,
          $$SyncOperationsTableFilterComposer,
          $$SyncOperationsTableOrderingComposer,
          $$SyncOperationsTableAnnotationComposer,
          $$SyncOperationsTableCreateCompanionBuilder,
          $$SyncOperationsTableUpdateCompanionBuilder,
          (
            SyncOperation,
            BaseReferences<_$AppDatabase, $SyncOperationsTable, SyncOperation>,
          ),
          SyncOperation,
          PrefetchHooks Function()
        > {
  $$SyncOperationsTableTableManager(
    _$AppDatabase db,
    $SyncOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOperationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOperationsCompanion(
                id: id,
                userId: userId,
                entityType: entityType,
                entityId: entityId,
                operationType: operationType,
                payloadJson: payloadJson,
                status: status,
                attemptCount: attemptCount,
                nextAttemptAt: nextAttemptAt,
                lastErrorCode: lastErrorCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String entityType,
                required String entityId,
                required String operationType,
                required String payloadJson,
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncOperationsCompanion.insert(
                id: id,
                userId: userId,
                entityType: entityType,
                entityId: entityId,
                operationType: operationType,
                payloadJson: payloadJson,
                status: status,
                attemptCount: attemptCount,
                nextAttemptAt: nextAttemptAt,
                lastErrorCode: lastErrorCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncOperationsTable,
      SyncOperation,
      $$SyncOperationsTableFilterComposer,
      $$SyncOperationsTableOrderingComposer,
      $$SyncOperationsTableAnnotationComposer,
      $$SyncOperationsTableCreateCompanionBuilder,
      $$SyncOperationsTableUpdateCompanionBuilder,
      (
        SyncOperation,
        BaseReferences<_$AppDatabase, $SyncOperationsTable, SyncOperation>,
      ),
      SyncOperation,
      PrefetchHooks Function()
    >;
typedef $$SyncCheckpointsTableCreateCompanionBuilder =
    SyncCheckpointsCompanion Function({
      required String userId,
      required String scope,
      Value<String?> cursor,
      required DateTime pulledAt,
      Value<int> rowid,
    });
typedef $$SyncCheckpointsTableUpdateCompanionBuilder =
    SyncCheckpointsCompanion Function({
      Value<String> userId,
      Value<String> scope,
      Value<String?> cursor,
      Value<DateTime> pulledAt,
      Value<int> rowid,
    });

class $$SyncCheckpointsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCheckpointsTable> {
  $$SyncCheckpointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pulledAt => $composableBuilder(
    column: $table.pulledAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCheckpointsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCheckpointsTable> {
  $$SyncCheckpointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pulledAt => $composableBuilder(
    column: $table.pulledAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCheckpointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCheckpointsTable> {
  $$SyncCheckpointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<DateTime> get pulledAt =>
      $composableBuilder(column: $table.pulledAt, builder: (column) => column);
}

class $$SyncCheckpointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCheckpointsTable,
          SyncCheckpoint,
          $$SyncCheckpointsTableFilterComposer,
          $$SyncCheckpointsTableOrderingComposer,
          $$SyncCheckpointsTableAnnotationComposer,
          $$SyncCheckpointsTableCreateCompanionBuilder,
          $$SyncCheckpointsTableUpdateCompanionBuilder,
          (
            SyncCheckpoint,
            BaseReferences<
              _$AppDatabase,
              $SyncCheckpointsTable,
              SyncCheckpoint
            >,
          ),
          SyncCheckpoint,
          PrefetchHooks Function()
        > {
  $$SyncCheckpointsTableTableManager(
    _$AppDatabase db,
    $SyncCheckpointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCheckpointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCheckpointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCheckpointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String?> cursor = const Value.absent(),
                Value<DateTime> pulledAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCheckpointsCompanion(
                userId: userId,
                scope: scope,
                cursor: cursor,
                pulledAt: pulledAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String scope,
                Value<String?> cursor = const Value.absent(),
                required DateTime pulledAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncCheckpointsCompanion.insert(
                userId: userId,
                scope: scope,
                cursor: cursor,
                pulledAt: pulledAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCheckpointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCheckpointsTable,
      SyncCheckpoint,
      $$SyncCheckpointsTableFilterComposer,
      $$SyncCheckpointsTableOrderingComposer,
      $$SyncCheckpointsTableAnnotationComposer,
      $$SyncCheckpointsTableCreateCompanionBuilder,
      $$SyncCheckpointsTableUpdateCompanionBuilder,
      (
        SyncCheckpoint,
        BaseReferences<_$AppDatabase, $SyncCheckpointsTable, SyncCheckpoint>,
      ),
      SyncCheckpoint,
      PrefetchHooks Function()
    >;
typedef $$AppPreferencesTableCreateCompanionBuilder =
    AppPreferencesCompanion Function({
      required String userId,
      required String key,
      required String valueJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AppPreferencesTableUpdateCompanionBuilder =
    AppPreferencesCompanion Function({
      Value<String> userId,
      Value<String> key,
      Value<String> valueJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppPreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppPreferencesTable,
          AppPreference,
          $$AppPreferencesTableFilterComposer,
          $$AppPreferencesTableOrderingComposer,
          $$AppPreferencesTableAnnotationComposer,
          $$AppPreferencesTableCreateCompanionBuilder,
          $$AppPreferencesTableUpdateCompanionBuilder,
          (
            AppPreference,
            BaseReferences<_$AppDatabase, $AppPreferencesTable, AppPreference>,
          ),
          AppPreference,
          PrefetchHooks Function()
        > {
  $$AppPreferencesTableTableManager(
    _$AppDatabase db,
    $AppPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppPreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppPreferencesCompanion(
                userId: userId,
                key: key,
                valueJson: valueJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String key,
                required String valueJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppPreferencesCompanion.insert(
                userId: userId,
                key: key,
                valueJson: valueJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppPreferencesTable,
      AppPreference,
      $$AppPreferencesTableFilterComposer,
      $$AppPreferencesTableOrderingComposer,
      $$AppPreferencesTableAnnotationComposer,
      $$AppPreferencesTableCreateCompanionBuilder,
      $$AppPreferencesTableUpdateCompanionBuilder,
      (
        AppPreference,
        BaseReferences<_$AppDatabase, $AppPreferencesTable, AppPreference>,
      ),
      AppPreference,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalProfilesTableTableManager get localProfiles =>
      $$LocalProfilesTableTableManager(_db, _db.localProfiles);
  $$LocalMealsTableTableManager get localMeals =>
      $$LocalMealsTableTableManager(_db, _db.localMeals);
  $$LocalMealItemsTableTableManager get localMealItems =>
      $$LocalMealItemsTableTableManager(_db, _db.localMealItems);
  $$SyncOperationsTableTableManager get syncOperations =>
      $$SyncOperationsTableTableManager(_db, _db.syncOperations);
  $$SyncCheckpointsTableTableManager get syncCheckpoints =>
      $$SyncCheckpointsTableTableManager(_db, _db.syncCheckpoints);
  $$AppPreferencesTableTableManager get appPreferences =>
      $$AppPreferencesTableTableManager(_db, _db.appPreferences);
}
