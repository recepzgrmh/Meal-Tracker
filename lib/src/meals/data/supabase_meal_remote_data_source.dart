import 'package:supabase_flutter/supabase_flutter.dart';

import 'meal_remote_data_source.dart';
import 'meal_remote_dto.dart';

class SupabaseMealRemoteDataSource implements MealRemoteDataSource {
  const SupabaseMealRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<MealRemoteDto>> fetchWindow({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _client
        .from('meals')
        .select('''
          id,user_id,client_request_id,name,raw_input,occurred_at,image_path,updated_at,
          meal_items(
            id,food_id,position,source_text,canonical_name,portion_label,grams,
            calories_per_100g,protein_per_100g,carbs_per_100g,fat_per_100g,
            review_status,nutrition_source
          )
        ''')
        .eq('user_id', userId)
        .gte('occurred_at', from.toUtc().toIso8601String())
        .lt('occurred_at', to.toUtc().toIso8601String())
        .order('occurred_at');

    return rows.map(MealRemoteDto.fromJson).toList(growable: false);
  }
}
