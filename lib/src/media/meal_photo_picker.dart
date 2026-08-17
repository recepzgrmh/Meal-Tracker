import 'package:image_picker/image_picker.dart';

import '../domain/meal_analysis_input.dart';

enum MealPhotoSource { camera, gallery }

abstract interface class MealPhotoPicker {
  Future<MealPhotoAttachment?> pick(MealPhotoSource source);

  Future<MealPhotoAttachment?> recoverLost();
}

class ImagePickerMealPhotoPicker implements MealPhotoPicker {
  ImagePickerMealPhotoPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<MealPhotoAttachment?> pick(MealPhotoSource source) async {
    final file = await _picker.pickImage(
      source: source == MealPhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2048,
      requestFullMetadata: false,
    );
    return file == null ? null : _toAttachment(file);
  }

  @override
  Future<MealPhotoAttachment?> recoverLost() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty || response.files == null || response.files!.isEmpty) {
      return null;
    }
    return _toAttachment(response.files!.first);
  }

  Future<MealPhotoAttachment> _toAttachment(XFile file) async {
    final bytes = await file.readAsBytes();
    return MealPhotoAttachment(
      bytes: bytes,
      fileName: file.name,
      mimeType: file.mimeType ?? _mimeTypeFor(file.name),
    );
  }

  String _mimeTypeFor(String name) {
    final normalized = name.toLowerCase();
    if (normalized.endsWith('.png')) return 'image/png';
    if (normalized.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
