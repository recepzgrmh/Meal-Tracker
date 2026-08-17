import 'meal_remote_dto.dart';

abstract interface class MealRemoteDataSource {
  Future<List<MealRemoteDto>> fetchWindow({
    required String userId,
    required DateTime from,
    required DateTime to,
  });
}
