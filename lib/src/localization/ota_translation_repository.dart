import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtaTranslationBundle {
  const OtaTranslationBundle({required this.version, required this.values});

  final int version;
  final Map<String, String> values;
}

abstract interface class OtaTranslationRepository {
  Future<OtaTranslationBundle> load(String locale);
}

class SupabaseOtaTranslationRepository implements OtaTranslationRepository {
  const SupabaseOtaTranslationRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<OtaTranslationBundle> load(String locale) async {
    final preferences = await SharedPreferences.getInstance();
    final cacheKey = 'ota_translations_$locale';
    final cached = _decode(preferences.getString(cacheKey));
    try {
      final row = await _client
          .from('translation_bundles')
          .select('version,values')
          .eq('locale', locale)
          .single()
          .timeout(const Duration(milliseconds: 1500));
      final remote = _fromRow(row);
      if (remote.version >= cached.version) {
        await preferences.setString(
          cacheKey,
          jsonEncode({'version': remote.version, 'values': remote.values}),
        );
        return remote;
      }
    } catch (_) {
      // Bundled ARB strings and the last valid cache keep startup offline-safe.
    }
    return cached;
  }

  OtaTranslationBundle _fromRow(Map<String, dynamic> row) {
    final version = row['version'];
    final values = row['values'];
    if (version is! int || version < 1 || values is! Map) return _empty;
    final strings = <String, String>{};
    for (final entry in values.entries) {
      if (entry.key is String &&
          entry.value is String &&
          (entry.value as String).length <= 500) {
        strings[entry.key as String] = (entry.value as String).trim();
      }
    }
    return OtaTranslationBundle(version: version, values: strings);
  }

  OtaTranslationBundle _decode(String? raw) {
    if (raw == null || raw.length > 65536) return _empty;
    try {
      final value = jsonDecode(raw);
      return value is Map<String, dynamic> ? _fromRow(value) : _empty;
    } catch (_) {
      return _empty;
    }
  }

  static const _empty = OtaTranslationBundle(version: 0, values: {});
}

class BundledOnlyTranslationRepository implements OtaTranslationRepository {
  const BundledOnlyTranslationRepository();

  @override
  Future<OtaTranslationBundle> load(String locale) async =>
      const OtaTranslationBundle(version: 0, values: {});
}
