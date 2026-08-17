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
    final values = <String, Object?>{
      'primary_intention':
          (draft.intention ?? TrackingIntention.understand).name,
      'onboarding_version': version,
      'onboarding_completed_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (draft.dailyCalorieTarget case final target?) {
      values['daily_calorie_target'] = target;
    }

    await _client.from('profiles').update(values).eq('id', userId);
  }
}
