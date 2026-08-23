import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/meal_analysis_input.dart';

class StoredMealPhoto {
  const StoredMealPhoto({
    required this.bucket,
    required this.path,
    required this.mimeType,
    this.signedUrl,
  });

  final String bucket;
  final String path;
  final String mimeType;
  final String? signedUrl;

  Map<String, String> toJson() => {
    'bucket': bucket,
    'path': path,
    'mimeType': mimeType,
  };
}

abstract interface class MealPhotoStorage {
  Future<StoredMealPhoto> upload({
    required String requestId,
    required MealPhotoAttachment photo,
  });
}

class MealPhotoStorageException implements Exception {
  const MealPhotoStorageException(this.code);

  final String code;
}

class SupabaseMealPhotoStorage implements MealPhotoStorage {
  const SupabaseMealPhotoStorage(this._client);

  static const bucket = 'meal-photos';
  final SupabaseClient _client;

  @override
  Future<StoredMealPhoto> upload({
    required String requestId,
    required MealPhotoAttachment photo,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const MealPhotoStorageException('UNAUTHENTICATED');
    }
    if (photo.byteLength > 8 * 1024 * 1024) {
      throw const MealPhotoStorageException('PHOTO_TOO_LARGE');
    }

    final path = '$userId/$requestId/source.${_extension(photo.mimeType)}';
    try {
      await _client.storage
          .from(bucket)
          .uploadBinary(
            path,
            photo.bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              contentType: photo.mimeType,
              upsert: false,
            ),
          );
      return StoredMealPhoto(
        bucket: bucket,
        path: path,
        mimeType: photo.mimeType,
        signedUrl: await _client.storage
            .from(bucket)
            .createSignedUrl(path, 3600),
      );
    } on StorageException catch (error) {
      throw MealPhotoStorageException(
        error.statusCode == '409'
            ? 'PHOTO_ALREADY_EXISTS'
            : 'PHOTO_UPLOAD_FAILED',
      );
    }
  }

  String _extension(String mimeType) => switch (mimeType) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    _ => 'jpg',
  };
}
