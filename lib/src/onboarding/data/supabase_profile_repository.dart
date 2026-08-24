import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/onboarding_draft.dart';
import 'profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  const SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> completeOnboarding({
    required String userId,
    required OnboardingDraft draft,
    required int version,
  }) async {
    final body = draft.body;
    final plan = draft.plan;

    final values = <String, Object?>{
      'primary_intention':
          (draft.intention ?? TrackingIntention.understand).name,
      'onboarding_version': version,
      'onboarding_completed_at': DateTime.now().toUtc().toIso8601String(),
      'biological_sex': body.sex?.wire,
      'birth_year': body.birthYear,
      'height_cm': body.heightCm,
      'weight_kg': body.weightKg,
      'target_weight_kg': body.targetWeightKg,
      'activity_level': body.activityLevel?.wire,
      'weight_goal': body.goal?.wire,
      'goal_pace': body.pace.wire,
      'diet_pattern': body.dietPattern?.wire,
      'measurement_system': body.measurementSystem.wire,
    };

    // The column is `not null` with a 2100 default, so it is only written when
    // there is a real target to write; a skipped setup keeps the default.
    if (plan != null) {
      values['daily_calorie_target'] = plan.calories.round();
      values['daily_protein_target_g'] = plan.proteinG.round();
      values['daily_carb_target_g'] = plan.carbsG.round();
      values['daily_fat_target_g'] = plan.fatG.round();
      values['calorie_target_source'] = plan.source.wire;
    }

    await _client.from('profiles').update(values).eq('id', userId);
  }
}
